import 'package:flutter/material.dart';

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
