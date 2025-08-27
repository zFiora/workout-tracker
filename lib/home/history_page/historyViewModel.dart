import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';


class HistoryViewModel extends ChangeNotifier {
  final List<WorkoutHistoryEntry> _history = [];

  List<WorkoutHistoryEntry> get history => List.unmodifiable(_history);

  Future<void> save(WorkoutHistoryEntry entry) async {
    // TODO: Persist with Hive/SQL
    _history.add(entry);
    notifyListeners();
  }
}
