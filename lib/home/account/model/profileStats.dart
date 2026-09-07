import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// Aggregate profile statistics computed from the user's real workout
/// history — nothing fabricated. Streak values are server-owned and live on
/// [AccountModel], so they're not recomputed here.
class ProfileStats {
  const ProfileStats({
    required this.workouts,
    required this.totalTime,
    required this.totalVolumeKg,
    required this.exercisesTracked,
  });

  /// Number of completed workouts.
  final int workouts;

  /// Summed duration across all workouts.
  final Duration totalTime;

  /// Total working-set volume (Σ weight × reps over work sets).
  final double totalVolumeKg;

  /// Distinct exercises the user has logged at least once.
  final int exercisesTracked;

  static const empty = ProfileStats(
    workouts: 0,
    totalTime: Duration.zero,
    totalVolumeKg: 0,
    exercisesTracked: 0,
  );

  factory ProfileStats.from(Iterable<WorkoutHistoryEntry> history) {
    var workouts = 0;
    var total = Duration.zero;
    var volume = 0.0;
    final exercises = <int>{};

    for (final entry in history) {
      workouts++;
      total += entry.duration;
      for (final log in entry.logs) {
        exercises.add(log.exerciseId);
        for (final set in log.sets) {
          if (set.type == SetType.work) volume += set.weight * set.reps;
        }
      }
    }

    return ProfileStats(
      workouts: workouts,
      totalTime: total,
      totalVolumeKg: volume,
      exercisesTracked: exercises.length,
    );
  }
}
