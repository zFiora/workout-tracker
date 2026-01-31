import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryEntryStats {
  final int exerciseCount;
  final int setCount;
  final double volume;

  const HistoryEntryStats({
    required this.exerciseCount,
    required this.setCount,
    required this.volume,
  });
}

HistoryEntryStats computeHistoryEntryStats(WorkoutHistoryEntry entry) {
  final exCount = entry.logs.length;

  final setCount = entry.logs.fold<int>(
    0,
    (sum, log) => sum + log.sets.length,
  );

  final volume = entry.logs.fold<double>(0.0, (sum, log) {
    return sum + log.sets.fold<double>(
      0.0,
      (s, set) => s + (set.weight * set.reps),
    );
  });

  return HistoryEntryStats(
    exerciseCount: exCount,
    setCount: setCount,
    volume: volume,
  );
}

String formatVolumeKg(double v) {
  if (v >= 100) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}
