import 'package:shared_preferences/shared_preferences.dart';

/// Persists the workout-history reconciliation cursor, **scoped per account**.
///
/// The key embeds the authenticated user's id so two accounts on the same
/// device never share a cursor. A missing cursor means "do a full backfill from
/// the start"; once `hasMore == false`, the last cursor stored here is the
/// high-water mark reused for incremental reconciliation on later launches.
class HistoryReconcileCursorStore {
  const HistoryReconcileCursorStore();

  static const String keyPrefix = 'history_reconcile_cursor_';
  static String storageKey(String userId) => '$keyPrefix$userId';

  Future<String?> get(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(storageKey(userId));
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> set(String userId, String cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey(userId), cursor);
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey(userId));
  }
}
