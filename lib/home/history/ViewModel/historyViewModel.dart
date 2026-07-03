import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:workout_tracker/core/services/synced_sessions_store.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/repos/hiveHistoryRepository.dart';
import 'package:workout_tracker/home/history/repos/hivePREventRepo.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/workout_sessions_api_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    HistoryRepository? historyRepo,
    PrEventsRepository? prRepo,
    HistoryService? service,
    WorkoutSessionsApiService? api,
    SyncedSessionsStore? syncedStore,
  }) : _api = api ?? WorkoutSessionsApiService(),
       _synced = syncedStore ?? SyncedSessionsStore() {
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
    });

    _pullFromApi();
  }

  late final HistoryRepository _historyRepo;
  late final PrEventsRepository _prRepo;
  late final HistoryService _service;
  final WorkoutSessionsApiService _api;
  final SyncedSessionsStore _synced;

  StreamSubscription? _sub;

  // Cached derived state
  late List<HistoryItem> _historyItems;
  late List<WorkoutHistoryEntry> _history;
  late Map<DateTime, List<WorkoutHistoryEntry>> _groupedByDay;

  List<HistoryItem> get historyItems => _historyItems;
  List<WorkoutHistoryEntry> get history => _history;
  HistoryService get service => _service;

  Map<DateTime, List<WorkoutHistoryEntry>> get groupedByDay => _groupedByDay;

  Future<void> save(WorkoutHistoryEntry entry) async {
    await _service.save(entry);
    // No notify here. The repo watch will fire and update everything.
    _pushOne(entry);
  }

  Future<void> saveWithPrEvents(
    WorkoutHistoryEntry entry, {
    required List<Map<String, dynamic>> prEvents,
  }) async {
    // prEvents are kept locally for in-session PR detection; the backend
    // derives PRs from the synced session itself, so they aren't pushed.
    await _service.saveWithPrEvents(entry, prEvents: prEvents);
    // No notify here. Watch will handle it.
    _pushOne(entry);
  }

  /// Pushes a single freshly-saved session; marks it synced on success.
  void _pushOne(WorkoutHistoryEntry entry) {
    _api.pushSessions([entry]).then(_synced.markSynced).catchError((_) {});
  }

  /// Reconciles history with the backend. Sessions are identified by their
  /// client UUID and upserted, so nothing ever duplicates. Server sessions the
  /// device lacks are pulled in; local sessions not yet confirmed synced (e.g.
  /// a workout finished offline) are pushed. Runs only after a successful
  /// fetch — offline leaves the cache untouched.
  Future<void> _pullFromApi() async {
    try {
      final remote = await _api.fetchRecent(sinceDays: 7);
      final localIds = _history.map((e) => e.id).toSet();

      // Pull down sessions recorded on other devices (new ids only).
      for (final entry in remote) {
        if (entry.id.isNotEmpty && !localIds.contains(entry.id)) {
          await _historyRepo.add(entry);
        }
      }
      // Everything the server returned is, by definition, already synced.
      await _synced.markSynced(remote.map((e) => e.id));

      // Push local sessions the server hasn't confirmed yet.
      final unsynced =
          _history.where((e) => e.id.isNotEmpty && !_synced.isSynced(e.id)).toList();
      if (unsynced.isNotEmpty) {
        final saved = await _api.pushSessions(unsynced);
        await _synced.markSynced(saved);
      }
    } catch (_) {
      // offline or auth error — cached history is still shown
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
    _groupedByDay = _service.groupedByDay();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
