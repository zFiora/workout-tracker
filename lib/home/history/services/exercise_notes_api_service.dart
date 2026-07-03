import 'package:workout_tracker/core/api/api_client.dart';
import 'package:workout_tracker/core/api/api_result.dart';
import 'package:workout_tracker/home/history/models/exNote.dart';

/// Backend CRUD for per-exercise notes. Notes are scoped to the caller.
class ExerciseNotesApiService {
  final _client = ApiClient.instance;

  /// Newest-first, for one exercise.
  Future<List<ExerciseNote>> fetch(int exerciseId) async {
    final result = await _client.get('/api/exercises/$exerciseId/notes');
    return switch (result) {
      ApiSuccess(:final data) => (data as List)
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .toList(),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<ExerciseNote> create(int exerciseId, String text) async {
    final result = await _client.post(
      '/api/exercises/$exerciseId/notes',
      {'text': text},
    );
    return switch (result) {
      ApiSuccess(:final data) => _fromJson(data),
      ApiError(:final message) => throw Exception(message),
    };
  }

  Future<void> delete(String id) async {
    final result = await _client.delete('/api/exercise-notes/$id');
    if (result is ApiError) throw Exception((result as ApiError).message);
  }

  ExerciseNote _fromJson(Map<String, dynamic> j) => ExerciseNote(
        exerciseId: (j['exerciseId'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        text: j['text'] as String? ?? '',
      );
}
