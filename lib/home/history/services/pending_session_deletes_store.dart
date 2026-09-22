import 'package:shared_preferences/shared_preferences.dart';

/// Tracks workout-session ids the user deleted while offline (or when the
/// DELETE otherwise failed), **scoped per account**, so a later reconciliation
/// can retry the server delete and — crucially — never re-pushes or re-adds a
/// session that's pending deletion (which would resurrect it).
///
/// Mirrors the measurements pattern ([PendingMeasurementDeletesStore]).
class PendingSessionDeletesStore {
  const PendingSessionDeletesStore();

  static const String keyPrefix = 'pending_deleted_session_ids_';
  static String storageKey(String userId) => '$keyPrefix$userId';

  Future<Set<String>> all(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(storageKey(userId)) ?? const []).toSet();
  }

  Future<bool> contains(String userId, String id) async {
    return (await all(userId)).contains(id);
  }

  Future<void> add(String userId, String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(storageKey(userId)) ?? const []).toSet()
      ..add(id);
    await prefs.setStringList(storageKey(userId), ids.toList());
  }

  Future<void> remove(String userId, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(storageKey(userId)) ?? const []).toSet()
      ..remove(id);
    await prefs.setStringList(storageKey(userId), ids.toList());
  }
}
