import 'dart:convert';
import 'package:flutter/material.dart' show TimeOfDay;

enum TaskPriority { low, medium, high }

enum TaskSubject { math, biology, physics, chemistry, english, other }

extension TaskSubjectExtension on TaskSubject {
  String get label {
    switch (this) {
      case TaskSubject.math: return 'Math';
      case TaskSubject.biology: return 'Biology';
      case TaskSubject.physics: return 'Physics';
      case TaskSubject.chemistry: return 'Chemistry';
      case TaskSubject.english: return 'English';
      case TaskSubject.other: return 'Other';
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
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        dueTime: json['dueTimeHour'] != null
            ? TimeOfDay(hour: json['dueTimeHour'], minute: json['dueTimeMinute'])
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
