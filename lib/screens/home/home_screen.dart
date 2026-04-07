import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: AppTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              text: 'Hello, ',
                              style: AppTheme.displayLarge,
                              children: [
                                TextSpan(
                                  text: 'Alu 👋',
                                  style: AppTheme.displayLarge.copyWith(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: const Center(
                        child: Text('S',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            ),

            // Hero progress card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Consumer<TaskProvider>(
                  builder: (context, taskProv, _) {
                    final completed = taskProv.completedToday;
                    final total = taskProv.totalToday;
                    final pct = total > 0 ? completed / total : 0.0;
                    return _HeroCard(
                      completed: completed,
                      total: total,
                      percent: pct,
                    );
                  },
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: AppTheme.headlineSmall),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        _QuickActionCard(
                          emoji: '📂',
                          title: 'Upload PDF',
                          subtitle: 'AI summary',
                          color: AppTheme.primary,
                          onTap: () => _navigate(context, 1),
                        ),
                        _QuickActionCard(
                          emoji: '🍅',
                          title: 'Pomodoro',
                          subtitle: 'Focus · 25 min',
                          color: AppTheme.secondary,
                          onTap: () => _navigate(context, 4),
                        ),
                        _QuickActionCard(
                          emoji: '🧠',
                          title: 'Flashcards',
                          subtitle: 'Review cards',
                          color: AppTheme.warning,
                          onTap: () => _navigate(context, 2),
                        ),
                        _QuickActionCard(
                          emoji: '📅',
                          title: 'Timetable',
                          subtitle: 'View schedule',
                          color: AppTheme.success,
                          onTap: () => Navigator.pushNamed(context, '/timetable'),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            ),

            // Today's Tasks
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Tasks", style: AppTheme.headlineSmall),
                    GestureDetector(
                      onTap: () => _navigate(context, 3),
                      child: Text(
                        'See all',
                        style: AppTheme.labelMedium
                            .copyWith(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: Consumer<TaskProvider>(
                builder: (context, taskProv, _) {
                  final tasks = taskProv.todaysTasks.take(4).toList();
                  if (tasks.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyTasks(
                        onAdd: () => _navigate(context, 3),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TaskCard(
                          task: tasks[i],
                          animationIndex: i,
                          onToggle: () =>
                              taskProv.toggleComplete(tasks[i].id),
                          onDelete: () =>
                              taskProv.deleteTask(tasks[i].id),
                        ),
                      ),
                      childCount: tasks.length,
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

  void _navigate(BuildContext context, int index) {
    const routes = ['/', '/upload', '/notes', '/flashcards', '/tasks'];
    if (index < routes.length && index > 0) {
      Navigator.pushNamed(context, routes[index]);
    }
  }
}

class _HeroCard extends StatelessWidget {
  final int completed;
  final int total;
  final double percent;

  const _HeroCard({
    required this.completed,
    required this.total,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.heroCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S PROGRESS',
                  style: AppTheme.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of $total tasks done',
                  style: AppTheme.headlineMedium
                      .copyWith(color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(percent * 100).toInt()}%',
                      style: AppTheme.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 7,
            percent: percent.clamp(0.0, 1.0),
            center: Text(
              '$completed\n/$total',
              textAlign: TextAlign.center,
              style: AppTheme.labelMedium.copyWith(
                color: Colors.white,
                height: 1.3,
              ),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.25),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(
              color: _pressed
                  ? widget.color.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                ),
                child: Center(
                  child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTheme.titleSmall),
                  Text(widget.subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTasks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Text('🎉', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('No tasks today!',
              style: AppTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap to add your first task',
              style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Text('+ Add Task',
                style: AppTheme.labelLarge
                    .copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

