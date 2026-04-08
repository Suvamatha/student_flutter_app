import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/flashcard_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flashcard_widget.dart';
import '../../widgets/custom_button.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        if (provider.flashcards.isEmpty) {
          return _EmptyState();
        }

        if (provider.isComplete) {
          return _CompletionScreen(provider: provider);
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            title: Text('Flashcards', style: AppTheme.headlineMedium),
            actions: [
              TextButton(
                onPressed: provider.reset,
                child: Text('Restart',
                    style: AppTheme.labelMedium
                        .copyWith(color: AppTheme.primary)),
              ),
            ],
          ),
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < -300) {
                HapticFeedback.lightImpact();
                provider.next();
              } else if (details.primaryVelocity! > 300) {
                HapticFeedback.lightImpact();
                provider.previous();
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                children: [
                  // Progress dots
                  _ProgressDots(provider: provider)
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),

                  // Counter
                  Text(
                    '${provider.currentIndex + 1} / ${provider.total}',
                    style: AppTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),

                  // Flashcard
                  if (provider.currentCard != null)
                    FlashcardWidget(
                      card: provider.currentCard!,
                      isFlipped: provider.isFlipped,
                      onFlip: provider.flip,
                    ).animate(key: ValueKey(provider.currentIndex))
                        .fadeIn(duration: 250.ms)
                        .scale(begin: const Offset(0.96, 0.96)),
                  const SizedBox(height: 16),

                  // Swipe hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swipe_rounded,
                          size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Text('Swipe left/right to navigate',
                          style: AppTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prev / Next
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: '← Previous',
                          isOutlined: true,
                          height: 46,
                          onPressed: provider.hasPrev ? provider.previous : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          label: 'Next →',
                          height: 46,
                          onPressed: provider.hasNext ? provider.next : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rating row
                  AnimatedOpacity(
                    opacity: provider.isFlipped ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How was that?', style: AppTheme.headlineSmall),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RatingButton(
                                label: '😓 Hard',
                                color: AppTheme.error,
                                onTap: provider.isFlipped
                                    ? () => provider.rate(
                                        FlashcardDifficulty.hard)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RatingButton(
                                label: '😐 Ok',
                                color: AppTheme.warning,
                                onTap: provider.isFlipped
                                    ? () => provider.rate(
                                        FlashcardDifficulty.medium)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RatingButton(
                                label: '😊 Easy',
                                color: AppTheme.success,
                                onTap: provider.isFlipped
                                    ? () => provider.rate(
                                        FlashcardDifficulty.easy)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final FlashcardProvider provider;
  const _ProgressDots({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(provider.total, (i) {
        final isDone = i < provider.currentIndex;
        final isCurrent = i == provider.currentIndex;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < provider.total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isDone || isCurrent
                  ? AppTheme.primary.withOpacity(isDone ? 1.0 : 0.5)
                  : AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No flashcards yet', style: AppTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Upload a PDF to generate flashcards',
                style: AppTheme.bodyMedium),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: CustomButton(
                label: 'Upload PDF',
                icon: Icons.upload_file_rounded,
                onPressed: () => Navigator.pushNamed(context, '/upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final FlashcardProvider provider;
  const _CompletionScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56))
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms,
                      curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text('Session Complete!', style: AppTheme.displayMedium)
                  .animate(delay: 200.ms)
                  .fadeIn(),
              const SizedBox(height: 8),
              Text(
                '${provider.total} cards reviewed',
                style: AppTheme.bodyLarge
                    .copyWith(color: AppTheme.textSecondary),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 32),
              _StatRow(
                easyCount: provider.easyCount,
                mediumCount: provider.mediumCount,
                hardCount: provider.hardCount,
              ).animate(delay: 400.ms).fadeIn(),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Study Again',
                icon: Icons.refresh_rounded,
                onPressed: provider.reset,
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int easyCount;
  final int mediumCount;
  final int hardCount;

  const _StatRow({
    required this.easyCount,
    required this.mediumCount,
    required this.hardCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(label: 'Easy', count: easyCount, color: AppTheme.success),
        const SizedBox(width: 12),
        _StatChip(label: 'Ok', count: mediumCount, color: AppTheme.warning),
        const SizedBox(width: 12),
        _StatChip(label: 'Hard', count: hardCount, color: AppTheme.error),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTheme.displayMedium.copyWith(color: color),
          ),
          Text(label,
              style: AppTheme.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
