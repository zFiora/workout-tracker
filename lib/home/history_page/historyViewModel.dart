import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  final List<WorkoutHistoryEntry> _history = [];

  List<WorkoutHistoryEntry> get history => List.unmodifiable(
    _history..sort((a, b) => b.endedAt.compareTo(a.endedAt)),
  );

  Future<void> save(WorkoutHistoryEntry entry) async {
    _history.add(entry);
    notifyListeners();
  }

  // ----- Helpers -----
  int totalSets(WorkoutHistoryEntry e) =>
      e.logs.fold(0, (sum, log) => sum + log.sets.length);

  double totalVolume(WorkoutHistoryEntry e) => e.logs.fold(
    0.0,
    (sum, log) =>
        sum + log.sets.fold(0.0, (s, set) => s + (set.weight * set.reps)),
  );

  Map<DateTime, List<WorkoutHistoryEntry>> groupedByDay() {
    final map = <DateTime, List<WorkoutHistoryEntry>>{};
    for (final e in history) {
      final d = DateTime(e.endedAt.year, e.endedAt.month, e.endedAt.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    // sort days desc
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }
}
