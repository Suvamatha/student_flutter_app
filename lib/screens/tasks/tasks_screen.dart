import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';
import '../../widgets/custom_button.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Tasks', style: AppTheme.headlineMedium),
        actions: [
          IconButton(
            onPressed: () => _showAddTaskSheet(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusXS),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTheme.labelMedium,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _TaskList(
                tasks: provider.todaysTasks,
                emptyMessage: 'No tasks today!',
                emptyEmoji: '🎉',
                onToggle: provider.toggleComplete,
                onDelete: provider.deleteTask,
              ),
              _TaskList(
                tasks: provider.tasks,
                emptyMessage: 'No tasks yet',
                emptyEmoji: '📋',
                onToggle: provider.toggleComplete,
                onDelete: provider.deleteTask,
              ),
              _TaskList(
                tasks: provider.completedTasks,
                emptyMessage: 'Nothing completed yet',
                emptyEmoji: '⭐',
                onToggle: provider.toggleComplete,
                onDelete: provider.deleteTask,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Task',
          style: AppTheme.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        onAdd: (task) => context.read<TaskProvider>().addTask(task),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final String emptyMessage;
  final String emptyEmoji;
  final Future<void> Function(String) onToggle;
  final Future<void> Function(String) onDelete;

  const _TaskList({
    required this.tasks,
    required this.emptyMessage,
    required this.emptyEmoji,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 48))
                .animate()
                .scale(begin: const Offset(0.7, 0.7), duration: 400.ms,
                    curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(emptyMessage, style: AppTheme.headlineSmall)
                .animate(delay: 100.ms)
                .fadeIn(),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TaskCard(
            task: task,
            animationIndex: i,
            onToggle: () => onToggle(task.id),
            onDelete: () {
              onDelete(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  backgroundColor: AppTheme.textSecondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () {}, // In production: restore task
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Add Task Bottom Sheet ──────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final void Function(TaskModel task) onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _priority = TaskPriority.medium;
  TaskSubject _subject = TaskSubject.other;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;

    final task = TaskModel(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      dueDate: _selectedDate,
      dueTime: _selectedTime,
      priority: _priority,
      subject: _subject,
    );

    widget.onAdd(task);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          Text('New Task', style: AppTheme.headlineMedium),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task title'),
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 10),

          // Description (optional)
          TextField(
            controller: _descController,
            decoration:
                const InputDecoration(hintText: 'Description (optional)'),
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 14),

          // Date & Time row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: _PickerChip(
                    icon: Icons.calendar_today_rounded,
                    label: _selectedDate != null
                        ? DateFormat('MMM d').format(_selectedDate!)
                        : 'Date',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: _PickerChip(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Time',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subject picker
          Text('Subject', style: AppTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskSubject.values.map((s) {
              final isSelected = _subject == s;
              return GestureDetector(
                onTap: () => setState(() => _subject = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    s.label,
                    style: AppTheme.labelMedium.copyWith(
                      color:
                          isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Priority
          Text('Priority', style: AppTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: TaskPriority.values.map((p) {
              final isSelected = _priority == p;
              final colors = [AppTheme.success, AppTheme.warning, AppTheme.error];
              final labels = ['Low', 'Medium', 'High'];
              final color = colors[p.index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: p.index < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? color : AppTheme.textHint.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Center(
                      child: Text(
                        labels[p.index],
                        style: AppTheme.labelMedium.copyWith(
                          color: isSelected ? color : AppTheme.textSecondary,
                          fontWeight: isSelected
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
          const SizedBox(height: 20),

          // Submit
          CustomButton(
            label: 'Add Task',
            icon: Icons.add_task_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PickerChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style:
                  AppTheme.labelMedium.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
