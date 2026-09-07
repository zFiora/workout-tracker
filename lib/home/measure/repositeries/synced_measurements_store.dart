import 'package:hive/hive.dart';

/// Tracks which locally-stored measurement entries the backend has already
/// accepted, so a background sync only ever deletes an entry the server
/// itself deleted — never one that's simply still offline/pending.
///
/// Mirrors [SyncedSessionsStore]'s pattern. Keyed by the entry's id. The box
/// is opened in `main()`.
class SyncedMeasurementsStore {
  SyncedMeasurementsStore({Box<bool>? box})
      : _box = box ?? Hive.box<bool>('syncedMeasurementsBox');

  final Box<bool> _box;

  bool isSynced(String id) => id.isNotEmpty && _box.get(id) == true;

  Future<void> markSynced(String id) async {
    if (id.isNotEmpty) await _box.put(id, true);
  }

  Future<void> markSyncedAll(Iterable<String> ids) async {
    for (final id in ids) {
      await markSynced(id);
    }
  }

  Future<void> forget(String id) => _box.delete(id);
}
