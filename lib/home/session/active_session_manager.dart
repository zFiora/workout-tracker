import 'package:flutter/foundation.dart';
import 'package:workout_tracker/home/exercises/models/exerciseModel.dart';
import 'package:workout_tracker/home/session/models/sessionModels.dart';
import 'package:workout_tracker/home/session/sessionViewModel.dart';

/// Root-level ChangeNotifier that owns the currently active workout session.
/// Lives for the lifetime of the app so the timer survives navigation.
class ActiveSessionManager extends ChangeNotifier {
  WorkoutSessionViewModel? _session;
  List<ExerciseModel> _exercises = [];
  List<int> _originalExerciseIds = [];
  String? _templateId;
  String? _templateName;
  String? _templateIcon;

  // ── getters ──────────────────────────────────────────────────────────────

  WorkoutSessionViewModel? get session => _session;
  bool get hasActiveSession => _session != null;

  List<ExerciseModel> get exercises => List.unmodifiable(_exercises);
  String? get templateId => _templateId;
  String? get templateName => _templateName;
  String? get templateIcon => _templateIcon;

  /// True when exercises were added/removed mid-session vs original template.
  bool get exercisesWereModified {
    if (_session == null) return false;
    final current = _exercises.map((e) => e.id).toSet();
    final original = _originalExerciseIds.toSet();
    return !current.containsAll(original) || !original.containsAll(current);
  }

  // ── session lifecycle ─────────────────────────────────────────────────────

  void startSession({
    required String templateId,
    required String templateName,
    required String templateIcon,
    required List<ExerciseModel> exercises,
  }) {
    // tear down any previous session
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    _session = null;

    _templateId = templateId;
    _templateName = templateName;
    _templateIcon = templateIcon;
    _exercises = List.of(exercises);
    _originalExerciseIds = exercises.map((e) => e.id).toList();

    final vm = WorkoutSessionViewModel(
      templateId: templateId,
      templateName: templateName,
      templateIcon: templateIcon,
      exerciseIds: exercises.map((e) => e.id).toList(),
    )..start();

    vm.addListener(_onSessionChanged);
    _session = vm;
    notifyListeners();
  }

  /// Stops the timer, clears session state, and returns the history entry.
  /// Call BEFORE saving to HistoryViewModel.
  WorkoutHistoryEntry endSession() {
    final s = _session;
    if (s == null) throw StateError('No active session');

    s.removeListener(_onSessionChanged);
    final entry = s.end(); // stops timer; returns WorkoutHistoryEntry

    _session = null;
    _templateId = null;
    _templateName = null;
    _templateIcon = null;
    // keep _exercises / _originalExerciseIds until caller finishes comparing
    notifyListeners();
    return entry;
  }

  /// Clears exercise tracking state. Call after handling template-update dialog.
  void clearAfterEnd() {
    _exercises = [];
    _originalExerciseIds = [];
    notifyListeners();
  }

  /// Cancel session without saving.
  void discardSession() {
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    _session = null;
    _templateId = null;
    _templateName = null;
    _templateIcon = null;
    _exercises = [];
    _originalExerciseIds = [];
    notifyListeners();
  }

  // ── mid-session exercise editing ─────────────────────────────────────────

  void addExerciseToSession(ExerciseModel exercise) {
    if (_session == null) return;
    if (_exercises.any((e) => e.id == exercise.id)) return;
    _exercises = [..._exercises, exercise];
    _session!.addExercise(exercise);
    notifyListeners();
  }

  void removeExerciseFromSession(ExerciseModel exercise) {
    if (_session == null) return;
    if (!_exercises.any((e) => e.id == exercise.id)) return;
    _exercises = _exercises.where((e) => e.id != exercise.id).toList();
    _session!.removeExercise(exercise.id);
    notifyListeners();
  }

  // ── internal ─────────────────────────────────────────────────────────────

  void _onSessionChanged() => notifyListeners();

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _session?.cancel();
    super.dispose();
  }
}
