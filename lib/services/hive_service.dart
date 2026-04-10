import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/timetable_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String taskBoxName = 'tasksBox';
  static const String timetableSubjectBoxName = 'timetableSubjectBox';
  static const String timetableScheduleBoxName = 'timetableScheduleBox';

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(SubjectModelAdapter());
    Hive.registerAdapter(ScheduleBlockModelAdapter());

    await Future.wait([
      Hive.openBox<TaskModel>(taskBoxName),
      Hive.openBox<SubjectModel>(timetableSubjectBoxName),
      Hive.openBox(timetableScheduleBoxName),
    ]);
  }

  Box<TaskModel> get _taskBox => Hive.box<TaskModel>(taskBoxName);

  List<TaskModel> getTasks() => _taskBox.values.toList();

  Future<void> saveTask(TaskModel task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  Box<SubjectModel> get _subjectBox =>
      Hive.box<SubjectModel>(timetableSubjectBoxName);

  Box get _scheduleBox => Hive.box(timetableScheduleBoxName);

  List<SubjectModel> getSubjects() => _subjectBox.values.toList();

  Future<void> saveSubject(SubjectModel subject) async {
    await _subjectBox.put(subject.id, subject);
  }

  Future<void> deleteSubject(String id) async {
    await _subjectBox.delete(id);
  }

  Map<String, List<ScheduleBlockModel>> getScheduleBlocks() {
    final Map<String, List<ScheduleBlockModel>> map = {};
    for (var key in _scheduleBox.keys) {
      final list = _scheduleBox.get(key);
      if (list != null) {
        map[key.toString()] =
            (list as List).cast<ScheduleBlockModel>().toList();
      }
    }
    return map;
  }

  Future<void> saveScheduleBlocksForDay(
      String day, List<ScheduleBlockModel> blocks) async {
    await _scheduleBox.put(day, blocks);
  }
}
