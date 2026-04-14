import 'dart:convert';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive/hive.dart';

enum TaskPriority { low, medium, high }

enum TaskSubject { math, biology, physics, chemistry, english, other }

extension TaskSubjectExtension on TaskSubject {
  String get label {
    switch (this) {
      case TaskSubject.math:      return 'Math';
      case TaskSubject.biology:   return 'Biology';
      case TaskSubject.physics:   return 'Physics';
      case TaskSubject.chemistry: return 'Chemistry';
      case TaskSubject.english:   return 'English';
      case TaskSubject.other:     return 'Other';
    }
  }
}

class TaskModel {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isCompleted;
  TaskPriority priority;
  TaskSubject subject;
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.subject = TaskSubject.other,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    TaskPriority? priority,
    TaskSubject? subject,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      subject: subject ?? this.subject,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeHour': dueTime?.hour,
        'dueTimeMinute': dueTime?.minute,
        'isCompleted': isCompleted,
        'priority': priority.index,
        'subject': subject.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        dueTime: json['dueTimeHour'] != null
            ? TimeOfDay(
                hour: json['dueTimeHour'], minute: json['dueTimeMinute'])
            : null,
        isCompleted: json['isCompleted'] ?? false,
        priority: TaskPriority.values[json['priority'] ?? 1],
        subject: TaskSubject.values[json['subject'] ?? 5],
        createdAt: DateTime.parse(json['createdAt']),
      );

  String toJsonString() => jsonEncode(toJson());

  static TaskModel fromJsonString(String jsonString) =>
      TaskModel.fromJson(jsonDecode(jsonString));
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    TimeOfDay? parsedTime;
    if (fields[4] != null) {
      if (fields[4] is List && (fields[4] as List).length >= 2) {
        final list = fields[4] as List;
        parsedTime = TimeOfDay(hour: list[0] as int, minute: list[1] as int);
      } else if (fields[4] is String) {
        final parts = (fields[4] as String).split(':');
        if (parts.length == 2) {
          parsedTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    }

    return TaskModel(
      id: fields[0] as String? ??
          'task_${DateTime.now().millisecondsSinceEpoch}',
      title: fields[1] as String? ?? 'Untitled',
      description: fields[2] as String?,
      dueDate: fields[3] as DateTime?,
      dueTime: parsedTime,
      isCompleted: fields[5] as bool? ?? false,
      priority: TaskPriority.values[fields[6] as int? ?? 1],
      subject: TaskSubject.values[fields[7] as int? ?? 5],
      // FIX: was "fields[8] as DateTime?" — non-nullable field needs fallback
      createdAt: fields[8] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.dueTime != null
          ? '${obj.dueTime!.hour}:${obj.dueTime!.minute}'
          : null)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.priority.index)
      ..writeByte(7)
      ..write(obj.subject.index)
      ..writeByte(8)
      ..write(obj.createdAt);
  }
}