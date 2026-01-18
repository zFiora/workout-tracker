// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exNote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseNoteAdapter extends TypeAdapter<ExerciseNote> {
  @override
  final int typeId = 77;

  @override
  ExerciseNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseNote(
      exerciseId: fields[0] as int,
      createdAt: fields[1] as DateTime,
      text: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseNote obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
