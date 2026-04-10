import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final int animationIndex;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onDelete,
    this.onTap,
    this.animationIndex = 0,
  });

  Color get _subjectColor {
    switch (task.subject) {
      case TaskSubject.math: return AppTheme.subjectMath;
      case TaskSubject.biology: return AppTheme.subjectBiology;
      case TaskSubject.physics: return AppTheme.subjectPhysics;
      case TaskSubject.chemistry: return AppTheme.subjectChemistry;
      case TaskSubject.english: return AppTheme.subjectEnglish;
      case TaskSubject.other: return AppTheme.textSecondary;
    }
  }

  String get _timeLabel {
    if (task.dueDate == null) return '';
    final now = DateTime.now();
    final isToday = task.dueDate!.year == now.year &&
        task.dueDate!.month == now.month &&
        task.dueDate!.day == now.day;
    final isTomorrow = task.dueDate!.difference(now).inDays == 1;

    String datePart = isToday
        ? 'Today'
        : isTomorrow
            ? 'Tomorrow'
            : DateFormat('MMM d').format(task.dueDate!);

    if (task.dueTime != null) {
      final hour = task.dueTime!.hour;
      final minute = task.dueTime!.minute;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final m = minute.toString().padLeft(2, '0');
      datePart += ' · $h:$m $ampm';
    }
    return datePart;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.error, size: 22),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete?.call();
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppTheme.primary : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppTheme.primary
                          : AppTheme.textHint,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTheme.titleSmall.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted
                            ? AppTheme.textHint
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (_timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(_timeLabel, style: AppTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              // Removed subject badge from card
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
