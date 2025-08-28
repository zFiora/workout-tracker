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

@HiveType(typeId: 3)
class ExerciseLog {
  @HiveField(0)
  final int exerciseId;

  @HiveField(1)
  final List<PerformedSet> sets;

  ExerciseLog({required this.exerciseId, List<PerformedSet>? sets})
    : sets = sets ?? [];
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
