import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/account/model/streakSyncService.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

/// HistoryViewModel persists finished sessions in Hive and exposes:
/// - history list
/// - grouped-by-day convenience map
/// - total sets / volume helpers
/// - computed streak (current/best) using your "gap >= 3 days resets" rule
/// If a StreakSyncService is injected, it auto-pushes streak snapshots to PB
/// after save/delete/clear.
class HistoryViewModel extends ChangeNotifier {
  late final Box<WorkoutHistoryEntry> _box;
  StreakSyncService? _sync;

  StreamSubscription<BoxEvent>? _boxSub;

  HistoryViewModel({StreakSyncService? sync}) : _sync = sync {
    _box = Hive.box<WorkoutHistoryEntry>('historyBox');
    // If entries are changed elsewhere, keep listeners updated
    _boxSub = _box.watch().listen((_) => notifyListeners());
  }

  /// Allow late injection or refresh when the logged-in account changes.
  void setSync(StreakSyncService? sync) => _sync = sync;

  // ----- Getters -----

  /// Immutable snapshot of all saved entries.
  List<WorkoutHistoryEntry> get history => _box.values.toList(growable: false);

  /// Your rule: reset when TWO full days pass with no workout (gap >= 3 days).
  StreakInfo get streak {
    final dates = history.map((e) => e.endedAt);
    return StreakCalculator.compute(dates);
  }

  // ----- Mutations -----

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _box.add(entry);
    await _recomputeAndSync();
  }

  Future<void> deleteAt(int index) async {
    final key = _box.keyAt(index);
    await _box.delete(key);
    await _recomputeAndSync();
  }

  Future<void> clear() async {
    await _box.clear();
    await _recomputeAndSync();
  }

  // ----- Helpers -----

  int totalSets(WorkoutHistoryEntry e) =>
      e.logs.fold(0, (sum, log) => sum + log.sets.length);

  double totalVolume(WorkoutHistoryEntry e) => e.logs.fold(
    0.0,
    (sum, log) =>
        sum + log.sets.fold(0.0, (s, set) => s + (set.weight * set.reps)),
  );

  /// Returns a {dayStart: [entries...]} map.
  /// Keys are normalized to midnight for stable grouping.
  Map<DateTime, List<WorkoutHistoryEntry>> groupedByDay() {
    final map = <DateTime, List<WorkoutHistoryEntry>>{};
    for (final e in history) {
      final d = DateTime(e.endedAt.year, e.endedAt.month, e.endedAt.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    // Sort days descending (newest first)
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  // ----- Internal -----

  Future<void> _recomputeAndSync() async {
    // 1) Update UI immediately
    notifyListeners();

    // 2) Push to PocketBase (optional)
    //   final s = streak;
    //   final sync = _sync;
    //   if (sync != null) {
    //     try {
    //       await sync.push(s);
    //     } catch (e) {
    //       if (kDebugMode) {
    //         // Non-fatal: log locally; UI stays consistent with Hive.
    //         print('Streak sync failed: $e');
    //       }
    //     }
    //   }
    // }

    @override
    void dispose() {
      _boxSub?.cancel();
      super.dispose();
    }
  }
}
