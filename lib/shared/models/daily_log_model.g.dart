// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogAdapter extends TypeAdapter<DailyLog> {
  @override
  final int typeId = 0;

  @override
  DailyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLog(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      cigarettes: fields[3] as int?,
      alcohol: fields[4] as double?,
      calories: fields[5] as int?,
      protein: fields[6] as double?,
      carbs: fields[7] as double?,
      fat: fields[8] as double?,
      exerciseMinutes: fields[9] as int?,
      waterGlasses: fields[10] as int?,
      sleepHours: fields[11] as double?,
      steps: fields[12] as int?,
      meals: (fields[13] as Map?)?.cast<String, dynamic>(),
      quests: (fields[14] as Map?)?.cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyLog obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.cigarettes)
      ..writeByte(4)
      ..write(obj.alcohol)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.carbs)
      ..writeByte(8)
      ..write(obj.fat)
      ..writeByte(9)
      ..write(obj.exerciseMinutes)
      ..writeByte(10)
      ..write(obj.waterGlasses)
      ..writeByte(11)
      ..write(obj.sleepHours)
      ..writeByte(12)
      ..write(obj.steps)
      ..writeByte(13)
      ..write(obj.meals)
      ..writeByte(14)
      ..write(obj.quests);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
