import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pomodoro_model.dart';

class PomodoroProvider extends ChangeNotifier {
  PomodoroSettings _settings = const PomodoroSettings();
  PomodoroMode _currentMode = PomodoroMode.focus;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  int _todaySessions = 0;
  List<PomodoroSession> _sessions = [];
  Timer? _timer;

  PomodoroSettings get settings => _settings;
  PomodoroMode get currentMode => _currentMode;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;
  int get todaySessions => _todaySessions;
  List<PomodoroSession> get sessions => _sessions;

  double get progress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 1.0;

  String get displayTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get sessionLabel {
    switch (_currentMode) {
      case PomodoroMode.focus:
        return 'Session #${_todaySessions + 1} · Focus time';
      case PomodoroMode.shortBreak:
        return 'Short break · Stretch & breathe';
      case PomodoroMode.longBreak:
        return 'Long break · You earned it!';
    }
  }

  void setMode(PomodoroMode mode) {
    _timer?.cancel();
    _isRunning = false;
    _currentMode = mode;
    switch (mode) {
      case PomodoroMode.focus:
        _totalSeconds = _settings.focusMinutes * 60;
        break;
      case PomodoroMode.shortBreak:
        _totalSeconds = _settings.shortBreakMinutes * 60;
        break;
      case PomodoroMode.longBreak:
        _totalSeconds = _settings.longBreakMinutes * 60;
        break;
    }
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _isRunning = false;
    _onTimerComplete();
  }

  void _onTimerComplete() {
    if (_currentMode == PomodoroMode.focus) {
      _completedSessions++;
      _todaySessions++;
      _sessions.add(PomodoroSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        mode: _currentMode,
        completedAt: DateTime.now(),
        durationSeconds: _totalSeconds,
      ));
      // Auto switch to break
      if (_completedSessions % _settings.sessionsBeforeLongBreak == 0) {
        setMode(PomodoroMode.longBreak);
      } else {
        setMode(PomodoroMode.shortBreak);
      }
    } else {
      setMode(PomodoroMode.focus);
    }
  }

  void updateSettings(PomodoroSettings newSettings) {
    _settings = newSettings;
    reset();
    setMode(_currentMode);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
