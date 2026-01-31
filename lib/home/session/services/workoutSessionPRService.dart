import 'package:workout_tracker/home/session/models/PRHit.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class WorkoutSessionPrService {
  String prKey(int exerciseId, DateTime ts) =>
      '$exerciseId:${ts.millisecondsSinceEpoch}';

  double bestWeightAllTime({
    required int exerciseId,
    required List<WorkoutHistoryEntry> history,
  }) {
    double best = 0;
    for (final entry in history) {
      for (final log in entry.logs) {
        if (log.exerciseId != exerciseId) continue;
        for (final s in log.sets) {
          if (s.weight > best) best = s.weight;
        }
      }
    }
    return best;
  }

  PrHit? bestWeightHitIfAny({
    required int exerciseId,
    required DateTime performedAt,
    required double weight,
    required int reps,
    required List<WorkoutHistoryEntry> history,
  }) {
    final prevBest = bestWeightAllTime(
      exerciseId: exerciseId,
      history: history,
    );
    if (weight <= prevBest) return null;

    return PrHit(
      exerciseId: exerciseId,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      kind: 'bestWeight',
    );
  }
}
