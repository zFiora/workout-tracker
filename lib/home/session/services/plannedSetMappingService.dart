import 'package:workout_tracker/home/session/models/sessionModels.dart';

class PlannedSetMappingService {
  /// Rebuild keys after removing a planned row so the mapping stays aligned.
  void rebuildMappingKeysForExercise({
    required int exerciseId,
    required ExerciseLog log,
    required Map<String, DateTime> plannedToPerformedTs,
  }) {
    final entries = <MapEntry<String, DateTime>>[];
    plannedToPerformedTs.forEach((key, ts) {
      if (key.startsWith('$exerciseId:')) {
        entries.add(MapEntry(key, ts));
      }
    });

    plannedToPerformedTs.removeWhere(
      (key, _) => key.startsWith('$exerciseId:'),
    );

    for (int i = 0; i < log.plannedSets.length; i++) {
      final p = log.plannedSets[i];
      if (!p.done) continue;

      DateTime? reused;
      for (final e in List<MapEntry<String, DateTime>>.from(entries)) {
        final ts = e.value;
        if (log.sets.any((s) => s.timestamp == ts)) {
          reused = ts;
          entries.remove(e);
          break;
        }
      }

      if (reused != null) {
        plannedToPerformedTs['$exerciseId:$i'] = reused;
      }
    }
  }
}
