// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessionModels.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformedSetAdapter extends TypeAdapter<PerformedSet> {
  @override
  final int typeId = 2;

  @override
  PerformedSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerformedSet(
      weight: fields[0] as double,
      reps: fields[1] as int,
      timestamp: fields[2] as DateTime,
      type: fields[3] as SetType,
    );
  }

  @override
  void write(BinaryWriter writer, PerformedSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.weight)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformedSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlannedSetAdapter extends TypeAdapter<PlannedSet> {
  @override
  final int typeId = 5;

  @override
  PlannedSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlannedSet(
      type: fields[0] as SetType,
      weight: fields[1] as double?,
      reps: fields[2] as int?,
      done: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlannedSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.done);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseLogAdapter extends TypeAdapter<ExerciseLog> {
  @override
  final int typeId = 3;

  @override
  ExerciseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseLog(
      exerciseId: fields[0] as int,
      exerciseIcon: fields[3] as String,
      exerciseName: fields[2] as String,
      sets: (fields[1] as List?)?.cast<PerformedSet>(),
      plannedSets: (fields[4] as List?)?.cast<PlannedSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.sets)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.exerciseIcon)
      ..writeByte(4)
      ..write(obj.plannedSets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutHistoryEntryAdapter extends TypeAdapter<WorkoutHistoryEntry> {
  @override
  final int typeId = 4;

  @override
  WorkoutHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutHistoryEntry(
      templateIcon: fields[2] as String,
      templateId: fields[0] as String,
      templateName: fields[1] as String,
      startedAt: fields[3] as DateTime,
      endedAt: fields[4] as DateTime,
      duration: fields[5] as Duration,
      logs: (fields[6] as List).cast<ExerciseLog>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutHistoryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.templateId)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.templateIcon)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.endedAt)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.logs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SetTypeAdapter extends TypeAdapter<SetType> {
  @override
  final int typeId = 1;

  @override
  SetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SetType.work;
      case 1:
        return SetType.warmup;
      case 2:
        return SetType.dropset;
      default:
        return SetType.work;
    }
  }

  @override
  void write(BinaryWriter writer, SetType obj) {
    switch (obj) {
      case SetType.work:
        writer.writeByte(0);
        break;
      case SetType.warmup:
        writer.writeByte(1);
        break;
      case SetType.dropset:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
