import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/home/history/services/history_reconcile_cursor_store.dart';
import 'package:workout_tracker/home/history/services/pending_session_deletes_store.dart';

/// Guards against one account's locally-cached data leaking into another
/// account's session on a shared device.
///
/// Hive boxes are process-global and not scoped by user id, so logging in as
/// a different account than the one whose data is already cached on this
/// device would otherwise show that previous account's templates, history,
/// measurements, etc. Offline (no-account) usage is intentionally preserved
/// across a *first* login (no prior account on this device), so anything
/// created while offline can still sync up once the account is online.
class LocalDataGuard {
  LocalDataGuard._();

  static const _lastUserIdKey = 'last_authenticated_user_id';

  /// Call right after a login/register succeeds and the new token/userId is
  /// saved. Wipes locally-cached, account-owned data if the account signing
  /// in now differs from the one whose data is already on this device.
  static Future<void> onAuthenticated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUserId = prefs.getString(_lastUserIdKey);

    if (lastUserId != null && lastUserId != userId) {
      await _clearAccountOwnedCaches();
    }
    await prefs.setString(_lastUserIdKey, userId);
  }

  /// Boxes whose contents are shown live via a `watch()` subscription need
  /// per-key delete events so already-loaded view models drop stale data
  /// immediately, not just after their next full reload.
  static const _watchedBoxes = ['historyBox', 'templatesBox'];

  static const _unwatchedBoxes = [
    'measurementsBox',
    'measureProfileBox',
    'macrosProfileBox',
    'prEventsBox',
    'syncedSessionsBox',
    'syncedMeasurementsBox',
    'exerciseNotesBox',
    'activeSessionBox',
    'customExercisesBox',
  ];

  /// Wipes all locally-cached account data after the user deletes their
  /// account, and forgets the last-user marker so a fresh registration on this
  /// device starts clean. (The caller should reload any in-memory caches, e.g.
  /// [CustomExercisesRepository].)
  static Future<void> wipeAfterAccountDeletion() async {
    await _clearAccountOwnedCaches();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
  }

  static Future<void> _clearAccountOwnedCaches() async {
    try {
      for (final name in _watchedBoxes) {
        if (Hive.isBoxOpen(name)) {
          final box = Hive.box(name);
          await box.deleteAll(box.keys.toList());
        }
      }
      for (final name in _unwatchedBoxes) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).clear();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('account_cache');

      // Account-scoped history sync state (reconciliation cursors + offline
      // session-delete queues) lives in SharedPreferences, not Hive — drop it
      // so a different account never inherits another's cursor/queue.
      for (final k in prefs.getKeys().toList()) {
        if (k.startsWith(HistoryReconcileCursorStore.keyPrefix) ||
            k.startsWith(PendingSessionDeletesStore.keyPrefix)) {
          await prefs.remove(k);
        }
      }
    } catch (e) {
      debugPrint('[LocalDataGuard] failed to clear local caches: $e');
    }
  }
}
