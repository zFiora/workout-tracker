import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/home/templates/models/workout_template.dart';

class TemplatesApiService {
  final _client = ApiClient.instance;

  /// Upsert by id — POST is the only write verb the backend exposes for
  /// templates (no separate PUT).
  Future<void> pushUpsert(WorkoutTemplateModel template) async {
    final result = await _client.post('/api/templates', {
      ...template.toJson(),
      'isPublic': false,
    });
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  /// Returns only the current user's own templates (the endpoint also
  /// returns other users' public templates, which we don't want mixed into
  /// the local "My Templates" box).
  Future<List<WorkoutTemplateModel>> fetchMine() async {
    final result = await _client.get('/api/templates');
    final myId = AuthToken.I.userId;
    return switch (result) {
      ApiSuccess(:final data) => (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((j) => j['userId'] == myId)
          .map(WorkoutTemplateModel.fromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  /// Ids of the caller's own templates that were soft-deleted within the last
  /// [sinceDays]. Lets a reconcile tell a server-side delete apart from a
  /// template created locally while offline (which must be pushed, not dropped).
  Future<Set<String>> fetchDeletedIds({int sinceDays = 30}) async {
    final result = await _client.get('/api/templates', params: {
      'includeDeleted': true,
      'sinceDays': sinceDays,
    });
    return switch (result) {
      ApiSuccess(:final data) => (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((j) => j['deletedAt'] != null)
          .map((j) => j['id'] as String)
          .toSet(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<List<WorkoutTemplateModel>> fetchFriendTemplates(String userId) async {
    final result = await _client.get('/api/templates/friend/$userId');
    return switch (result) {
      ApiSuccess(:final data) => (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WorkoutTemplateModel.fromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<void> deleteRemote(String id) async {
    final result = await _client.delete('/api/templates/$id');
    if (result is ApiError) throw Exception((result as ApiError).message);
  }
}
