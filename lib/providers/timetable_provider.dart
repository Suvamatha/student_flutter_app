import 'package:flutter/material.dart';
import '../models/timetable_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TimetableProvider extends ChangeNotifier {
  List<SubjectModel> _subjects = [];
  Map<String, List<ScheduleBlockModel>> _schedule = {};
  bool _isLoading = false;

  List<SubjectModel> get subjects => _subjects;
  Map<String, List<ScheduleBlockModel>> get schedule => _schedule;
  bool get isLoading => _isLoading;

  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  TimetableProvider() {
    _loadData();
  }

  void _loadData() {
    try {
      _subjects = HiveService().getSubjects();
      _schedule = HiveService().getScheduleBlocks();
    } catch (_) {
    }
  }
  Future<void> addSubject(SubjectModel subject) async {
    _subjects.add(subject);
    notifyListeners();
    await HiveService().saveSubject(subject);
  }

  Future<void> deleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    await HiveService().deleteSubject(id);
    for (var day in days) {
      final blocks = _schedule[day] ?? [];
      final removedBlocks = blocks.where((b) => b.subjectId == id).toList();
      blocks.removeWhere((b) => b.subjectId == id);
      await HiveService().saveScheduleBlocksForDay(day, blocks);
      for (var block in removedBlocks) {
        await NotificationService().cancelNotification(block.id);
      }
    }
    notifyListeners();
  }

  Future<void> addScheduleBlock(String day, ScheduleBlockModel block) async {
    if (!_schedule.containsKey(day)) {
      _schedule[day] = [];
    }
    _schedule[day]!.add(block);
    
    notifyListeners();
    await HiveService().saveScheduleBlocksForDay(day, _schedule[day]!);
    
    final subject = getSubjectById(block.subjectId);
    if (subject != null) {
      await NotificationService().scheduleTimetableBlock(block, subject, day);
    }
  }

  Future<void> updateScheduleBlock(String day, ScheduleBlockModel block) async {
    if (!_schedule.containsKey(day)) return;
    final index = _schedule[day]!.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      _schedule[day]![index] = block;
      notifyListeners();
      await HiveService().saveScheduleBlocksForDay(day, _schedule[day]!);
      
      final subject = getSubjectById(block.subjectId);
      if (subject != null) {
        await NotificationService().scheduleTimetableBlock(block, subject, day);
      }
    }
  }

  Future<void> deleteScheduleBlock(String day, String blockId) async {
    if (!_schedule.containsKey(day)) return;
    _schedule[day]!.removeWhere((b) => b.id == blockId);
    notifyListeners();
    await HiveService().saveScheduleBlocksForDay(day, _schedule[day]!);
    await NotificationService().cancelNotification(blockId);
  }

  // Helper method for the UI
  SubjectModel? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  String generateId() => 'tt_${DateTime.now().millisecondsSinceEpoch}';
}
