import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class WorkoutsApiService {
  final _client = ApiClient.instance;

  /// Idempotent on (templateId, startedAt) per-user — safe to call from a
  /// sync queue without local dedup bookkeeping.
  Future<void> pushEntry(WorkoutHistoryEntry entry) async {
    final result = await _client.post('/api/workouts', entry.toJson());
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  /// Pulls every workout for the current user, newest first, across pages.
  Future<List<WorkoutHistoryEntry>> fetchAll() async {
    final all = <WorkoutHistoryEntry>[];
    var page = 1;
    const perPage = 50;

    while (true) {
      final result = await _client.get(
        '/api/workouts',
        params: {'page': page, 'perPage': perPage},
      );
      final data = switch (result) {
        ApiSuccess(:final data) => data as Map<String, dynamic>,
        ApiError(:final message) => throw Exception(message),
      };
      final items = (data['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WorkoutHistoryEntry.fromJson)
          .toList();
      all.addAll(items);

      final totalItems = (data['totalItems'] as num).toInt();
      if (all.length >= totalItems || items.isEmpty) break;
      page++;
    }

    return all;
  }
}
