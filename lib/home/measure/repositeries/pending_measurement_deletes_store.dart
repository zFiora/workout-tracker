import 'package:shared_preferences/shared_preferences.dart';

/// Tracks measurement ids deleted while offline (or while the delete request
/// otherwise failed) so a later sync doesn't resurrect them.
///
/// Without this, `MeasuresViewModel._syncFromApi` would see the id still
/// present in the server's list (the delete never reached it) and re-add it
/// locally — an offline delete would silently "undo itself" the next time
/// the app comes back online.
class PendingMeasurementDeletesStore {
  static const _key = 'pending_deleted_measurement_ids';

  Future<Set<String>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> add(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? const []).toSet()..add(id);
    await prefs.setStringList(_key, ids.toList());
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? const []).toSet()..remove(id);
    await prefs.setStringList(_key, ids.toList());
  }
}
