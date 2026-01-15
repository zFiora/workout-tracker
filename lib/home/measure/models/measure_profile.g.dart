// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasureProfileAdapter extends TypeAdapter<MeasureProfile> {
  @override
  final int typeId = 31;

  @override
  MeasureProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasureProfile(
      heightCm: fields[0] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, MeasureProfile obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.heightCm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
