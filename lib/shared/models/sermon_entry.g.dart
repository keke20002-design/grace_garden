// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written Hive TypeAdapter for SermonEntry

part of 'sermon_entry.dart';

class SermonEntryAdapter extends TypeAdapter<SermonEntry> {
  @override
  final int typeId = 2;

  @override
  SermonEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SermonEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
      pastor: fields[3] as String,
      scriptureRef: fields[4] as String,
      summary: fields[5] as String,
      fullContent: fields[6] as String,
      talentsEarned: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SermonEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.pastor)
      ..writeByte(4)
      ..write(obj.scriptureRef)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.fullContent)
      ..writeByte(7)
      ..write(obj.talentsEarned);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SermonEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
