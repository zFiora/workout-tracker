import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:workout_tracker/home/account/model/streakCalculator.dart';
import 'package:workout_tracker/home/account/model/streakSyncService.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/repos/hiveHistoryRepository.dart';
import 'package:workout_tracker/home/history/repos/hivePREventRepo.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/pr_events_api_service.dart';
import 'package:workout_tracker/home/history/services/workouts_api_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    StreakSyncService? sync,
    HistoryRepository? historyRepo,
    PrEventsRepository? prRepo,
    HistoryService? service,
    WorkoutsApiService? api,
    PrEventsApiService? prApi,
  }) : _sync = sync,
       _api = api ?? WorkoutsApiService(),
       _prApi = prApi ?? PrEventsApiService() {
    _historyRepo = historyRepo ?? HiveHistoryRepository();
    _prRepo = prRepo ?? HivePrEventsRepository();
    _service =
        service ?? HistoryService(historyRepo: _historyRepo, prRepo: _prRepo);

    // Initial compute
    _recomputeDerived();

    // Single refresh path: any Hive change triggers recompute + notify
    _sub = _historyRepo.watch((_) {
      _recomputeDerived();
      notifyListeners();
      _maybeSync();
    });

    _pullFromApi();
  }

  late final HistoryRepository _historyRepo;
  late final PrEventsRepository _prRepo;
  late final HistoryService _service;
  final WorkoutsApiService _api;
  final PrEventsApiService _prApi;

  StreakSyncService? _sync;
  StreamSubscription? _sub;

  // Cached derived state
  late List<HistoryItem> _historyItems;
  late List<WorkoutHistoryEntry> _history;
  late StreakInfo _streak;
  late Map<DateTime, List<WorkoutHistoryEntry>> _groupedByDay;

  void setSync(StreakSyncService? sync) => _sync = sync;

  List<HistoryItem> get historyItems => _historyItems;
  List<WorkoutHistoryEntry> get history => _history;
  HistoryService get service => _service;
  StreakInfo get streak => _streak;

  Map<DateTime, List<WorkoutHistoryEntry>> get groupedByDay => _groupedByDay;

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _service.save(entry);
    // No notify here. The repo watch will fire and update everything.
    _api.pushEntry(entry).catchError((_) {});
  }

  Future<void> saveWithPrEvents(
    WorkoutHistoryEntry entry, {
    required List<Map<String, dynamic>> prEvents,
  }) async {
    await _service.saveWithPrEvents(entry, prEvents: prEvents);
    // No notify here. Watch will handle it.
    _api.pushEntry(entry).catchError((_) {});
    _prApi.pushEvents(prEvents).catchError((_) {});
  }

  /// Best-effort pull of remote workouts not yet present locally (e.g.
  /// recorded on another device). Never blocks or fails the UI.
  Future<void> _pullFromApi() async {
    try {
      final remote = await _api.fetchAll();
      final local = _history;
      bool existsLocally(WorkoutHistoryEntry r) => local.any(
        (e) =>
            e.templateId == r.templateId &&
            e.startedAt.isAtSameMomentAs(r.startedAt),
      );

      for (final entry in remote) {
        if (!existsLocally(entry)) {
          await _historyRepo.add(entry);
        }
      }
    } catch (_) {
      // offline or auth error — local history is still shown
    }
  }

  Future<void> deleteByKey(dynamic key) async {
    await _service.deleteByKey(key);
    // Watch will handle it.
  }

  Future<void> clear() async {
    await _service.clear();
    // Watch will handle it.
  }

  void _recomputeDerived() {
    _historyItems = _service.historyItems;
    _history = List.unmodifiable(_historyItems.map((e) => e.entry));
    _streak = StreakCalculator.compute(_history.map((e) => e.endedAt));
    _groupedByDay = _service.groupedByDay();
  }

  void _maybeSync() {
    // Keep it optional and non-blocking for UI.
    // If you want strict sync guarantees, we can await in writes instead.
    final s = _sync;
    if (s == null) return;

    // Uncomment when ready:
    // unawaited(s.sync(_streak));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
