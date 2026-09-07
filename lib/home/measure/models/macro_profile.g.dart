// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'macro_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MacroProfileAdapter extends TypeAdapter<MacroProfile> {
  @override
  final int typeId = 32;

  @override
  MacroProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MacroProfile(
      isMale: fields[0] as bool,
      ageFallback: fields[1] as int,
      activityFactor: fields[2] as double,
      sexValue: fields[3] as Sex?,
      dateOfBirthUtc: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MacroProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isMale)
      ..writeByte(1)
      ..write(obj.ageFallback)
      ..writeByte(2)
      ..write(obj.activityFactor)
      ..writeByte(3)
      ..write(obj.sexValue)
      ..writeByte(4)
      ..write(obj.dateOfBirthUtc);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
