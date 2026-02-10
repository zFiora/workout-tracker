import 'dart:async';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/history/repos/historyRepository.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HiveHistoryRepository implements HistoryRepository {
  HiveHistoryRepository({String boxName = 'historyBox'}) : _boxName = boxName;

  final String _boxName;
  Box<WorkoutHistoryEntry> get _box => Hive.box<WorkoutHistoryEntry>(_boxName);

  @override
  StreamSubscription<BoxEvent> watch(void Function(BoxEvent) onEvent) {
    return _box.watch().listen(onEvent);
  }

  @override
  List<HistoryRecord> getAllRecords() {
    final records = <HistoryRecord>[];

    // values are ordered by insertion, keys aligns with values order.
    // but we still read via key iteration to guarantee key->value pairing.
    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry == null) continue;
      records.add(HistoryRecord(key: key, entry: entry));
    }

    return records;
  }

  @override
  WorkoutHistoryEntry? get(dynamic key) => _box.get(key);

  @override
  Future<dynamic> add(WorkoutHistoryEntry entry) => _box.add(entry);

  @override
  Future<void> deleteByKey(dynamic key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear();
}
