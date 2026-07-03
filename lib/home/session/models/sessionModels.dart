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

extension SetTypeCodec on SetType {
  String toShort() {
    switch (this) {
      case SetType.work:
        return 'work';
      case SetType.warmup:
        return 'warmup';
      case SetType.dropset:
        return 'dropset';
    }
  }

  static SetType fromShort(String v) {
    switch (v) {
      case 'warmup':
        return SetType.warmup;
      case 'dropset':
        return SetType.dropset;
      case 'work':
      default:
        return SetType.work;
    }
  }
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
  final SetType type;

  const PerformedSet({
    required this.weight,
    required this.reps,
    required this.timestamp,
    this.type = SetType.work,
  });

  PerformedSet copyWith({
    double? weight,
    int? reps,
    DateTime? timestamp,
    SetType? type,
  }) {
    return PerformedSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'timestamp': timestamp.toIso8601String(),
        'type': type.toShort(),
      };

  factory PerformedSet.fromJson(Map<String, dynamic> json) {
    return PerformedSet(
      weight: (json['weight'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: SetTypeCodec.fromShort((json['type'] as String?) ?? 'work'),
    );
  }
}

/// A planned row shown to the user (editable) before they mark it Done.
/// Note: This is runtime-ish, but you already store it in ExerciseLog, so we keep it Hive-friendly + JSON.
@HiveType(typeId: 5)
class PlannedSet {
  @HiveField(0)
  final SetType type;

  @HiveField(1)
  final double? weight;

  @HiveField(2)
  final int? reps;

  @HiveField(3)
  final bool done;

  const PlannedSet({
    required this.type,
    this.weight,
    this.reps,
    this.done = false,
  });

  PlannedSet copyWith({
    SetType? type,
    double? weight,
    int? reps,
    bool? done,
  }) {
    return PlannedSet(
      type: type ?? this.type,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toShort(),
        'weight': weight,
        'reps': reps,
        'done': done,
      };

  factory PlannedSet.fromJson(Map<String, dynamic> json) {
    return PlannedSet(
      type: SetTypeCodec.fromShort((json['type'] as String?) ?? 'work'),
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      done: (json['done'] as bool?) ?? false,
    );
  }
}

@HiveType(typeId: 3)
class ExerciseLog {
  @HiveField(0)
  final int exerciseId;

  @HiveField(1)
  final List<PerformedSet> sets;

  @HiveField(2)
  final String exerciseName;

  @HiveField(3)
  final String exerciseIcon;

  // Checklist rows prefilled from last workout
  @HiveField(4)
  final List<PlannedSet> plannedSets;

  ExerciseLog({
    required this.exerciseId,
    required this.exerciseIcon,
    required this.exerciseName,
    List<PerformedSet>? sets,
    List<PlannedSet>? plannedSets,
  })  : sets = sets ?? <PerformedSet>[],
        plannedSets = plannedSets ?? <PlannedSet>[];

  ExerciseLog copyWith({
    List<PerformedSet>? sets,
    List<PlannedSet>? plannedSets,
    String? exerciseName,
    String? exerciseIcon,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseIcon: exerciseIcon ?? this.exerciseIcon,
      sets: sets ?? List<PerformedSet>.from(this.sets),
      plannedSets: plannedSets ?? List<PlannedSet>.from(this.plannedSets),
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseIcon': exerciseIcon,
        'sets': sets.map((s) => s.toJson()).toList(),
        'plannedSets': plannedSets.map((p) => p.toJson()).toList(),
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: (json['exerciseId'] as num).toInt(),
      exerciseName: json['exerciseName'] as String? ?? '',
      exerciseIcon: json['exerciseIcon'] as String? ?? '',
      sets: (json['sets'] as List? ?? const [])
          .map((e) => PerformedSet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      plannedSets: (json['plannedSets'] as List? ?? const [])
          .map((e) => PlannedSet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

@HiveType(typeId: 4)
class WorkoutHistoryEntry {
  /// Client-generated stable id (UUID). This is the sync identity — the
  /// backend upserts sessions by it, so replaying a push never duplicates.
  /// `defaultValue` keeps pre-sync Hive rows (which lack this field) readable;
  /// a startup migration backfills a real id for any that are empty.
  @HiveField(7, defaultValue: '')
  final String id;

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

  const WorkoutHistoryEntry({
    required this.id,
    required this.templateIcon,
    required this.templateId,
    required this.templateName,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.logs,
  });

  WorkoutHistoryEntry copyWith({String? id}) => WorkoutHistoryEntry(
        id: id ?? this.id,
        templateIcon: templateIcon,
        templateId: templateId,
        templateName: templateName,
        startedAt: startedAt,
        endedAt: endedAt,
        duration: duration,
        logs: logs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'templateName': templateName,
        'templateIcon': templateIcon,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: json['id'] as String? ?? '',
      templateId: json['templateId'] as String? ?? '',
      templateName: json['templateName'] as String? ?? '',
      templateIcon: json['templateIcon'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
      logs: (json['logs'] as List? ?? const [])
          .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
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
