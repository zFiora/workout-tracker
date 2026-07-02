import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/core/api/api_config.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';

/// Thin Dio wrapper that:
///   • Attaches Authorization: Bearer <token> to every protected request
///   • Catches DioException and maps to ApiError
///   • Catches connectivity errors (SocketException / TimeoutException)
///   • Clears the auth token on 401 responses
///
/// Every public method returns [ApiResult<T>] — never throws.
class ApiClient {
  ApiClient._() {
    _dio.interceptors.add(_RefreshInterceptor(_dio));
  }
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Options get _auth => Options(headers: {
    'Authorization': 'Bearer ${AuthToken.I.token}',
  });

  // ── Generic guarded call ─────────────────────────────────────────────────

  // Paths where a 401 means "wrong credentials", not "expired session" —
  // the token itself is still valid, so it must not be cleared.
  static const _credentialCheckPaths = [
    '/api/auth/login',
    '/api/auth/change-password',
  ];

  Future<ApiResult<T>> guard<T>(Future<T> Function() call) async {
    try {
      return ApiSuccess(await call());
    } on DioException catch (e) {
      debugPrint(
        '[ApiClient] DioException on ${e.requestOptions.method} '
        '${e.requestOptions.uri}: type=${e.type} message=${e.message} '
        'status=${e.response?.statusCode} error=${e.error}',
      );
      final normalizedBody = _normalize(e.response?.data);
      final bodyMessage =
          normalizedBody is Map ? normalizedBody['message'] as String? : null;
      final path = e.requestOptions.path;
      final isCredentialCheck =
          _credentialCheckPaths.any((p) => path.contains(p));

      if (e.response?.statusCode == 401) {
        if (isCredentialCheck) {
          return ApiError(
            bodyMessage ?? 'Invalid credentials.',
            statusCode: 401,
            cause: e,
          );
        }
        await AuthToken.I.clear();
        return ApiError(
          bodyMessage ?? 'Session expired. Please sign in again.',
          statusCode: 401,
          cause: e,
        );
      }
      final msg = bodyMessage ??
          'Request failed (${e.response?.statusCode ?? e.type.name})';
      return ApiError(msg, statusCode: e.response?.statusCode, cause: e);
    } catch (e, st) {
      debugPrint('[ApiClient] unexpected error: $e\n$st');
      final s = e.toString();
      if (s.contains('SocketException') ||
          s.contains('Connection refused') ||
          s.contains('TimeoutException')) {
        return ApiError('No connection. Check your internet.', cause: e);
      }
      return ApiError('Unexpected error. Please try again.', cause: e);
    }
  }

  // ── HTTP verbs ───────────────────────────────────────────────────────────

  /// Defends against a backend that double-serializes JSON (e.g. an
  /// endpoint that returns `Results.Ok(JsonSerializer.Serialize(dto))`
  /// instead of `Results.Ok(dto)`). Dio happily decodes the outer JSON,
  /// which turns out to itself be a JSON string — leaving `r.data` as a
  /// String instead of a Map/List. Re-decode once more in that case.
  dynamic _normalize(dynamic raw) {
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) => guard(() async {
    final r = await _dio.post(
      path,
      data: body,
      options: withAuth ? _auth : null,
    );
    return _normalize(r.data) as Map<String, dynamic>;
  });

  Future<ApiResult<Map<String, dynamic>>> patch(
    String path,
    Map<String, dynamic> body,
  ) => guard(() async {
    final r = await _dio.patch(path, data: body, options: _auth);
    return _normalize(r.data) as Map<String, dynamic>;
  });

  Future<ApiResult<Map<String, dynamic>>> put(
    String path,
    Map<String, dynamic> body,
  ) => guard(() async {
    final r = await _dio.put(path, data: body, options: _auth);
    return _normalize(r.data) as Map<String, dynamic>;
  });

  Future<ApiResult<dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) => guard(() async {
    final r = await _dio.get(path, queryParameters: params, options: _auth);
    return _normalize(r.data);
  });

  Future<ApiResult<bool>> delete(String path) => guard(() async {
    await _dio.delete(path, options: _auth);
    return true;
  });

  // Multipart PATCH — for file uploads (avatar)
  Future<ApiResult<Map<String, dynamic>>> patchMultipart(
    String path,
    FormData formData,
  ) => guard(() async {
    final r = await _dio.patch(
      path,
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer ${AuthToken.I.token}'}),
    );
    return _normalize(r.data) as Map<String, dynamic>;
  });

  // POST with no body — for token refresh
  Future<ApiResult<Map<String, dynamic>>> postEmpty(String path) =>
      guard(() async {
        final r = await _dio.post(path, options: _auth);
        return _normalize(r.data) as Map<String, dynamic>;
      });
}

/// On a 401, refreshes the token once and retries the failed request.
/// Refresh attempts are queued so concurrent 401s only trigger one refresh.
class _RefreshInterceptor extends QueuedInterceptor {
  _RefreshInterceptor(this._dio);
  final Dio _dio;
  Future<bool>? _refreshFuture;

  static const _exemptPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/refresh',
    '/api/auth/change-password',
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isExempt = _exemptPaths.any((p) => path.contains(p));
    if (err.response?.statusCode != 401 || isExempt || !AuthToken.I.isValid) {
      return handler.next(err);
    }

    final refreshed = await (_refreshFuture ??= _refresh());
    _refreshFuture = null;
    if (!refreshed) return handler.next(err);

    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer ${AuthToken.I.token}';
      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<bool> _refresh() async {
    try {
      final r = await _dio.post(
        '/api/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer ${AuthToken.I.token}'},
        ),
      );
      final data = r.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userId = (data['user'] as Map<String, dynamic>)['id'] as String;
      await AuthToken.I.save(token, userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
