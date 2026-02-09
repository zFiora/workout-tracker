import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:workout_tracker/common/formatters/duarationFormatter.dart';
import 'package:workout_tracker/home/exercises/exerciesesList.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/PRHit.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/services/plannedSetMappingService.dart';
import 'package:workout_tracker/home/session/services/workoutSessionPRService.dart';

class WorkoutSessionViewModel extends ChangeNotifier {
  WorkoutSessionViewModel({
    required this.templateId,
    required this.templateName,
    required this.templateIcon,
    required this.exerciseIds,
    List<ExerciseModel>? exerciseCatalog,
    WorkoutSessionPrService? prService,
    PlannedSetMappingService? mappingService,
  }) : allExercises = exerciseCatalog ?? ExercisesViewModel.all,
       _prService = prService ?? WorkoutSessionPrService(),
       _mappingService = mappingService ?? PlannedSetMappingService() {
    _initLogs();
  }

  final String templateId;
  final String templateName;
  final List<int> exerciseIds;
  final String templateIcon;

  final List<ExerciseModel> allExercises;

  final WorkoutSessionPrService _prService;
  final PlannedSetMappingService _mappingService;

  DateTime? _startedAt;
  DateTime? _endedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  final Map<int, ExerciseLog> _logs = {};

  /// planned row (exerciseId:index) -> performed set timestamp created when marked done
  final Map<String, DateTime> _plannedToPerformedTs = {};

  /// PR hits keyed by "exerciseId:timestampMs"
  final Map<String, PrHit> _prHits = {};

  // ------------------- getters -------------------

  bool get isRunning => _ticker != null;
  Duration get elapsed => _elapsed;
  DateTime? get startedAt => _startedAt;

  UnmodifiableMapView<int, ExerciseLog> get logs => UnmodifiableMapView(_logs);
  UnmodifiableMapView<String, PrHit> get prHits => UnmodifiableMapView(_prHits);

  String get elapsedText => hhmmss(_elapsed);

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

  // ------------------- init -------------------

  void _initLogs() {
    for (final id in exerciseIds) {
      final ex = allExercises.firstWhere((e) => e.id == id);

      _logs[id] = ExerciseLog(
        exerciseId: id,
        exerciseName: ex.name,
        exerciseIcon: ex.workoutImage,
      );
    }
  }

  // ------------------- PR helpers -------------------

  void clearPrHits() {
    _prHits.clear();
    notifyListeners();
  }

  PrHit? prHitForPlannedRow({required int exerciseId, required int index}) {
    final ts = _plannedToPerformedTs['$exerciseId:$index'];
    if (ts == null) return null;
    return _prHits[_prService.prKey(exerciseId, ts)];
  }

  // ------------------- lifecycle -------------------

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
    if (!isRunning) throw StateError('Session not running');

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

  // ------------------- performed sets CRUD -------------------

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

  void updatePerformedSet({
    required int exerciseId,
    required int index,
    double? weight,
    int? reps,
    SetType? type,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    final old = log.sets[index];
    log.sets[index] = PerformedSet(
      weight: weight ?? old.weight,
      reps: reps ?? old.reps,
      timestamp: old.timestamp,
      type: type ?? old.type,
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

    final old = log.sets[index];
    log.sets[index] = old.copyWith(type: type);
    notifyListeners();
  }

  void removeSet(int exerciseId, int index) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.sets.length) return;

    final removed = log.sets.removeAt(index);
    _plannedToPerformedTs.removeWhere((_, ts) => ts == removed.timestamp);

    // also remove any PR hit tied to that removed performed set
    _prHits.remove(_prService.prKey(exerciseId, removed.timestamp));

    notifyListeners();
  }

  // ------------------- planned sets -------------------

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

    _plannedToPerformedTs.removeWhere(
      (key, _) => key.startsWith('$exerciseId:'),
    );
    log.plannedSets.clear();
    notifyListeners();
  }

  void addPlannedSetRow({
    required int exerciseId,
    SetType type = SetType.work,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;

    double? w;
    int? r;

    // prefer previous planned row
    for (int i = log.plannedSets.length - 1; i >= 0; i--) {
      final p = log.plannedSets[i];
      if (p.weight != null && p.reps != null) {
        w = p.weight;
        r = p.reps;
        break;
      }
    }

    // fallback to last performed set
    if (w == null || r == null) {
      if (log.sets.isNotEmpty) {
        final last = log.sets.last;
        w ??= last.weight;
        r ??= last.reps;
      }
    }

    log.plannedSets.add(
      PlannedSet(type: type, weight: w, reps: r, done: false),
    );
    notifyListeners();
  }

  void removePlannedSetRow({required int exerciseId, required int index}) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;
    if (log.plannedSets[index].done) return;

    _plannedToPerformedTs.remove('$exerciseId:$index');

    // remove row then rebuild mapping based on existing performed timestamps
    log.plannedSets.removeAt(index);
    _mappingService.rebuildMappingKeysForExercise(
      exerciseId: exerciseId,
      log: log,
      plannedToPerformedTs: _plannedToPerformedTs,
    );

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

    final old = log.plannedSets[index];

    final updated = old.copyWith(
      type: type ?? old.type,
      weight: weight ?? old.weight,
      reps: reps ?? old.reps,
    );

    log.plannedSets[index] = updated;

    // If already done, keep performed set in sync too
    if (updated.done) {
      final key = '$exerciseId:$index';
      final ts = _plannedToPerformedTs[key];
      if (ts != null) {
        final performedIndex = log.sets.indexWhere((s) => s.timestamp == ts);
        if (performedIndex != -1) {
          final w = updated.weight;
          final r = updated.reps;
          if (w != null && r != null) {
            updatePerformedSet(
              exerciseId: exerciseId,
              index: performedIndex,
              weight: w,
              reps: r,
              type: updated.type,
            );
            return;
          }
        }
      }
    }

    notifyListeners();
  }

  void markPlannedSetDone({
    required int exerciseId,
    required int index,
    required List<WorkoutHistoryEntry> history,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (p.done) return;

    final w = p.weight;
    final r = p.reps;
    if (w == null || r == null) return;

    final ts = DateTime.now();

    // mark done (replace planned row)
    log.plannedSets[index] = p.copyWith(done: true);

    // add performed set
    log.sets.add(PerformedSet(weight: w, reps: r, timestamp: ts, type: p.type));

    _plannedToPerformedTs['$exerciseId:$index'] = ts;

    final hit = _prService.bestWeightHitIfAny(
      exerciseId: exerciseId,
      performedAt: ts,
      weight: w,
      reps: r,
      history: history,
    );

    if (hit != null) {
      _prHits[_prService.prKey(exerciseId, ts)] = hit;
    }

    notifyListeners();
  }

  void undoPlannedSetDone({
    required int exerciseId,
    required int index,
    bool removePerformed = true,
  }) {
    final log = _logs[exerciseId];
    if (log == null) return;
    if (index < 0 || index >= log.plannedSets.length) return;

    final p = log.plannedSets[index];
    if (!p.done) return;

    final key = '$exerciseId:$index';
    final ts = _plannedToPerformedTs[key];

    // mark not done (replace planned row)
    log.plannedSets[index] = p.copyWith(done: false);

    if (removePerformed && ts != null) {
      final performedIndex = log.sets.indexWhere((s) => s.timestamp == ts);
      if (performedIndex != -1) {
        log.sets.removeAt(performedIndex);
      }
      _prHits.remove(_prService.prKey(exerciseId, ts));
    }

    _plannedToPerformedTs.remove(key);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
