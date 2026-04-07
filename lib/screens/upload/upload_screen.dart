import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  String? _fileSize;
  bool _isProcessing = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final List<Map<String, String>> _recentFiles = [
    {'name': 'Math_Calculus_Notes.pdf', 'size': '1.8 MB', 'date': 'Yesterday'},
    {'name': 'Physics_Thermodynamics.pdf', 'size': '3.1 MB', 'date': '2 days ago'},
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true, // Important: get bytes for web support
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedFileName = file.name;
        _selectedFileBytes = file.bytes;
        final bytes = file.size;
        _fileSize = bytes < 1024 * 1024
            ? '${(bytes / 1024).toStringAsFixed(1)} KB'
            : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedFileName == null || _selectedFileBytes == null) return;

    setState(() => _isProcessing = true);

    final notesProvider = context.read<NotesProvider>();
    final flashcardProvider = context.read<FlashcardProvider>();

    await notesProvider.generateFromBytes(
      fileBytes: _selectedFileBytes!,
      fileName: _selectedFileName!,
    );

    if (!mounted) return;

    if (notesProvider.error != null) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notesProvider.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
        ),
      );
      notesProvider.clearError();
      setState(() => _isProcessing = false);
      return;
    }

    // Load generated flashcards into flashcard provider
    flashcardProvider.loadFlashcards(notesProvider.currentFlashcards);

    setState(() {
      _isProcessing = false;
      _recentFiles.insert(0, {
        'name': _selectedFileName!,
        'size': _fileSize ?? '',
        'date': 'Just now',
      });
      _selectedFileName = null;
      _selectedFileBytes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Summary & ${notesProvider.currentFlashcards.length} flashcards generated!',
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
      ),
    );

    Navigator.pushNamed(context, '/notes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Upload PDF', style: AppTheme.headlineMedium),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload zone
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                    0, _selectedFileName == null && !_isProcessing ? _bounceAnimation.value : 0),
                child: child,
              ),
              child: GestureDetector(
                onTap: _isProcessing ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 44),
                  decoration: BoxDecoration(
                    color: _selectedFileName != null
                        ? AppTheme.primary.withOpacity(0.04)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(
                      color: _selectedFileName != null
                          ? AppTheme.primary.withOpacity(0.4)
                          : AppTheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedFileName != null ? '✅' : '📂',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName != null
                            ? 'File selected!'
                            : 'Tap to select a file',
                        style: AppTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFileName != null
                            ? 'Tap to choose a different file'
                            : 'PDF or TXT · up to 20 MB',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.96, 0.96)),

            const SizedBox(height: 16),

            // File chip
            if (_selectedFileName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Text('📄', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedFileName!,
                              style: AppTheme.titleSmall
                                  .copyWith(color: AppTheme.primary),
                              overflow: TextOverflow.ellipsis),
                          Text(_fileSize ?? '', style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFileName = null;
                        _selectedFileBytes = null;
                      }),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 12),
            ],

            // AI processing status
            if (_isProcessing) ...[
              Consumer<NotesProvider>(
                builder: (context, provider, _) => _ProcessingCard(
                  statusMessage: provider.statusMessage,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Generate button
            if (_selectedFileName != null && !_isProcessing)
              CustomButton(
                label: 'Generate Summary + Flashcards ✨',
                icon: Icons.auto_awesome_rounded,
                onPressed: _startProcessing,
              ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // API key hint
            _ApiKeyHint(),

            const SizedBox(height: 24),

            // Recent uploads
            Text('Recent Uploads', style: AppTheme.headlineSmall),
            const SizedBox(height: 12),
            ..._recentFiles.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentFileCard(file: e.value),
                  ).animate(
                      delay: Duration(milliseconds: e.key * 80)).fadeIn(),
                ),
          ],
        ),
      ),
    );
  }
}

// ── Processing status card ─────────────────────────────────────────
class _ProcessingCard extends StatelessWidget {
  final String statusMessage;
  const _ProcessingCard({required this.statusMessage});

  static const _steps = [
    'Reading document...',
    'Extracting text...',
    'Sending to Gemini AI...',
    'Done!',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  statusMessage.isEmpty ? 'Processing...' : statusMessage,
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._steps.map((step) {
            final isDone = _steps.indexOf(step) <
                _steps.indexOf(statusMessage.isEmpty ? '' : statusMessage);
            final isCurrent = step == statusMessage;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : isCurrent
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isDone
                        ? AppTheme.success
                        : isCurrent
                            ? AppTheme.primary
                            : AppTheme.textHint,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    step,
                    style: AppTheme.bodyMedium.copyWith(
                      color: isDone || isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── API key reminder banner ────────────────────────────────────────
class _ApiKeyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔑', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemini API key required',
                  style: AppTheme.labelMedium.copyWith(color: AppTheme.warning),
                ),
                const SizedBox(height: 3),
                Text(
                  'Add your free key in lib/services/gemini_service.dart\n'
                  'Get one at: aistudio.google.com/app/apikey',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  final Map<String, String> file;
  const _RecentFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            ),
            child: const Center(
                child: Text('📄', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file['name'] ?? '',
                    style: AppTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
                Text('${file['size']} · ${file['date']}',
                    style: AppTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppTheme.textHint),
        ],
      ),
    );
  }
}
