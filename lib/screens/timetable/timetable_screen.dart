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
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
    final today = _days[DateTime.now().weekday - 1 < 7
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
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (provider.subjects.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add a subject first'))
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AddBlockSheet(day: day, provider: provider),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                    ),
                    child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                  ),
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
              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Class?'),
                      content: const Text('Remove this class from your schedule?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.deleteScheduleBlock(day, block.id);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
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
              ));
            }),
        ],
      ),
    ).animate(delay: Duration(milliseconds: animIndex * 70)).fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

class _AddBlockSheet extends StatefulWidget {
  final String day;
  final TimetableProvider provider;
  const _AddBlockSheet({required this.day, required this.provider});

  @override
  State<_AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends State<_AddBlockSheet> {
  String? _selectedSubjectId;
  TimeOfDay? _selectedTime;
  final _durationController = TextEditingController(text: '60');

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedSubjectId == null || _selectedTime == null) return;
    
    final timeString = _selectedTime!.format(context);

    final block = ScheduleBlockModel(
      id: widget.provider.generateId(),
      subjectId: _selectedSubjectId!,
      time: timeString,
      durationMinutes: int.tryParse(_durationController.text) ?? 60,
    );

    widget.provider.addScheduleBlock(widget.day, block);
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text('Add Class to ${widget.day}', style: AppTheme.headlineMedium),
          const SizedBox(height: 16),
          
          Text('Select Subject', style: AppTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.provider.subjects.map((s) {
              final isSelected = _selectedSubjectId == s.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedSubjectId = s.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? s.color : s.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    s.name,
                    style: AppTheme.labelMedium.copyWith(
                      color: isSelected ? Colors.white : s.color,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime?.format(context) ?? 'Start Time',
                          style: AppTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Duration (min)',
                    prefixIcon: const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.15)),
                    ),
                  ),
                  style: AppTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Add Class',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

