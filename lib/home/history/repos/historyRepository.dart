import 'dart:async';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryRepository {
  HistoryRepository({String boxName = 'historyBox'}) : _boxName = boxName;

  final String _boxName;
  Box<WorkoutHistoryEntry> get _box => Hive.box<WorkoutHistoryEntry>(_boxName);

  StreamSubscription<BoxEvent> watch(void Function(BoxEvent) onEvent) {
    return _box.watch().listen(onEvent);
  }

  List<HistoryItem> getAllItemsSorted() {
    final items = <HistoryItem>[];

    for (final key in _box.keys) {
      final entry = _box.get(key);
      if (entry != null) items.add(HistoryItem(key: key, entry: entry));
    }

    items.sort((a, b) => b.entry.endedAt.compareTo(a.entry.endedAt));
    return List.unmodifiable(items);
  }

  Future<dynamic> add(WorkoutHistoryEntry entry) => _box.add(entry);

  Future<void> delete(dynamic key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}

class HistoryItem {
  final dynamic key;
  final WorkoutHistoryEntry entry;

  const HistoryItem({required this.key, required this.entry});
}
