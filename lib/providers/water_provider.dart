import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class WaterProvider extends ChangeNotifier {
  int _glassesConsumed = 5;
  int _dailyGoal = 8;
  bool _remindersEnabled = true;
  int _intervalMinutes = 60;
  DateTime _lastDrink = DateTime.now().subtract(const Duration(minutes: 37));

  WaterProvider() {
    _loadData();
  }

  void _loadData() {
    try {
      final box = Hive.box('settingsBox');
      _glassesConsumed = box.get('water_glasses', defaultValue: 5);
      _dailyGoal = box.get('water_goal', defaultValue: 8);
      _remindersEnabled = box.get('water_reminders', defaultValue: true);
      _intervalMinutes = box.get('water_interval', defaultValue: 60);
      final lastDrinkStr = box.get('water_last_drink');
      if (lastDrinkStr != null) {
        _lastDrink = DateTime.parse(lastDrinkStr);
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
    try {
      final box = Hive.box('settingsBox');
      await box.put('water_glasses', _glassesConsumed);
      await box.put('water_goal', _dailyGoal);
      await box.put('water_reminders', _remindersEnabled);
      await box.put('water_interval', _intervalMinutes);
      await box.put('water_last_drink', _lastDrink.toIso8601String());
    } catch (_) {}
  }

  int get glassesConsumed => _glassesConsumed;
  int get dailyGoal => _dailyGoal;
  bool get remindersEnabled => _remindersEnabled;
  int get intervalMinutes => _intervalMinutes;
  DateTime get lastDrink => _lastDrink;

  double get progress =>
      (_glassesConsumed / _dailyGoal).clamp(0.0, 1.0);

  bool get goalReached => _glassesConsumed >= _dailyGoal;

  Duration get timeUntilNext {
    final nextDrink = _lastDrink.add(Duration(minutes: _intervalMinutes));
    final remaining = nextDrink.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get nextReminderText {
    final dur = timeUntilNext;
    if (dur == Duration.zero) return 'Drink now!';
    final minutes = dur.inMinutes;
    return 'Next reminder in $minutes min';
  }

  void drinkGlass() {
    if (_glassesConsumed < _dailyGoal) {
      _glassesConsumed++;
      _lastDrink = DateTime.now();
      notifyListeners();
      _saveData();
    }
  }

  void removeGlass() {
    if (_glassesConsumed > 0) {
      _glassesConsumed--;
      notifyListeners();
      _saveData();
    }
  }

  void setInterval(int minutes) {
    _intervalMinutes = minutes;
    notifyListeners();
    _saveData();
  }

  void toggleReminders() {
    _remindersEnabled = !_remindersEnabled;
    notifyListeners();
    _saveData();
  }

  void resetDay() {
    _glassesConsumed = 0;
    notifyListeners();
    _saveData();
  }
}
