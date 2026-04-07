import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
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
  String? _selectedFilePath;
  String? _fileSize;
  double _uploadProgress = 0.0;
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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
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
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedFileName = file.name;
        _selectedFilePath = file.path;
        final bytes = file.size;
        _fileSize = bytes < 1024 * 1024
            ? '${(bytes / 1024).toStringAsFixed(1)} KB'
            : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        _uploadProgress = 0;
        _isProcessing = false;
      });
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedFileName == null) return;

    setState(() {
      _isProcessing = true;
      _uploadProgress = 0;
    });

    // Simulate upload + AI processing
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _uploadProgress = i / 100);
    }

    if (mounted) {
      // Generate notes via provider
      await context.read<NotesProvider>().generateFromFile(
            _selectedFileName!,
            '', // In production, pass file content
          );

      setState(() {
        _isProcessing = false;
        _recentFiles.insert(0, {
          'name': _selectedFileName!,
          'size': _fileSize ?? '',
          'date': 'Just now',
        });
        _selectedFileName = null;
        _uploadProgress = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Summary & flashcards generated!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
          ),
        );
        Navigator.pushNamed(context, '/notes');
      }
    }
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
                offset: Offset(0, _selectedFileName == null ? _bounceAnimation.value : 0),
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
                      style: BorderStyle.solid,
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
                            : 'Tap to select a PDF',
                        style: AppTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedFileName != null
                            ? 'Tap to select a different file'
                            : 'PDF, DOCX · up to 20 MB',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),

            const SizedBox(height: 16),

            // File chip
            if (_selectedFileName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2)),
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
                          Text(_fileSize ?? '',
                              style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFileName = null;
                        _uploadProgress = 0;
                      }),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 12),
            ],

            // Progress bar
            if (_isProcessing) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _uploadProgress < 0.5
                            ? 'Uploading…'
                            : 'Generating AI summary…',
                        style: AppTheme.labelMedium,
                      ),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: AppTheme.labelMedium
                            .copyWith(color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Generate button
            if (_selectedFileName != null && !_isProcessing)
              CustomButton(
                label: 'Generate Summary + Flashcards',
                icon: Icons.auto_awesome_rounded,
                onPressed: _startProcessing,
              ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // Recent uploads
            Text('Recent Uploads', style: AppTheme.headlineSmall),
            const SizedBox(height: 12),
            ..._recentFiles.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentFileCard(file: e.value),
                ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn()),
          ],
        ),
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
