import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_timezone/flutter_timezone.dart'; // FIX: added
import '../models/task_model.dart';
import '../models/timetable_model.dart';
import 'hive_service.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    // FIX: set local timezone so scheduled times match the device clock
    try {
      final String localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (e) {
      debugPrint('Error setting timezone: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await flutterLocalNotificationsPlugin.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            // Handle notification tap if needed
          });

      // Request permissions for Android 13+
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      // Create Notification Channels (Required for Android 8+)
      await _createChannels();
      
    } catch (e) {
      debugPrint('Notification Init Error: $e');
    }
  }

  Future<void> _createChannels() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    const taskChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for upcoming deadline tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const timetableChannel = AndroidNotificationChannel(
      'timetable_alerts',
      'Timetable Alerts',
      description: 'Notifications for your weekly classes',
      importance: Importance.high,
      playSound: true,
    );

    await androidImplementation?.createNotificationChannel(taskChannel);
    await androidImplementation?.createNotificationChannel(timetableChannel);
  }

  int _generateId(String idString) {
    return idString.hashCode.abs() % 2147483647;
  }

  Future<void> scheduleTask(TaskModel task) async {
    if (kIsWeb) return;
    if (task.dueDate == null || task.dueTime == null || task.isCompleted)
      return;

    final int id = _generateId(task.id);

    final scheduledDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      task.dueTime!.hour,
      task.dueTime!.minute,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: 'Task Reminder: ${task.title}',
        body: 'It is time to ${task.title}!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription:
                'Notifications for upcoming deadline tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'Task Reminder: ${task.title}',
          body: 'It is time to ${task.title}!',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription:
                  'Notifications for upcoming deadline tasks',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        print('Failed to schedule inexact task reminder: $e');
      }
    }
  }

  Future<void> scheduleTimetableBlock(
      ScheduleBlockModel block, SubjectModel subject, String day) async {
    if (kIsWeb) return;

    final int id = _generateId(block.id);

    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final targetDay = days.indexOf(day) + 1;

    final timeStr = block.time.split('–').first.trim();
    int hour = 8;
    int minute = 0;

    try {
      final isPM = timeStr.toLowerCase().contains('pm');
      var timePart = timeStr.replaceAll(RegExp(r'[a-zA-Z\s]'), '');
      if (timePart.contains(':')) {
        final parts = timePart.split(':');
        int h = int.parse(parts[0]);
        if (isPM && h < 12) h += 12;
        if (!isPM && h == 12) h = 0;
        hour = h;
        minute = int.parse(parts[1]);
      }
    } catch (_) {}

    tz.TZDateTime scheduleDate =
        _nextInstanceOfDayAndTime(targetDay, hour, minute);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: 'Class Starting: ${subject.name}',
        body: 'Your ${subject.name} session begins now.',
        scheduledDate: scheduleDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'timetable_alerts',
            'Timetable Alerts',
            channelDescription: 'Notifications for your weekly classes',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'Class Starting: ${subject.name}',
          body: 'Your ${subject.name} session begins now.',
          scheduledDate: scheduleDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'timetable_alerts',
              'Timetable Alerts',
              channelDescription: 'Notifications for your weekly classes',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        print('Failed to schedule inexact timetable reminder: $e');
      }
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(
      int dayOfWeek, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(String idString) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin
        .cancel(id: _generateId(idString));
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> rescheduleAll() async {
    if (kIsWeb) return;
    await cancelAll();

    final tasks = HiveService().getTasks();
    for (var task in tasks) {
      await scheduleTask(task);
    }

    final subjects = HiveService().getSubjects();
    final scheduleMap = HiveService().getScheduleBlocks();

    for (var entry in scheduleMap.entries) {
      final day = entry.key;
      for (var block in entry.value) {
        try {
          final subject =
              subjects.firstWhere((s) => s.id == block.subjectId);
          await scheduleTimetableBlock(block, subject, day);
        } catch (_) {}
      }
    }
  }
}