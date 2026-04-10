import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SubjectModel {
  final String id;
  final String name;
  final Color color;
  final int hoursPerWeek;

  SubjectModel({
    required this.id,
    required this.name,
    required this.color,
    required this.hoursPerWeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'hoursPerWeek': hoursPerWeek,
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: Color(json['color'] ?? Colors.blue.value),
      hoursPerWeek: json['hoursPerWeek'] ?? 3,
    );
  }
}

class ScheduleBlockModel {
  final String id;
  final String subjectId;
  final String time;
  final int durationMinutes;

  ScheduleBlockModel({
    required this.id,
    required this.subjectId,
    required this.time,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'time': time,
      'durationMinutes': durationMinutes,
    };
  }

  factory ScheduleBlockModel.fromJson(Map<String, dynamic> json) {
    return ScheduleBlockModel(
      id: json['id'] ?? '',
      subjectId: json['subjectId'] ?? '',
      time: json['time'] ?? '9:00 AM',
      durationMinutes: json['durationMinutes'] ?? 60,
    );
  }
}

class SubjectModelAdapter extends TypeAdapter<SubjectModel> {
  @override
  final int typeId = 1;

  @override
  SubjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectModel(
      id: fields[0] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: fields[1] as String? ?? 'Untitled',
      color: Color(fields[2] as int? ?? Colors.blue.value),
      hoursPerWeek: fields[3] as int? ?? 3,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color.value)
      ..writeByte(3)
      ..write(obj.hoursPerWeek);
  }
}

class ScheduleBlockModelAdapter extends TypeAdapter<ScheduleBlockModel> {
  @override
  final int typeId = 2;

  @override
  ScheduleBlockModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleBlockModel(
      id: fields[0] as String? ?? 'blk_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: fields[1] as String? ?? '',
      time: fields[2] as String? ?? '9:00 AM',
      durationMinutes: fields[3] as int? ?? 60,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleBlockModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.durationMinutes);
  }
}