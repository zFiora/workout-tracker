import 'package:hive/hive.dart';

/// Tracks which locally-stored workout sessions the backend has already
/// accepted, so a reconcile only pushes what's actually outstanding.
///
/// Keyed by the session's client UUID. The box is opened in `main()`.
class SyncedSessionsStore {
  SyncedSessionsStore({Box<bool>? box})
      : _box = box ?? Hive.box<bool>('syncedSessionsBox');

  final Box<bool> _box;

  bool isSynced(String id) => id.isNotEmpty && _box.get(id) == true;

  Future<void> markSynced(Iterable<String> ids) async {
    for (final id in ids) {
      if (id.isNotEmpty) await _box.put(id, true);
    }
  }
}
