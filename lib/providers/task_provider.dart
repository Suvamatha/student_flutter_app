import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<TaskModel> get todaysTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList()
      ..sort((a, b) {
        final aTime = a.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
        final bTime = b.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
        return aTime.hour * 60 + aTime.minute -
            (bTime.hour * 60 + bTime.minute);
      });
  }

  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  int get completedToday {
    return todaysTasks.where((t) => t.isCompleted).length;
  }

  int get totalToday => todaysTasks.length;

  TaskProvider() {
    _loadTasks();
    _addSampleTasks();
  }

  void _addSampleTasks() {
    if (_tasks.isNotEmpty) return;
    final now = DateTime.now();
    _tasks = [
      TaskModel(
        id: 'sample_1',
        title: 'Read Chapter 5 – Biology',
        subject: TaskSubject.biology,
        dueDate: now,
        dueTime: const TimeOfDay(hour: 9, minute: 0),
        isCompleted: true,
        priority: TaskPriority.high,
      ),
      TaskModel(
        id: 'sample_2',
        title: 'Submit Math Assignment',
        subject: TaskSubject.math,
        dueDate: now,
        dueTime: const TimeOfDay(hour: 14, minute: 0),
        priority: TaskPriority.high,
      ),
      TaskModel(
        id: 'sample_3',
        title: 'Review Physics notes',
        subject: TaskSubject.physics,
        dueDate: now,
        dueTime: const TimeOfDay(hour: 17, minute: 30),
        priority: TaskPriority.medium,
      ),
      TaskModel(
        id: 'sample_4',
        title: 'Prepare presentation slides',
        subject: TaskSubject.english,
        dueDate: now.add(const Duration(days: 1)),
        dueTime: const TimeOfDay(hour: 10, minute: 0),
        priority: TaskPriority.medium,
      ),
      TaskModel(
        id: 'sample_5',
        title: 'Study for Chemistry quiz',
        subject: TaskSubject.chemistry,
        dueDate: now.add(const Duration(days: 2)),
        dueTime: const TimeOfDay(hour: 9, minute: 0),
        priority: TaskPriority.high,
      ),
    ];
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('tasks') ?? [];
      _tasks = jsonList
          .map((s) => TaskModel.fromJson(jsonDecode(s)))
          .toList();
    } catch (_) {
      _tasks = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tasks.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('tasks', jsonList);
    } catch (_) {}
  }

  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _saveTasks();
  }

  String generateId() =>
      'task_${DateTime.now().millisecondsSinceEpoch}';
}
