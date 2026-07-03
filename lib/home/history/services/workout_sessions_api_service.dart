import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Talks to the consolidated `/api/workout-sessions` backend.
///
/// Sessions are identified by a client-generated UUID and upserted, so pushing
/// the same session twice never duplicates it.
class WorkoutSessionsApiService {
  final _client = ApiClient.instance;

  /// Batch idempotent upsert. Returns the ids the server confirmed as saved
  /// (already-present ids are included; malformed ones are omitted, signalling
  /// the client to retry them).
  Future<Set<String>> pushSessions(List<WorkoutHistoryEntry> sessions) async {
    if (sessions.isEmpty) return <String>{};
    final result = await _client.post('/api/workout-sessions/sync', {
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
    return switch (result) {
      ApiSuccess(:final data) =>
        ((data['savedIds'] as List?) ?? const []).cast<String>().toSet(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  /// The caller's sessions whose endedAt falls within the last [sinceDays].
  Future<List<WorkoutHistoryEntry>> fetchRecent({int sinceDays = 7}) async {
    final result = await _client.get(
      '/api/workout-sessions',
      params: {'sinceDays': sinceDays},
    );
    return switch (result) {
      ApiSuccess(:final data) => (data as List)
          .cast<Map<String, dynamic>>()
          .map(WorkoutHistoryEntry.fromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }
}
