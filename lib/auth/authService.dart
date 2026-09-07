import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/core/services/local_data_guard.dart';

class AuthService {
  bool get isLoggedIn => AuthToken.I.isValid;
  String? get userId => AuthToken.I.userId;

  Future<void> login(String identity, String password) async {
    final result = await ApiClient.instance.post(
      '/api/auth/login',
      {'identity': identity, 'password': password},
      withAuth: false,
    );
    if (result is ApiError) throw Exception((result as ApiError).message);
    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    final token = data['token'] as String;
    final userId = (data['user'] as Map<String, dynamic>)['id'] as String;
    await AuthToken.I.save(token, userId);
    await LocalDataGuard.onAuthenticated(userId);
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    final result = await ApiClient.instance.post(
      '/api/auth/register',
      {
        'email': email,
        'username': username,
        'password': password,
        'displayName': displayName,
      },
      withAuth: false,
    );
    if (result is ApiError) throw Exception((result as ApiError).message);
    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    final token = data['token'] as String;
    final userId = (data['user'] as Map<String, dynamic>)['id'] as String;
    await AuthToken.I.save(token, userId);
    await LocalDataGuard.onAuthenticated(userId);
  }

  /// Requests a password-reset email. Always resolves without throwing on a
  /// "not found"-shaped failure — the caller shows the same generic message
  /// either way so this can't be used to enumerate registered emails.
  Future<void> requestPasswordReset(String email) async {
    await ApiClient.instance.post(
      '/api/auth/forgot-password',
      {'email': email},
      withAuth: false,
    );
    // Result intentionally ignored (besides logging, done inside guard()) —
    // see the anti-enumeration note above.
  }

  /// Completes a password reset using the token from the emailed link.
  /// Throws on failure — expired/used/invalid tokens are real distinct
  /// outcomes the UI needs to show.
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final result = await ApiClient.instance.post(
      '/api/auth/reset-password',
      {'token': token, 'newPassword': newPassword},
      withAuth: false,
    );
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  Future<void> refreshToken() async {
    final result = await ApiClient.instance.postEmpty('/api/auth/refresh');
    if (result is ApiError) throw Exception((result as ApiError).message);
    final data = (result as ApiSuccess<Map<String, dynamic>>).data;
    final token = data['token'] as String;
    final userId =
        (data['user'] as Map<String, dynamic>)['id'] as String;
    await AuthToken.I.save(token, userId);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ApiClient.instance.post('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  /// Permanently deletes the signed-in account. Requires the current password
  /// for confirmation. The backend returns 400 (not 401) on a wrong password,
  /// so the message surfaces without triggering the client's 401 force-logout.
  /// Throws on any failure; clears the local token only on success.
  Future<void> deleteAccount(String password) async {
    final result = await ApiClient.instance.delete(
      '/api/users/me',
      body: {'password': password},
    );
    if (result is ApiError) throw Exception((result as ApiError).message);
    await AuthToken.I.clear();
  }

  Future<void> logout() => AuthToken.I.clear();
}
