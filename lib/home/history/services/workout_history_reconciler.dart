import 'package:workout_tracker/core/auth_token.dart';
import 'package:workout_tracker/core/services/synced_sessions_store.dart';
import 'package:workout_tracker/home/history/services/history_reconcile_cursor_store.dart';
import 'package:workout_tracker/home/history/services/historyService.dart';
import 'package:workout_tracker/home/history/services/pending_session_deletes_store.dart';
import 'package:workout_tracker/home/history/services/workout_sessions_api_service.dart';

/// Reconciles the local workout-history cache with the backend change-feed.
///
/// Flow (all keyed by the session's client UUID, so everything is idempotent):
///   1. Flush any offline session deletes (retry `DELETE` per queued id).
///   2. Page `/api/workout-sessions/history` from the saved per-account cursor
///      until `hasMore == false`, persisting the cursor progressively so an
///      interrupted backfill resumes where it left off.
///   3. Apply each change: tombstones remove the local session; upserts add it
///      if absent (sessions are immutable once saved). A session currently
///      pending local deletion is never re-added — that's the no-resurrection
///      guarantee on the client side.
///   4. If the server rejects the cursor, reset once and full-backfill.
///
/// It is purely a sync concern — the UI updates itself via the history box
/// `watch()` subscription in [HistoryService]/the view model, not from here.
class WorkoutHistoryReconciler {
  WorkoutHistoryReconciler({
    required HistoryService service,
    WorkoutSessionsApiService? api,
    HistoryReconcileCursorStore? cursorStore,
    PendingSessionDeletesStore? pendingDeletes,
    SyncedSessionsStore? synced,
    String? Function()? userIdProvider,
    int pageLimit = 200,
    int maxPages = 10000,
  })  : _service = service,
        _api = api ?? WorkoutSessionsApiService(),
        _cursorStore = cursorStore ?? const HistoryReconcileCursorStore(),
        _pendingDeletes = pendingDeletes ?? const PendingSessionDeletesStore(),
        _synced = synced ?? SyncedSessionsStore(),
        _userIdProvider = userIdProvider ?? (() => AuthToken.I.userId),
        _pageLimit = pageLimit,
        _maxPages = maxPages;

  final HistoryService _service;
  final WorkoutSessionsApiService _api;
  final HistoryReconcileCursorStore _cursorStore;
  final PendingSessionDeletesStore _pendingDeletes;
  final SyncedSessionsStore _synced;
  final String? Function() _userIdProvider;
  final int _pageLimit;
  final int _maxPages;

  bool _running = false;

  /// Runs a reconciliation pass. Safe to call repeatedly and concurrently — a
  /// pass already in flight is a no-op (duplicate-sync safety). Never throws:
  /// offline / server errors leave the cursor and cache intact for next time.
  Future<void> reconcile() async {
    final userId = _userIdProvider();
    if (userId == null || userId.isEmpty) return; // not signed in
    if (_running) return;
    _running = true;
    try {
      await _flushPendingDeletes(userId);

      // Snapshot local id → Hive key once; keep it in step as we mutate.
      final idToKey = <String, dynamic>{};
      for (final item in _service.historyItems) {
        final id = item.entry.id;
        if (id.isNotEmpty) idToKey[id] = item.key;
      }

      var cursor = await _cursorStore.get(userId);
      var didReset = false;
      var pages = 0;

      while (pages++ < _maxPages) {
        final requestCursor = cursor;
        RemoteSessionPage page;
        try {
          page = await _api.fetchHistoryPage(
            cursor: requestCursor,
            limit: _pageLimit,
          );
        } on CursorInvalidException {
          if (didReset) rethrow; // already retried once — give up this pass
          await _cursorStore.clear(userId);
          cursor = null;
          didReset = true;
          continue; // full backfill from the start
        }

        await _applyPage(page, userId, idToKey);

        // Persist progress so an interrupted backfill resumes here next time.
        if (page.nextCursor != null && page.nextCursor != requestCursor) {
          cursor = page.nextCursor;
          await _cursorStore.set(userId, cursor!);
        }

        if (!page.hasMore) break;
        // Defensive: no forward progress → stop rather than loop forever.
        if (page.nextCursor == null || page.nextCursor == requestCursor) break;
      }
    } catch (_) {
      // Offline / transient server error — keep cursor + cache for next pass.
    } finally {
      _running = false;
    }
  }

  Future<void> _flushPendingDeletes(String userId) async {
    for (final id in await _pendingDeletes.all(userId)) {
      try {
        await _api.deleteSession(id);
        await _pendingDeletes.remove(userId, id);
      } catch (_) {
        // Still offline / failing — leave queued for the next pass.
      }
    }
  }

  Future<void> _applyPage(
    RemoteSessionPage page,
    String userId,
    Map<String, dynamic> idToKey,
  ) async {
    for (final change in page.changes) {
      if (change.id.isEmpty) continue;

      if (change.deleted) {
        // Tombstone: remove locally (also clears its PR events via the service)
        // and clear any of our own pending delete for it (server already did).
        final key = idToKey.remove(change.id);
        if (key != null) await _service.deleteByKey(key);
        await _synced.markSynced([change.id]);
        await _pendingDeletes.remove(userId, change.id);
        continue;
      }

      // Upsert. Never resurrect a session we're locally deleting.
      if (await _pendingDeletes.contains(userId, change.id)) continue;
      if (idToKey.containsKey(change.id)) {
        await _synced.markSynced([change.id]); // already have it — just confirm
        continue;
      }
      final entry = change.entry;
      if (entry == null) continue;
      final key = await _service.save(entry);
      idToKey[change.id] = key;
      await _synced.markSynced([change.id]);
    }
  }
}
