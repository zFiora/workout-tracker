import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/account/model/accountModel.dart';

class AccountRepository {
  final _client = ApiClient.instance;

  Future<AccountModel> fetchMe() async {
    final result = await _client.get('/api/users/me');
    return switch (result) {
      ApiSuccess(:final data) =>
        AccountModel.fromJson(data as Map<String, dynamic>),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<AccountModel> updateMe({
    String? displayName,
    String? username,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (username != null) body['username'] = username;

    final result = await _client.patch('/api/users/me', body);
    return switch (result) {
      ApiSuccess(:final data) => AccountModel.fromJson(data),
      ApiError(:final message) => throw Exception(message),
    };
  }
}
