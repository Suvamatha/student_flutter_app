import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../providers/timetable_provider.dart';
import '../../models/timetable_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool _showForm = false;
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _addSubject(BuildContext context, TimetableProvider provider) {
    final name = _subjectController.text.trim();
    final hours = int.tryParse(_hoursController.text.trim()) ?? 3;
    if (name.isEmpty) return;

    final colors = [
      AppTheme.primary, AppTheme.secondary, AppTheme.info,
      AppTheme.success, AppTheme.warning,
    ];
    final color = colors[provider.subjects.length % colors.length];

    provider.addSubject(SubjectModel(
      id: provider.generateId(),
      name: name,
      color: color,
      hoursPerWeek: hours,
    ));

    setState(() {
      _subjectController.clear();
      _hoursController.clear();
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _days[DateTime.now().weekday - 1 < 5
        ? DateTime.now().weekday - 1
        : 0];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Timetable', style: AppTheme.headlineMedium),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(
              _showForm ? Icons.close_rounded : Icons.add_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TimetableProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add subject form
                if (_showForm)
                  _AddSubjectForm(
                    subjectController: _subjectController,
                    hoursController: _hoursController,
                    onAdd: () => _addSubject(context, provider),
                  ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.1),

                // Subject chips
                _SubjectLegend(
                  subjects: provider.subjects,
                  onDelete: (id) => provider.deleteSubject(id),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Weekly schedule
                ...(_days.asMap().entries.map((e) {
                  final day = e.value;
                  final blocks = provider.schedule[day] ?? [];
                  final isToday = day == today;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DayCard(
                      day: day,
                      blocks: blocks,
                      isToday: isToday,
                      animIndex: e.key,
                      provider: provider,
                    ),
                  );
                })),

                const SizedBox(height: 12),
                CustomButton(
                  label: 'Add Subject',
                  icon: Icons.edit_calendar_rounded,
                  isOutlined: true,
                  onPressed: () => setState(() => _showForm = !_showForm),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddSubjectForm extends StatelessWidget {
  final TextEditingController subjectController;
  final TextEditingController hoursController;
  final VoidCallback onAdd;

  const _AddSubjectForm({
    required this.subjectController,
    required this.hoursController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Subject', style: AppTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(hintText: 'Subject name'),
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: hoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Hours per week'),
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          CustomButton(label: 'Add Subject', onPressed: onAdd, height: 44),
        ],
      ),
    );
  }
}

class _SubjectLegend extends StatelessWidget {
  final List<SubjectModel> subjects;
  final Function(String id) onDelete;

  const _SubjectLegend({required this.subjects, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((s) {
        return GestureDetector(
          onLongPress: () => onDelete(s.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.name} · ${s.hoursPerWeek}h/wk',
                  style: AppTheme.labelSmall.copyWith(color: s.color),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String day;
  final List<ScheduleBlockModel> blocks;
  final bool isToday;
  final int animIndex;
  final TimetableProvider provider;

  const _DayCard({
    required this.day,
    required this.blocks,
    required this.isToday,
    required this.animIndex,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: isToday
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : null,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  day.toUpperCase(),
                  style: AppTheme.labelMedium.copyWith(
                    letterSpacing: 0.8,
                    color: isToday ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      'Today',
                      style: AppTheme.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${blocks.length} sessions',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (blocks.isEmpty)
            Padding(
               padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text('Free day 🎉', style: AppTheme.bodyMedium),
            )
          else
            ...blocks.asMap().entries.map((e) {
              final block = e.value;
              final subject = provider.getSubjectById(block.subjectId);
              if (subject == null) return const SizedBox.shrink();

              final isLast = e.key == blocks.length - 1;
              return Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          top: BorderSide(
                              color: Color(0xFFEEEEF5), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: subject.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject.name,
                              style: AppTheme.titleSmall),
                          Text(block.time, style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: subject.color.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${block.durationMinutes ~/ 60 > 0 ? "${block.durationMinutes ~/ 60}h" : ""}${block.durationMinutes % 60 > 0 ? " ${block.durationMinutes % 60}m" : ""}',
                        style: AppTheme.labelSmall.copyWith(
                          color: subject.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate(delay: Duration(milliseconds: animIndex * 70)).fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

