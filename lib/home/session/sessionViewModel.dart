// viewmodels/workout_session_view_model.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
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
  final List<ExerciseModel> allExercises = ExercisesViewModel.all;

  WorkoutSessionViewModel({
    required this.templateId,
    required this.templateName,
    required this.templateIcon,
    required this.exerciseIds,
  }) {
    for (final id in exerciseIds) {
      final ex = allExercises.firstWhere((e) => e.id == id);

      _logs[id] = ExerciseLog(
        exerciseId: id,
        exerciseName: ex.name,
        exerciseIcon: ex.workoutImage,
      );
    }
  }

  bool get isRunning => _ticker != null;
  Duration get elapsed => _elapsed;
  DateTime? get startedAt => _startedAt;

  UnmodifiableMapView<int, ExerciseLog> get logs => UnmodifiableMapView(_logs);

  // ---------- UI-ready helpers ----------

  String get elapsedText => _format(_elapsed);

  int get totalSets =>
      _logs.values.fold(0, (sum, log) => sum + log.sets.length);

  int get totalWorkSets => _logs.values.fold(
        0,
        (sum, log) => sum + log.sets.where((s) => s.type == SetType.work).length,
      );

  double get totalVolume {
    double v = 0;
    for (final log in _logs.values) {
      for (final s in log.sets) {
        if (s.type != SetType.work) continue;
        v += (s.weight * s.reps);
      }
    }
    return v;
  }

  // ---------- Session lifecycle ----------

  void start() {
    if (isRunning) return;
    _startedAt = DateTime.now();
    _endedAt = null;
    _elapsed = Duration.zero;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      _elapsed = DateTime.now().difference(start);
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
    final start = _startedAt ?? _endedAt!;
    _elapsed = _endedAt!.difference(start);

    final entry = WorkoutHistoryEntry(
      templateIcon: templateIcon,
      templateId: templateId,
      templateName: templateName,
      startedAt: start,
      endedAt: _endedAt!,
      duration: _elapsed,
      logs: _logs.values
          .map(
            (e) => ExerciseLog(
              exerciseId: e.exerciseId,
              sets: List.of(e.sets),
              exerciseIcon: e.exerciseIcon,
              exerciseName: e.exerciseName,
              // plannedSets intentionally not persisted to history
            ),
          )
          .toList(),
    );

    notifyListeners();
    return entry;
  }

  // ---------- Performed sets CRUD ----------

  void addSet({
    required int exerciseId,
    required double weight,
    required int reps,
    SetType type = SetType.work,
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
    if (index < 0 || index >= log.sets.length) return;

    log.sets.removeAt(index);
    notifyListeners();
  }

  // ---------- Planned sets (your checklist UI) ----------

  void loadPlannedSetsFromLastWorkout({
    required int exerciseId,
    required List<PerformedSet> lastSets,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (lastSets.isEmpty) return;

    if (log.plannedSets.isNotEmpty) return;

    log.plannedSets
      ..clear()
      ..addAll(
        lastSets.map(
          (s) => PlannedSet(
            type: s.type,
            weight: s.weight,
            reps: s.reps,
            done: false,
          ),
        ),
      );

    notifyListeners();
  }

  void clearPlannedSets(int exerciseId) {
    final log = _logs[exerciseId];
    if (log == null) return;
    log.plannedSets.clear();
    notifyListeners();
  }

  void addPlannedSetRow({
    required int exerciseId,
    SetType type = SetType.work,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;

    log.plannedSets.add(PlannedSet(type: type));
    notifyListeners();
  }

  void removePlannedSetRow({
    required int exerciseId,
    required int index,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    if (log.plannedSets[index].done) return; // optional safety
    log.plannedSets.removeAt(index);
    notifyListeners();
  }

  void updatePlannedSet({
    required int exerciseId,
    required int index,
    double? weight,
    int? reps,
    SetType? type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (p.done) return;

    if (type != null) p.type = type;
    if (weight != null) p.weight = weight;
    if (reps != null) p.reps = reps;

    notifyListeners();
  }

  void markPlannedSetDone({
    required int exerciseId,
    required int index,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (p.done) return;

    final w = p.weight;
    final r = p.reps;
    if (w == null || r == null) return;

    p.done = true;

    log.sets.add(
      PerformedSet(
        weight: w,
        reps: r,
        timestamp: DateTime.now(),
        type: p.type,
      ),
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
