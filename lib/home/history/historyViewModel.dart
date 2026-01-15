import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/account/model/streakSyncService.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  late final Box<WorkoutHistoryEntry> _box;
  StreakSyncService? _sync;

  StreamSubscription<BoxEvent>? _boxSub;

  HistoryViewModel({StreakSyncService? sync}) : _sync = sync {
    _box = Hive.box<WorkoutHistoryEntry>('historyBox');
    _boxSub = _box.watch().listen((_) => notifyListeners());
  }

  void setSync(StreakSyncService? sync) => _sync = sync;

  /// Key + entry pair (so sorting won't break delete).
  List<HistoryItem> get historyItems {
    final items = <HistoryItem>[];
    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry != null) items.add(HistoryItem(key: key, entry: entry));
    }

    // Newest first
    items.sort((a, b) => b.entry.endedAt.compareTo(a.entry.endedAt));
    return List.unmodifiable(items);
  }

  /// If you still need just entries (already sorted newest first).
  List<WorkoutHistoryEntry> get history =>
      List.unmodifiable(historyItems.map((e) => e.entry));

  StreakInfo get streak {
    final dates = history.map((e) => e.endedAt);
    return StreakCalculator.compute(dates);
  }

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _box.add(entry);
    await _recomputeAndSync();
  }

  Future<void> deleteByKey(dynamic key) async {
    await _box.delete(key);
    await _recomputeAndSync();
  }

  Future<void> clear() async {
    await _box.clear();
    await _recomputeAndSync();
  }

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
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  Future<void> _recomputeAndSync() async {
    notifyListeners();

    // Keep your sync code here later if you want.
  }

  @override
  void dispose() {
    _boxSub?.cancel();
    super.dispose();
  }
}

class HistoryItem {
  final dynamic key; // Hive keys can be int or String depending on box usage
  final WorkoutHistoryEntry entry;

  const HistoryItem({required this.key, required this.entry});
}
