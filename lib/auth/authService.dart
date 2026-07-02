import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';

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

  Future<void> logout() => AuthToken.I.clear();
}
