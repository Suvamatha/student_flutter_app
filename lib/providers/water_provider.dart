import 'package:flutter/material.dart';

class WaterProvider extends ChangeNotifier {
  int _glassesConsumed = 5;
  int _dailyGoal = 8;
  bool _remindersEnabled = true;
  int _intervalMinutes = 60;
  DateTime _lastDrink = DateTime.now().subtract(const Duration(minutes: 37));

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
    }
  }

  void removeGlass() {
    if (_glassesConsumed > 0) {
      _glassesConsumed--;
      notifyListeners();
    }
  }

  void setInterval(int minutes) {
    _intervalMinutes = minutes;
    notifyListeners();
  }

  void toggleReminders() {
    _remindersEnabled = !_remindersEnabled;
    notifyListeners();
  }

  void resetDay() {
    _glassesConsumed = 0;
    notifyListeners();
  }
}
