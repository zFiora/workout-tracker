import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/home/friends/friendModel.dart';

class FriendService {
  final _client = ApiClient.instance;

  bool get _authed => AuthToken.I.isValid;

  Future<List<FriendUser>> listFriends() async {
    if (!_authed) return [];
    final result = await _client.get('/api/friends');
    return switch (result) {
      ApiSuccess(:final data) =>
        (data as List).map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList(),
      ApiError() => [],
    };
  }

  Future<List<PendingRequest>> incomingPending() async {
    if (!_authed) return [];
    final result = await _client.get('/api/friends/pending');
    return switch (result) {
      ApiSuccess(:final data) =>
        (data as List).map((e) => PendingRequest.fromJson(e as Map<String, dynamic>)).toList(),
      ApiError() => [],
    };
  }

  Future<List<FriendUser>> searchUsers(String q) async {
    if (!_authed || q.trim().isEmpty) return [];
    final result = await _client.get('/api/friends/search', params: {'q': q.trim()});
    return switch (result) {
      ApiSuccess(:final data) =>
        (data as List).map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList(),
      ApiError() => [],
    };
  }

  Future<String?> sendRequest(String addresseeId) async {
    if (!_authed) return 'Not signed in';
    final result = await _client.post('/api/friends/request', {
      'addresseeId': addresseeId,
    });
    return switch (result) {
      ApiSuccess() => null,
      ApiError(:final message) => message,
    };
  }

  Future<void> accept(String friendshipId) async {
    if (!_authed) return;
    await _client.patch('/api/friends/$friendshipId/respond', {'accept': true});
  }

  Future<void> decline(String friendshipId) async {
    if (!_authed) return;
    await _client.patch('/api/friends/$friendshipId/respond', {'accept': false});
  }

  Future<void> remove(String friendshipId) async {
    if (!_authed) return;
    await _client.delete('/api/friends/$friendshipId');
  }

  /// Public profile lookup. Requires friendship with [userId] (or self).
  Future<FriendUser?> fetchProfile(String userId) async {
    if (!_authed) return null;
    final result = await _client.get('/api/users/$userId');
    return switch (result) {
      ApiSuccess(:final data) => FriendUser.fromJson(data as Map<String, dynamic>),
      ApiError() => null,
    };
  }
}
