import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/water_provider.dart';
import '../../theme/app_theme.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.water,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Hydration Tracker',
                      style: AppTheme.headlineMedium
                          .copyWith(color: Colors.white),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      provider.nextReminderText,
                      style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.75)),
                    ).animate(delay: 50.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // Drop icon + count
                    Center(
                      child: Column(
                        children: [
                          const Text('💧', style: TextStyle(fontSize: 72))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .slideY(
                                begin: 0,
                                end: -0.1,
                                duration: 1800.ms,
                                curve: Curves.easeInOut,
                              ),
                          const SizedBox(height: 12),
                          Text(
                            '${provider.glassesConsumed}',
                            style: AppTheme.displayLarge.copyWith(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'of ${provider.dailyGoal} glasses',
                            style: AppTheme.bodyLarge
                                .copyWith(color: Colors.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 24),

                    // Glasses grid
                    _GlassesGrid(provider: provider)
                        .animate(delay: 200.ms)
                        .fadeIn(),

                    const SizedBox(height: 20),

                    // Log button
                    GestureDetector(
                      onTap: provider.goalReached
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              provider.drinkGlass();
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: provider.goalReached
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Center(
                          child: Text(
                            provider.goalReached ? '🎉 Goal reached!' : '+ Log a Glass',
                            style: AppTheme.titleMedium.copyWith(
                              color: provider.goalReached
                                  ? Colors.white
                                  : AppTheme.waterGradientEnd,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: 250.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Interval card
                    _IntervalCard(provider: provider)
                        .animate(delay: 300.ms)
                        .fadeIn(),

                    const SizedBox(height: 12),

                    // Reminder toggle
                    _ReminderToggle(provider: provider)
                        .animate(delay: 350.ms)
                        .fadeIn(),

                    const SizedBox(height: 20),

                    // Stats
                    _StatsRow(provider: provider)
                        .animate(delay: 400.ms)
                        .fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassesGrid extends StatelessWidget {
  final WaterProvider provider;
  const _GlassesGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: List.generate(provider.dailyGoal, (i) {
        final isFilled = i < provider.glassesConsumed;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (i == provider.glassesConsumed) {
              provider.drinkGlass();
            } else if (i == provider.glassesConsumed - 1) {
              provider.removeGlass();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isFilled
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Center(
              child: Text(
                '🥛',
                style: TextStyle(
                  fontSize: 24,
                  color: isFilled ? Colors.black : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .scale(begin: const Offset(0.7, 0.7), duration: 300.ms,
                curve: Curves.elasticOut);
      }),
    );
  }
}

class _IntervalCard extends StatelessWidget {
  final WaterProvider provider;
  const _IntervalCard({required this.provider});

  static const _intervals = [
    {'label': '30 min', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '2 hours', 'value': 120},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REMINDER INTERVAL',
            style: AppTheme.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.7), letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: _intervals.map((opt) {
              final isActive = provider.intervalMinutes == opt['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setInterval(opt['value'] as int);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: opt != _intervals.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXS),
                      border: Border.all(
                        color: isActive
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt['label'] as String,
                        style: AppTheme.labelMedium.copyWith(
                          color: isActive
                              ? AppTheme.waterGradientEnd
                              : Colors.white.withOpacity(0.85),
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
        ],
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final WaterProvider provider;
  const _ReminderToggle({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders ${provider.remindersEnabled ? "enabled" : "disabled"}',
                  style: AppTheme.titleSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.remindersEnabled
                      ? 'You will be notified every ${provider.intervalMinutes < 60 ? "${provider.intervalMinutes} min" : "${provider.intervalMinutes ~/ 60} hour${provider.intervalMinutes > 60 ? "s" : ""}"}'
                      : 'Turn on to get hydration reminders',
                  style: AppTheme.bodySmall
                      .copyWith(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleReminders();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: provider.remindersEnabled
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: provider.remindersEnabled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: provider.remindersEnabled
                            ? AppTheme.waterGradientEnd
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final WaterProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Consumed',
            value: '${(provider.glassesConsumed * 250)}ml',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Remaining',
            value: '${((provider.dailyGoal - provider.glassesConsumed).clamp(0, 8) * 250)}ml',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Daily goal',
            value: '${provider.dailyGoal * 250}ml',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodySmall
                .copyWith(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
