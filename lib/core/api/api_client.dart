import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/pb.dart';

/// Thin wrapper around PocketBase that:
///   • Catches [ClientException] and maps them to [ApiError]
///   • Catches connectivity errors (SocketException / TimeoutException)
///   • Re-tries auth refresh once on 401 before failing
///
/// Every public method returns [ApiResult<T>] — never throws.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  PocketBase get _pb => PB.I.pb;

  // ── Generic guarded call ─────────────────────────────────────────────────

  /// Wraps any async PocketBase call in error handling.
  Future<ApiResult<T>> guard<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return ApiSuccess(result);
    } on ClientException catch (e) {
      if (e.statusCode == 401) {
        // Attempt a single silent refresh, then retry.
        try {
          await _pb.collection('users').authRefresh();
          final retried = await call();
          return ApiSuccess(retried);
        } catch (_) {
          await PB.I.clearAuthEverywhere();
          return ApiError('Session expired. Please sign in again.', statusCode: 401, cause: e);
        }
      }
      final msg = (e.response['message'] as String?) ??
          (e.response.toString().isNotEmpty
              ? e.response.toString()
              : 'Request failed (${e.statusCode})');
      return ApiError(msg, statusCode: e.statusCode, cause: e);
    } catch (e, st) {
      debugPrint('[ApiClient] unexpected error: $e\n$st');
      final isNetworkError = e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused');
      if (isNetworkError) {
        return ApiError('No connection. Check your internet.', cause: e);
      }
      return ApiError('Unexpected error. Please try again.', cause: e);
    }
  }

  // ── Users ────────────────────────────────────────────────────────────────

  Future<ApiResult<RecordModel>> getUser(String id) =>
      guard(() => _pb.collection('users').getOne(id));

  Future<ApiResult<RecordModel>> updateUser(
    String id,
    Map<String, dynamic> body,
  ) =>
      guard(() => _pb.collection('users').update(id, body: body));

  // ── Generic collection helpers (used by social features) ─────────────────

  Future<ApiResult<List<RecordModel>>> list(
    String collection, {
    int page = 1,
    int perPage = 30,
    String sort = '-created',
    String filter = '',
    String expand = '',
  }) =>
      guard(() async {
        final page0 = await _pb.collection(collection).getList(
          page: page,
          perPage: perPage,
          sort: sort,
          filter: filter,
          expand: expand,
        );
        return page0.items;
      });

  Future<ApiResult<RecordModel>> create(
    String collection,
    Map<String, dynamic> body,
  ) =>
      guard(() => _pb.collection(collection).create(body: body));

  Future<ApiResult<bool>> delete(String collection, String id) =>
      guard(() async {
        await _pb.collection(collection).delete(id);
        return true;
      });
}
