// viewmodels/workout_session_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';

class WorkoutSessionViewModel extends ChangeNotifier {
  final String templateId;
  final String templateName;
  final List<int> exerciseIds;
  final String templateIcon;
  DateTime? _startedAt;
  DateTime? _endedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  final Map<int, ExerciseLog> _logs = {};

  WorkoutSessionViewModel({
    required this.templateId,
    required this.templateName,
    required this.templateIcon,
    required this.exerciseIds,
  }) {
    for (final id in exerciseIds) {
      _logs[id] = ExerciseLog(exerciseId: id);
    }
  }

  bool get isRunning => _ticker != null;
  Duration get elapsed => _elapsed;
  DateTime? get startedAt => _startedAt;
  Map<int, ExerciseLog> get logs => _logs;

  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(_startedAt!);
      notifyListeners();
    });
    notifyListeners();
  }

  WorkoutHistoryEntry end() {
    if (!isRunning) {
      throw StateError('Session not running');
    }
    _ticker?.cancel();
    _ticker = null;
    _endedAt = DateTime.now();
    _elapsed = _endedAt!.difference(_startedAt!);

    final entry = WorkoutHistoryEntry(
      templateIcon: templateIcon,
      templateId: templateId,
      templateName: templateName,
      startedAt: _startedAt!,
      endedAt: _endedAt!,
      duration: _elapsed,
      logs: _logs.values
          .map(
            (e) => ExerciseLog(exerciseId: e.exerciseId, sets: List.of(e.sets)),
          )
          .toList(),
    );

    notifyListeners();
    return entry;
  }

  // sessionViewModel.dart (WorkoutSessionViewModel)
  void addSet({
    required int exerciseId,
    required double weight,
    required int reps,
    SetType type = SetType.work, // <---
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    log.sets.add(
      PerformedSet(
        weight: weight,
        reps: reps,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    notifyListeners();
  }

  void updateSetType({
    required int exerciseId,
    required int index,
    required SetType type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;
    log.sets[index].type = type;
    notifyListeners();
  }

  void removeSet(int exerciseId, int index) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index >= 0 && index < log.sets.length) {
      log.sets.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
