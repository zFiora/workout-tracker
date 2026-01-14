// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementEntryAdapter extends TypeAdapter<MeasurementEntry> {
  @override
  final int typeId = 30;

  @override
  MeasurementEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weightKg: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weightKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
