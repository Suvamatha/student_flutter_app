import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';
import '../../providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    // Show name setup dialog if name is not set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      if (userProv.name == null || userProv.name!.isEmpty) {
        _showNameDialog(context);
      }
    });

    final userName = context.watch<UserProvider>().name ?? 'Friend';

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
                                  text: '$userName 👋',
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        image: const DecorationImage(
                          image: NetworkImage('https://media.tenor.com/PZcGBG5jBToAAAAM/mikasa-ackerman-attack-on-titan.gif'),
                          fit: BoxFit.cover,
                        ),
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
                          onTap: () => Navigator.pushNamed(context, '/upload'),
                        ),
                        _QuickActionCard(
                          emoji: '🍅',
                          title: 'Pomodoro',
                          subtitle: 'Focus · 25 min',
                          color: AppTheme.secondary,
                          onTap: () => onTabChange?.call(4),
                        ),
                        _QuickActionCard(
                          emoji: '🧠',
                          title: 'Flashcards',
                          subtitle: 'Review cards',
                          color: AppTheme.warning,
                          onTap: () => onTabChange?.call(2),
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
                      onTap: () => onTabChange?.call(3),
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
                        onAdd: () => onTabChange?.call(3),
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

  void _showNameDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NameSetupDialog(),
    );
  }
}

class _NameSetupDialog extends StatefulWidget {
  const _NameSetupDialog();

  @override
  State<_NameSetupDialog> createState() => _NameSetupDialogState();
}

class _NameSetupDialogState extends State<_NameSetupDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👋', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text('Welcome to StudyAI!', style: AppTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              "What should I call you?",
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter your name...',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await Provider.of<UserProvider>(context, listen: false).setName(name);
    if (mounted) Navigator.pop(context);
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
          const Text('🎉', style: TextStyle(fontSize: 32)),
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

