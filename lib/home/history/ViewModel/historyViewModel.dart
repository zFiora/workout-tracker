import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/account/model/streakSyncService.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    StreakSyncService? sync,
    HistoryRepository? historyRepo,
    PrEventsRepository? prRepo,
  }) : _sync = sync {
    _historyRepo = historyRepo ?? HistoryRepository();
    _prRepo = prRepo ?? PrEventsRepository();
    _service = HistoryService(historyRepo: _historyRepo, prRepo: _prRepo);

    _boxSub = _historyRepo.watch((_) => notifyListeners());
  }

  late final HistoryRepository _historyRepo;
  late final PrEventsRepository _prRepo;
  late final HistoryService _service;

  // ignore: unused_field
  StreakSyncService? _sync;
  StreamSubscription<BoxEvent>? _boxSub;

  void setSync(StreakSyncService? sync) => _sync = sync;

  List<HistoryItem> get historyItems => _service.historyItems;

  List<WorkoutHistoryEntry> get history => _service.history;

  StreakInfo get streak => _service.computeStreak();

  Map<DateTime, List<WorkoutHistoryEntry>> groupedByDay() =>
      _service.groupedByDay();

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _service.save(entry);
    await _recomputeAndSync();
  }

  Future<void> saveWithPrEvents(
    WorkoutHistoryEntry entry, {
    required List<Map<String, dynamic>> prEvents,
  }) async {
    // store workout first, get key, then store PR events against that key
    final key = await Hive.box<WorkoutHistoryEntry>('historyBox').add(entry);
    await _prRepo.putEventsForHistoryKey(key, prEvents);

    await _recomputeAndSync();
  }

  Future<void> deleteByKey(dynamic key) async {
    await _service.deleteByKey(key);
    await _recomputeAndSync();
  }

  Future<void> clear() async {
    await _service.clear();
    await _recomputeAndSync();
  }

  Future<void> _recomputeAndSync() async {
    notifyListeners();
    // Keep your sync code here later if you want.
    // Example future usage:
    // if (_sync != null) await _sync!.sync(streak);
  }

  @override
  void dispose() {
    _boxSub?.cancel();
    super.dispose();
  }
}
