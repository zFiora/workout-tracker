import 'package:workout_tracker/home/history/utils/historyEnteryStats.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/muscle_summary_service.dart';

/// Headline numbers for the post-workout summary, derived only from the saved
/// [WorkoutHistoryEntry] so the same numbers can be shown from History later.
class WorkoutSummaryStats {
  const WorkoutSummaryStats({
    required this.duration,
    required this.exercisesWithSets,
    required this.workingSets,
    required this.volumeKg,
  });

  factory WorkoutSummaryStats.fromEntry(WorkoutHistoryEntry entry) {
    final exerciseIds = {
      for (final log in entry.logs)
        if (log.sets.isNotEmpty) log.exerciseId,
    };
    return WorkoutSummaryStats(
      duration: entry.duration,
      exercisesWithSets: exerciseIds.length,
      workingSets: entry.logs.fold(0, (n, log) => n + workingSetCount(log)),
      // Same figure History shows for this workout (all logged sets).
      volumeKg: computeHistoryEntryStats(entry).volume,
    );
  }

  final Duration duration;

  /// Distinct exercises with at least one logged set (planned-but-skipped
  /// exercises have an empty log and don't count).
  final int exercisesWithSets;

  /// Work + drop sets; warm-ups excluded.
  final int workingSets;

  /// Canonical kilograms — format with the user's `WeightUnit`.
  final double volumeKg;
}
