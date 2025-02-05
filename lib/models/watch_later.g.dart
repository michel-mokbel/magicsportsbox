// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_later.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchLaterAdapter extends TypeAdapter<WatchLater> {
  @override
  final int typeId = 0;

  @override
  WatchLater read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchLater(
      fixtureId: fields[0] as String,
      homeTeam: fields[1] as String,
      awayTeam: fields[2] as String,
      date: fields[3] as String,
      venue: fields[4] as String,
      homeTeamLogo: fields[5] as String,
      awayTeamLogo: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WatchLater obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.fixtureId)
      ..writeByte(1)
      ..write(obj.homeTeam)
      ..writeByte(2)
      ..write(obj.awayTeam)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.venue)
      ..writeByte(5)
      ..write(obj.homeTeamLogo)
      ..writeByte(6)
      ..write(obj.awayTeamLogo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchLaterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
