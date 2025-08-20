// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workoutTemplateModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutTemplateModelAdapter extends TypeAdapter<WorkoutTemplateModel> {
  @override
  final int typeId = 1;

  @override
  WorkoutTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutTemplateModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconPath: fields[2] as String,
      exerciseIds: (fields[3] as List).cast<int>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutTemplateModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconPath)
      ..writeByte(3)
      ..write(obj.exerciseIds)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
