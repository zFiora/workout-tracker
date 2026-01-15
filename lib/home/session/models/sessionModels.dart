import 'package:hive_flutter/hive_flutter.dart';

part 'sessionModels.g.dart';

@HiveType(typeId: 1)
enum SetType {
  @HiveField(0)
  work,
  @HiveField(1)
  warmup,
  @HiveField(2)
  dropset,
}

@HiveType(typeId: 2)
class PerformedSet {
  @HiveField(0)
  final double weight;

  @HiveField(1)
  final int reps;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  SetType type;

  PerformedSet({
    required this.weight,
    required this.reps,
    required this.timestamp,
    this.type = SetType.work,
  });

  get setType => type;
}

/// A planned row shown to the user (editable) before they mark it Done.
@HiveType(typeId: 5)
class PlannedSet {
  @HiveField(0)
  SetType type;

  @HiveField(1)
  double? weight;

  @HiveField(2)
  int? reps;

  @HiveField(3)
  bool done;

  PlannedSet({
    required this.type,
    this.weight,
    this.reps,
    this.done = false,
  });
}

@HiveType(typeId: 3)
class ExerciseLog {
  @HiveField(0)
  final int exerciseId;

  @HiveField(1)
  final List<PerformedSet> sets;

  @HiveField(2)
  String exerciseName;

  @HiveField(3)
  String exerciseIcon;

  // New: checklist rows prefilled from last workout
  @HiveField(4)
  final List<PlannedSet> plannedSets;

  ExerciseLog({
    required this.exerciseId,
    required this.exerciseIcon,
    required this.exerciseName,
    List<PerformedSet>? sets,
    List<PlannedSet>? plannedSets,
  })  : sets = sets ?? [],
        plannedSets = plannedSets ?? [];
}

@HiveType(typeId: 4)
class WorkoutHistoryEntry {
  @HiveField(0)
  final String templateId;

  @HiveField(1)
  final String templateName;

  @HiveField(2)
  final String templateIcon;

  @HiveField(3)
  final DateTime startedAt;

  @HiveField(4)
  final DateTime endedAt;

  @HiveField(5)
  final Duration duration;

  @HiveField(6)
  final List<ExerciseLog> logs;

  WorkoutHistoryEntry({
    required this.templateIcon,
    required this.templateId,
    required this.templateName,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.logs,
  });
}

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 50;

  @override
  Duration read(BinaryReader reader) {
    final ms = reader.readInt();
    return Duration(milliseconds: ms);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMilliseconds);
  }
}
