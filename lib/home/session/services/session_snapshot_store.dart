import 'dart:convert';
import 'package:hive/hive.dart';

/// Persists a snapshot of the currently active workout session to Hive so an
/// in-progress workout survives the app being killed (OS memory pressure,
/// force-close, crash) — not just backgrounded.
///
/// Session state otherwise lives only in [WorkoutSessionViewModel]'s memory,
/// so without this a killed app loses every set logged since the workout
/// started. [ActiveSessionManager] writes a snapshot after each meaningful
/// change and clears it when the session ends or is discarded.
class SessionSnapshotStore {
  static const boxName = 'activeSessionBox';
  static const _key = 'current';

  Box get _box => Hive.box(boxName);

  Future<void> save(Map<String, dynamic> snapshotJson) async {
    await _box.put(_key, jsonEncode(snapshotJson));
  }

  Map<String, dynamic>? read() {
    final raw = _box.get(_key) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _box.delete(_key);
}
