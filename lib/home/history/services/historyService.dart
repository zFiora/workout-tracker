import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryItem {
  final dynamic key;
  final WorkoutHistoryEntry entry;
  const HistoryItem({required this.key, required this.entry});
}

class HistoryService {
  HistoryService({
    required HistoryRepository historyRepo,
    required PrEventsRepository prRepo,
  }) : _historyRepo = historyRepo,
       _prRepo = prRepo;

  final HistoryRepository _historyRepo;
  final PrEventsRepository _prRepo;

  List<HistoryItem> get historyItems {
    final records = _historyRepo.getAllRecords();

    final items = records
        .map((r) => HistoryItem(key: r.key, entry: r.entry))
        .toList();

    items.sort((a, b) => b.entry.endedAt.compareTo(a.entry.endedAt));
    return List.unmodifiable(items);
  }

  List<WorkoutHistoryEntry> get history =>
      List.unmodifiable(historyItems.map((e) => e.entry));

  StreakInfo computeStreak() {
    final dates = history.map((e) => e.endedAt);
    return StreakCalculator.compute(dates);
  }

  Future<dynamic> save(WorkoutHistoryEntry entry) async {
    return await _historyRepo.add(entry);
  }

  Future<dynamic> saveWithPrEvents(
    WorkoutHistoryEntry entry, {
    required List<Map<String, dynamic>> prEvents,
  }) async {
    final key = await _historyRepo.add(entry);
    await _prRepo.putEventsForHistoryKey(key, prEvents);
    return key;
  }

  Future<void> deleteByKey(dynamic key) async {
    await _historyRepo.deleteByKey(key);
    await _prRepo.deleteEventsForHistoryKey(key);
  }

  Future<void> clear() async {
    await _historyRepo.clear();
    await _prRepo.clearAll();
  }

  Map<DateTime, List<WorkoutHistoryEntry>> groupedByDay() {
    final map = <DateTime, List<WorkoutHistoryEntry>>{};
    for (final e in history) {
      final d = DateTime(e.endedAt.year, e.endedAt.month, e.endedAt.day);
      map.putIfAbsent(d, () => []).add(e);
    }

    // Optional: sort each day’s entries newest -> oldest
    for (final list in map.values) {
      list.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: List.unmodifiable(map[k]!)};
  }

  Future<Set<String>> loadBestWeightPrKeys(dynamic historyKey) async {
    final events = await _prRepo.loadEventsForHistoryKey(historyKey);

    final keys = <String>{};

    for (final e in events) {
      final exId = e['exerciseId'];
      final performedAt = e['performedAt'];
      final kind = e['kind'];

      if (kind != 'bestWeight') continue;
      if (exId is! int) continue;
      if (performedAt is! String) continue;

      final dt = DateTime.tryParse(performedAt);
      if (dt == null) continue;

      keys.add(PrEventKey.of(exId, dt));
    }

    return keys;
  }

  bool isPr(Set<String> prKeys, int exId, DateTime setTs) {
    return prKeys.contains(PrEventKey.of(exId, setTs));
  }
}
