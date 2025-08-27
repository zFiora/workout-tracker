enum SetType { work, warmup, dropset }

class PerformedSet {
  final double weight;
  final int reps;
  final DateTime timestamp;
  SetType type;
  // final int oldRecordWeight;
  // final int oldRecordReps; 

  PerformedSet({
    required this.weight,
    required this.reps,
    required this.timestamp,
    // required this.oldRecordWeight,
    // required this.oldRecordReps,
    this.type = SetType.work,
  });

  get setType => type;
}

class ExerciseLog {
  final int exerciseId;
  final List<PerformedSet> sets;

  ExerciseLog({required this.exerciseId, List<PerformedSet>? sets})
      : sets = sets ?? [];
}

class WorkoutHistoryEntry {
  final String templateId;
  final String templateName;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final List<ExerciseLog> logs;

  WorkoutHistoryEntry({
    required this.templateId,
    required this.templateName,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.logs,
  });
}
