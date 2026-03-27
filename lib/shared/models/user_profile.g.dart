// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 1;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      uid: fields[0] as String,
      displayName: fields[1] as String,
      totalTalents: fields[2] as int,
      treeStage: fields[3] as int,
      qtStreak: fields[4] as int,
      totalQtCount: fields[5] as int,
      lastQtDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.totalTalents)
      ..writeByte(3)
      ..write(obj.treeStage)
      ..writeByte(4)
      ..write(obj.qtStreak)
      ..writeByte(5)
      ..write(obj.totalQtCount)
      ..writeByte(6)
      ..write(obj.lastQtDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
