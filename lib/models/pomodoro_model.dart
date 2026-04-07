enum PomodoroMode { focus, shortBreak, longBreak }

extension PomodoroModeExtension on PomodoroMode {
  String get label {
    switch (this) {
      case PomodoroMode.focus: return 'Focus';
      case PomodoroMode.shortBreak: return 'Short Break';
      case PomodoroMode.longBreak: return 'Long Break';
    }
  }

  int get defaultMinutes {
    switch (this) {
      case PomodoroMode.focus: return 25;
      case PomodoroMode.shortBreak: return 5;
      case PomodoroMode.longBreak: return 15;
    }
  }

  int get defaultSeconds => defaultMinutes * 60;
}

class PomodoroSession {
  final String id;
  final PomodoroMode mode;
  final DateTime completedAt;
  final int durationSeconds;

  PomodoroSession({
    required this.id,
    required this.mode,
    required this.completedAt,
    required this.durationSeconds,
  });
}

class PomodoroSettings {
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool soundEnabled;

  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.soundEnabled = true,
  });

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? soundEnabled,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
