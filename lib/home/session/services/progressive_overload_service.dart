import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// A suggested target for one set, derived from last time's performance.
class ProgressionTarget {
  const ProgressionTarget({required this.weightKg, required this.reps});
  final double weightKg;
  final int reps;
}

/// Conservative "double-progression" assistant.
///
/// It never blindly adds weight every session. Reading each *work* set the
/// user performed last time:
///   • strong set (reps at/above [repCeiling]) → add one [incrementKg] step,
///     keep the reps (you earned the load);
///   • mid set (below the ceiling, at/above [repFloor]) → keep the weight and
///     aim for one more rep (earn the reps first);
///   • grind set (below [repFloor]) → repeat exactly, to consolidate.
///
/// Warm-up / drop sets are ignored — progression only concerns work sets.
/// Returns an empty list when there's no usable history, so the caller simply
/// shows nothing.
class ProgressiveOverloadService {
  const ProgressiveOverloadService({
    this.incrementKg = 2.5,
    this.repCeiling = 8,
    this.repFloor = 5,
  });

  final double incrementKg;
  final int repCeiling;
  final int repFloor;

  List<ProgressionTarget> suggestFrom(List<PerformedSet> lastSets) {
    final work = lastSets.where((s) => s.type == SetType.work).toList();
    if (work.isEmpty) return const [];

    return work.map((s) {
      if (s.reps >= repCeiling) {
        return ProgressionTarget(weightKg: s.weight + incrementKg, reps: s.reps);
      }
      if (s.reps >= repFloor) {
        return ProgressionTarget(weightKg: s.weight, reps: s.reps + 1);
      }
      return ProgressionTarget(weightKg: s.weight, reps: s.reps);
    }).toList();
  }

  /// True when the suggestion actually differs from what was done last time
  /// (so the UI doesn't offer a no-op "apply").
  bool differsFrom(
    List<ProgressionTarget> targets,
    List<PerformedSet> lastSets,
  ) {
    final work = lastSets.where((s) => s.type == SetType.work).toList();
    if (targets.length != work.length) return true;
    for (var i = 0; i < targets.length; i++) {
      if (targets[i].weightKg != work[i].weight ||
          targets[i].reps != work[i].reps) {
        return true;
      }
    }
    return false;
  }
}
