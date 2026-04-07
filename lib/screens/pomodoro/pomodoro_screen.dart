import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../models/pomodoro_model.dart';
import '../../theme/app_theme.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.pomodoro,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pomodoro Timer',
                              style: AppTheme.headlineMedium
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              provider.sessionLabel,
                              style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _showSettings(context, provider),
                          icon: Icon(
                            Icons.settings_rounded,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 20),

                  // Mode tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Row(
                        children: PomodoroMode.values.map((mode) {
                          final isActive = provider.currentMode == mode;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                provider.setMode(mode);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXS),
                                ),
                                child: Center(
                                  child: Text(
                                    mode.label,
                                    style: AppTheme.labelMedium.copyWith(
                                      color: isActive
                                          ? AppTheme.primary
                                          : Colors.white
                                              .withOpacity(0.8),
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // Timer ring
                  Expanded(
                    child: Center(
                      child: _TimerRing(provider: provider),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Controls
                  _Controls(provider: provider)
                      .animate(delay: 200.ms)
                      .fadeIn()
                      .slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Sessions tracker
                  _SessionsTracker(provider: provider)
                      .animate(delay: 300.ms)
                      .fadeIn(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context, PomodoroProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(provider: provider),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final PomodoroProvider provider;
  const _TimerRing({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring
          CustomPaint(
            size: const Size(240, 240),
            painter: _RingPainter(progress: provider.progress),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.displayTime,
                style: AppTheme.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.currentMode.label,
                style: AppTheme.labelMedium.copyWith(
                    color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Controls extends StatelessWidget {
  final PomodoroProvider provider;
  const _Controls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _ControlButton(
          icon: Icons.replay_rounded,
          size: 52,
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.reset();
          },
          isTransparent: true,
        ),
        const SizedBox(width: 16),

        // Play / Pause (main)
        _ControlButton(
          icon: provider.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 72,
          onTap: () {
            HapticFeedback.heavyImpact();
            provider.toggleTimer();
          },
          isWhite: true,
        ),
        const SizedBox(width: 16),

        // Skip
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 52,
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.skip();
          },
          isTransparent: true,
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool isWhite;
  final bool isTransparent;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.isWhite = false,
    this.isTransparent = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isWhite
                ? Colors.white
                : widget.isTransparent
                    ? Colors.white.withOpacity(0.18)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.size / 2),
            boxShadow: widget.isWhite
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: widget.isWhite ? AppTheme.primary : Colors.white,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );
  }
}

class _SessionsTracker extends StatelessWidget {
  final PomodoroProvider provider;
  const _SessionsTracker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Today's sessions",
                  style: AppTheme.labelMedium
                      .copyWith(color: Colors.white.withOpacity(0.7)),
                ),
                const Spacer(),
                Text(
                  '${provider.todaySessions} completed',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                provider.settings.sessionsBeforeLongBreak,
                (i) {
                  final isDone = i < provider.todaySessions;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          right: i < provider.settings.sessionsBeforeLongBreak - 1
                              ? 8
                              : 0),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXS),
                      ),
                      child: Center(
                        child: Text(
                          '🍅',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDone
                                ? Colors.black
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  final PomodoroProvider provider;
  const _SettingsSheet({required this.provider});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int _focusMin;
  late int _shortMin;
  late int _longMin;

  @override
  void initState() {
    super.initState();
    _focusMin = widget.provider.settings.focusMinutes;
    _shortMin = widget.provider.settings.shortBreakMinutes;
    _longMin = widget.provider.settings.longBreakMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text('Timer Settings', style: AppTheme.headlineMedium),
          const SizedBox(height: 20),
          _SliderRow(
            label: 'Focus duration',
            value: _focusMin,
            min: 5,
            max: 60,
            unit: 'min',
            onChanged: (v) => setState(() => _focusMin = v),
          ),
          _SliderRow(
            label: 'Short break',
            value: _shortMin,
            min: 1,
            max: 15,
            unit: 'min',
            onChanged: (v) => setState(() => _shortMin = v),
          ),
          _SliderRow(
            label: 'Long break',
            value: _longMin,
            min: 5,
            max: 30,
            unit: 'min',
            onChanged: (v) => setState(() => _longMin = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.provider.updateSettings(
                  widget.provider.settings.copyWith(
                    focusMinutes: _focusMin,
                    shortBreakMinutes: _shortMin,
                    longBreakMinutes: _longMin,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.labelMedium),
              Text(
                '$value $unit',
                style:
                    AppTheme.labelMedium.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primary.withOpacity(0.15),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }
}
