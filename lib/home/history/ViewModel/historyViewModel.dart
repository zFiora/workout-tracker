import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/core/services/network_reconnect_notifier.dart';
import 'package:workout_tracker/core/services/reconnect_sync_binder.dart';
import 'package:workout_tracker/core/services/synced_sessions_store.dart';
import 'package:workout_tracker/home/history/repos/PREventRepository.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/history/repos/hiveHistoryRepository.dart';
import 'package:workout_tracker/home/history/repos/hivePREventRepo.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/pending_session_deletes_store.dart';
import 'package:workout_tracker/home/history/services/workout_history_reconciler.dart';
import 'package:workout_tracker/home/history/services/workout_sessions_api_service.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    HistoryRepository? historyRepo,
    PrEventsRepository? prRepo,
    HistoryService? service,
    WorkoutSessionsApiService? api,
    SyncedSessionsStore? syncedStore,
    PendingSessionDeletesStore? pendingDeletes,
    WorkoutHistoryReconciler? reconciler,
    NetworkReconnectNotifier? reconnectNotifier,
  }) : _api = api ?? WorkoutSessionsApiService(),
       _synced = syncedStore ?? SyncedSessionsStore(),
       _pendingDeletes = pendingDeletes ?? const PendingSessionDeletesStore() {
    _historyRepo = historyRepo ?? HiveHistoryRepository();
    _prRepo = prRepo ?? HivePrEventsRepository();
    _service =
        service ?? HistoryService(historyRepo: _historyRepo, prRepo: _prRepo);
    _reconciler = reconciler ??
        WorkoutHistoryReconciler(
          service: _service,
          api: _api,
          pendingDeletes: _pendingDeletes,
          synced: _synced,
        );

    // Initial compute
    _recomputeDerived();

    // Single refresh path: any Hive change triggers recompute + notify
    _sub = _historyRepo.watch((_) {
      _recomputeDerived();
      notifyListeners();
    });

    // Fast path first (recent 7-day bootstrap for a responsive History tab),
    // then the full/incremental reconciliation in the background. Chaining
    // (rather than firing both at once) avoids the two racing to add the same
    // session twice.
    _pullFromApi().whenComplete(_reconcile);

    // Retry pending deletes + reconciliation whenever connectivity returns.
    // The reconciler's in-flight guard drops any overlap, so this never causes
    // a concurrent run; it does not poll.
    _reconnectBinder = ReconnectSyncBinder(
      reconnectNotifier ?? ConnectivityReconnectNotifier(),
      _reconcile,
    );
  }

  late final HistoryRepository _historyRepo;
  late final PrEventsRepository _prRepo;
  late final HistoryService _service;
  late final WorkoutHistoryReconciler _reconciler;
  final WorkoutSessionsApiService _api;
  final SyncedSessionsStore _synced;
  final PendingSessionDeletesStore _pendingDeletes;

  StreamSubscription? _sub;
  ReconnectSyncBinder? _reconnectBinder;

  // Cached derived state
  late List<HistoryItem> _historyItems;
  late List<WorkoutHistoryEntry> _history;
  late Map<DateTime, List<WorkoutHistoryEntry>> _groupedByDay;

  List<HistoryItem> get historyItems => _historyItems;
  List<WorkoutHistoryEntry> get history => _history;
  HistoryService get service => _service;

  Map<DateTime, List<WorkoutHistoryEntry>> get groupedByDay => _groupedByDay;

  Future<void> save(WorkoutHistoryEntry entry) async {
    // If this is an "undo" of a just-deleted session, cancel its queued
    // server-delete so a later reconciliation doesn't remove it again.
    final userId = AuthToken.I.userId;
    if (userId != null && entry.id.isNotEmpty) {
      await _pendingDeletes.remove(userId, entry.id);
    }
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

      // Push local sessions the server hasn't confirmed yet — but never a
      // session that's pending local deletion (that would resurrect it).
      final userId = AuthToken.I.userId;
      final pending =
          userId == null ? <String>{} : await _pendingDeletes.all(userId);
      final unsynced = _history
          .where((e) =>
              e.id.isNotEmpty &&
              !_synced.isSynced(e.id) &&
              !pending.contains(e.id))
          .toList();
      if (unsynced.isNotEmpty) {
        final saved = await _api.pushSessions(unsynced);
        await _synced.markSynced(saved);
      }
    } catch (_) {
      // offline or auth error — cached history is still shown
    }
  }

  Future<void> _reconcile() async {
    try {
      await _reconciler.reconcile();
    } catch (_) {
      // Reconciliation is best-effort; the box watch keeps the UI current.
    }
  }

  Future<void> deleteByKey(dynamic key) async {
    // Grab the id before the local delete removes it.
    final id = _historyRepo.get(key)?.id;

    // Offline-first: remove locally immediately (also clears its PR events).
    await _service.deleteByKey(key); // watch updates the UI

    if (id == null || id.isEmpty) return;
    final userId = AuthToken.I.userId;
    if (userId == null) return; // guest/offline account — nothing server-side

    // Queue first so a crash before the network call still deletes on the next
    // sync, then try immediately and dequeue on success. A failure (offline)
    // leaves it queued for the reconciler to flush on reconnect.
    await _pendingDeletes.add(userId, id);
    try {
      await _api.deleteSession(id);
      await _pendingDeletes.remove(userId, id);
    } catch (_) {
      // stays queued
    }
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
    _reconnectBinder?.dispose();
    super.dispose();
  }
}
