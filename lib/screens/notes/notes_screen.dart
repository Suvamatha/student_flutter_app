import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final note = notesProvider.currentNote;

        if (notesProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Generating AI summary…',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (note == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📄', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No notes yet', style: AppTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text('Upload a PDF to get started',
                      style: AppTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: CustomButton(
                      label: 'Upload PDF',
                      icon: Icons.upload_file_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/upload'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // Sticky AppBar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                title: Text('AI Summary', style: AppTheme.headlineMedium),
                actions: [
                  IconButton(
                    onPressed: () =>
                        notesProvider.toggleBookmark(note.id),
                    icon: Icon(
                      note.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: note.isBookmarked
                          ? AppTheme.primary
                          : AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Source card
                    _SourceCard(note: note).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 20),

                    // Summary
                    Text('Overview', style: AppTheme.headlineSmall)
                        .animate(delay: 50.ms)
                        .fadeIn(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration,
                      child: Text(
                        note.summary,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),
                    const SizedBox(height: 20),

                    // Key points
                    Text('Key Points', style: AppTheme.headlineSmall)
                        .animate(delay: 150.ms)
                        .fadeIn(),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: note.keyPoints
                            .asMap()
                            .entries
                            .map(
                              (e) => _KeyPointTile(
                                text: e.value,
                                index: e.key,
                                isLast: e.key == note.keyPoints.length - 1,
                              ),
                            )
                            .toList(),
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),
                    const SizedBox(height: 24),

                    // Actions
                    CustomButton(
                      label: 'Study Flashcards',
                      icon: Icons.style_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/flashcards'),
                    ).animate(delay: 300.ms).fadeIn(),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Add to Tasks',
                      icon: Icons.add_task_rounded,
                      isOutlined: true,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/tasks'),
                    ).animate(delay: 350.ms).fadeIn(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceCard extends StatelessWidget {
  final dynamic note;
  const _SourceCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.notesCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📄', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note.sourceFile,
                  style: AppTheme.labelMedium
                      .copyWith(color: AppTheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(note.title, style: AppTheme.headlineSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaChip(icon: '⏱', label: '${note.estimatedReadMinutes} min read'),
              const SizedBox(width: 8),
              _MetaChip(icon: '📚', label: '${note.pageCount} pages'),
              const SizedBox(width: 8),
              _MetaChip(icon: '🧠', label: '${note.flashcardCount} cards'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

class _KeyPointTile extends StatelessWidget {
  final String text;
  final int index;
  final bool isLast;

  const _KeyPointTile({
    required this.text,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFEEEEF5), width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(text,
                style: AppTheme.bodyLarge.copyWith(height: 1.5)),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 200 + index * 60)).fadeIn().slideX(begin: 0.05);
  }
}
