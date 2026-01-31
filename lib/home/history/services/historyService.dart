import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';


class HistoryService {
  HistoryService({
    required HistoryRepository historyRepo,
    required PrEventsRepository prRepo,
  }) : _historyRepo = historyRepo,
       _prRepo = prRepo;

  final HistoryRepository _historyRepo;
  final PrEventsRepository _prRepo;

  List<HistoryItem> get historyItems => _historyRepo.getAllItemsSorted();

  List<WorkoutHistoryEntry> get history =>
      List.unmodifiable(historyItems.map((e) => e.entry));

  StreakInfo computeStreak() {
    final dates = history.map((e) => e.endedAt);
    return StreakCalculator.compute(dates);
  }

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _historyRepo.add(entry);
  }

  Future<void> saveWithPrEvents(
    WorkoutHistoryEntry entry, {
    required dynamic historyKey, // optional override (rare)
    required List<Map<String, dynamic>> prEvents,
  }) async {
    // If caller already has a key, keep it. Otherwise add and get one.
    final key = historyKey ?? await _historyRepo.add(entry);
    await _prRepo.putEventsForHistoryKey(key, prEvents);
  }

  Future<void> deleteByKey(dynamic key) async {
    await _historyRepo.delete(key);
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
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }
}
