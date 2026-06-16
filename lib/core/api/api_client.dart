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
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Options get _auth => Options(headers: {
    'Authorization': 'Bearer ${AuthToken.I.token}',
  });

  // ── Generic guarded call ─────────────────────────────────────────────────

  Future<ApiResult<T>> guard<T>(Future<T> Function() call) async {
    try {
      return ApiSuccess(await call());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await AuthToken.I.clear();
        return ApiError(
          'Session expired. Please sign in again.',
          statusCode: 401,
          cause: e,
        );
      }
      final msg =
          (e.response?.data as Map?)?['message'] as String? ??
          'Request failed (${e.response?.statusCode ?? 'no response'})';
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
    return (r.data as Map<String, dynamic>);
  });

  Future<ApiResult<Map<String, dynamic>>> patch(
    String path,
    Map<String, dynamic> body,
  ) => guard(() async {
    final r = await _dio.patch(path, data: body, options: _auth);
    return (r.data as Map<String, dynamic>);
  });

  Future<ApiResult<Map<String, dynamic>>> put(
    String path,
    Map<String, dynamic> body,
  ) => guard(() async {
    final r = await _dio.put(path, data: body, options: _auth);
    return (r.data as Map<String, dynamic>);
  });

  Future<ApiResult<dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) => guard(() async {
    final r = await _dio.get(path, queryParameters: params, options: _auth);
    return r.data;
  });

  Future<ApiResult<bool>> delete(String path) => guard(() async {
    await _dio.delete(path, options: _auth);
    return true;
  });
}
