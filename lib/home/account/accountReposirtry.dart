import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/account/model/accountModel.dart';

class AccountRepository {
  final _client = ApiClient.instance;

  static const _cacheKey = 'account_cache';

  /// Last profile fetched successfully from the server, so the account
  /// screen has something to show immediately (and while offline) instead
  /// of a blank loading/error state.
  Future<AccountModel?> readCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return AccountModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(AccountModel account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(account.toJson()));
  }

  Future<AccountModel> fetchMe() async {
    final result = await _client.get('/api/users/me');
    return switch (result) {
      ApiSuccess(:final data) => () {
          final account = AccountModel.fromJson(data as Map<String, dynamic>);
          _cache(account);
          return account;
        }(),
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
      ApiSuccess(:final data) => () {
          final account = AccountModel.fromJson(data);
          _cache(account);
          return account;
        }(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<AccountModel> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'avatar.jpg',
      ),
    });
    final result = await _client.patchMultipart(
      '/api/users/me/avatar',
      formData,
    );
    return switch (result) {
      ApiSuccess() => fetchMe(),
      ApiError(:final message) => throw Exception(message),
    };
  }
}
