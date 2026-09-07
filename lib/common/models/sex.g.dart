// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sex.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SexAdapter extends TypeAdapter<Sex> {
  @override
  final int typeId = 33;

  @override
  Sex read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Sex.unspecified;
      case 1:
        return Sex.male;
      case 2:
        return Sex.female;
      default:
        return Sex.unspecified;
    }
  }

  @override
  void write(BinaryWriter writer, Sex obj) {
    switch (obj) {
      case Sex.unspecified:
        writer.writeByte(0);
        break;
      case Sex.male:
        writer.writeByte(1);
        break;
      case Sex.female:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SexAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
