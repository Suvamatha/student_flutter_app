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
      }
    } catch (_) {
    }
    _isLoading = false;
    notifyListeners();
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
