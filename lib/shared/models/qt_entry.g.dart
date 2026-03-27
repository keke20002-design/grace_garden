// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qt_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QtEntryAdapter extends TypeAdapter<QtEntry> {
  @override
  final int typeId = 0;

  @override
  QtEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QtEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      scriptureTitle: fields[2] as String,
      scriptureVerse: fields[3] as String,
      meditation: fields[4] as String,
      application: fields[5] as String,
      prayer: fields[6] as String,
      isShared: fields[7] as bool,
      talentsEarned: fields[8] as int,
      cardTemplate: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QtEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.scriptureTitle)
      ..writeByte(3)
      ..write(obj.scriptureVerse)
      ..writeByte(4)
      ..write(obj.meditation)
      ..writeByte(5)
      ..write(obj.application)
      ..writeByte(6)
      ..write(obj.prayer)
      ..writeByte(7)
      ..write(obj.isShared)
      ..writeByte(8)
      ..write(obj.talentsEarned)
      ..writeByte(9)
      ..write(obj.cardTemplate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QtEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
