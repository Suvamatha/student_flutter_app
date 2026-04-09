import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';
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

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final subjectsJson = prefs.getStringList('timetable_subjects') ?? [];
      _subjects = subjectsJson.map((s) => SubjectModel.fromJson(jsonDecode(s))).toList();

      final scheduleString = prefs.getString('timetable_schedule');
      if (scheduleString != null) {
        final Map<String, dynamic> decoded = jsonDecode(scheduleString);
        _schedule = decoded.map((key, value) {
          final list = (value as List).map((i) => ScheduleBlockModel.fromJson(i as Map<String, dynamic>)).toList();
          return MapEntry(key, list);
        });
      } else {
        _addDummyDataIfEmpty();
      }
    } catch (_) {
        _addDummyDataIfEmpty();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _addDummyDataIfEmpty() {
    if (_subjects.isNotEmpty) return;
    
    final s1 = SubjectModel(id: 'math', name: 'Mathematics', color: AppTheme.subjectMath, hoursPerWeek: 6);
    final s2 = SubjectModel(id: 'bio', name: 'Biology', color: AppTheme.subjectBiology, hoursPerWeek: 4);
    final s3 = SubjectModel(id: 'phys', name: 'Physics', color: AppTheme.subjectPhysics, hoursPerWeek: 5);
    final s4 = SubjectModel(id: 'chem', name: 'Chemistry', color: AppTheme.subjectChemistry, hoursPerWeek: 3);
    
    _subjects = [s1, s2, s3, s4];
    
    _schedule = {
      'Monday': [
        ScheduleBlockModel(id: 'm1', subjectId: 'math', time: '8:00 – 10:00 AM', durationMinutes: 120),
        ScheduleBlockModel(id: 'm2', subjectId: 'bio', time: '11:00 AM – 12:00 PM', durationMinutes: 60),
        ScheduleBlockModel(id: 'm3', subjectId: 'phys', time: '2:00 – 4:00 PM', durationMinutes: 120),
      ],
      'Tuesday': [
        ScheduleBlockModel(id: 't1', subjectId: 'bio', time: '9:00 – 11:00 AM', durationMinutes: 120),
        ScheduleBlockModel(id: 't2', subjectId: 'math', time: '1:00 – 2:00 PM', durationMinutes: 60),
      ],
      'Wednesday': [
        ScheduleBlockModel(id: 'w1', subjectId: 'phys', time: '8:00 – 9:30 AM', durationMinutes: 90),
        ScheduleBlockModel(id: 'w2', subjectId: 'math', time: '11:00 AM – 1:00 PM', durationMinutes: 120),
        ScheduleBlockModel(id: 'w3', subjectId: 'chem', time: '3:00 – 4:30 PM', durationMinutes: 90),
      ],
      'Thursday': [
        ScheduleBlockModel(id: 'th1', subjectId: 'bio', time: '8:00 – 9:00 AM', durationMinutes: 60),
        ScheduleBlockModel(id: 'th2', subjectId: 'phys', time: '10:00 – 11:30 AM', durationMinutes: 90),
        ScheduleBlockModel(id: 'th3', subjectId: 'chem', time: '1:00 – 2:00 PM', durationMinutes: 60),
      ],
      'Friday': [
        ScheduleBlockModel(id: 'f1', subjectId: 'math', time: '9:00 – 10:00 AM', durationMinutes: 60),
        ScheduleBlockModel(id: 'f2', subjectId: 'bio', time: '11:00 AM – 12:00 PM', durationMinutes: 60),
      ],
    };
    _saveData();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final subjectsJson = _subjects.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('timetable_subjects', subjectsJson);

      final scheduleJsonData = _schedule.map((key, value) => MapEntry(key, value.map((b) => b.toJson()).toList()));
      await prefs.setString('timetable_schedule', jsonEncode(scheduleJsonData));
    } catch (_) {}
  }

  void addSubject(SubjectModel subject) {
    _subjects.add(subject);
    notifyListeners();
    _saveData();
  }

  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
    for (var day in days) {
      _schedule[day]?.removeWhere((b) => b.subjectId == id);
    }
    notifyListeners();
    _saveData();
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
