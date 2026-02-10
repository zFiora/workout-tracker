import 'dart:async';
import 'package:hive/hive.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class HistoryRecord {
  final dynamic key;
  final WorkoutHistoryEntry entry;

  const HistoryRecord({required this.key, required this.entry});
}

abstract class HistoryRepository {
  StreamSubscription<BoxEvent> watch(void Function(BoxEvent) onEvent);

  /// Returns all history entries with their Hive keys.
  /// Repo owns how keys/values are read safely.
  List<HistoryRecord> getAllRecords();

  WorkoutHistoryEntry? get(dynamic key);

  Future<dynamic> add(WorkoutHistoryEntry entry);
  Future<void> deleteByKey(dynamic key);
  Future<void> clear();
}
