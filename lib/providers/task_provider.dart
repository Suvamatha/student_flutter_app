import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

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
  }



  void _loadTasks() {
    try {
      _tasks = HiveService().getTasks();
    } catch (_) {
      _tasks = [];
    }
  }

  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    notifyListeners();
    await HiveService().saveTask(task);
    await NotificationService().scheduleTask(task);
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
      await HiveService().saveTask(task);
      if (task.isCompleted) {
        await NotificationService().cancelNotification(task.id);
      } else {
        await NotificationService().scheduleTask(task);
      }
    }
  }

  Future<void> toggleComplete(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      _tasks[index] = updatedTask;
      notifyListeners();
      await HiveService().saveTask(updatedTask);
      if (updatedTask.isCompleted) {
        await NotificationService().cancelNotification(taskId);
      } else {
        await NotificationService().scheduleTask(updatedTask);
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await HiveService().deleteTask(taskId);
    await NotificationService().cancelNotification(taskId);
  }

  String generateId() =>
      'task_${DateTime.now().millisecondsSinceEpoch}';
}
