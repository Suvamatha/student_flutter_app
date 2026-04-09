import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';
import '../services/gemini_service.dart';
import '../services/pdf_extractor.dart';

class NotesProvider extends ChangeNotifier {
  NoteModel? _currentNote;
  List<NoteModel> _allNotes = [];
  List<FlashcardModel> _currentFlashcards = [];
  bool _isLoading = false;
  String? _error;
  String _statusMessage = '';

  NoteModel? get currentNote => _currentNote;
  List<NoteModel> get allNotes => _allNotes;
  List<FlashcardModel> get currentFlashcards => _currentFlashcards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusMessage => _statusMessage;
  List<NoteModel> get bookmarkedNotes =>
      _allNotes.where((n) => n.isBookmarked).toList();

  NotesProvider();

  Future<void> generateFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    int pageCount = 0,
  }) async {
    _isLoading = true;
    _error = null;
    _statusMessage = 'Reading document...';
    notifyListeners();

    try {
      _statusMessage = 'Extracting text...';
      notifyListeners();

      final extractedText = await PdfExtractor.extractText(fileBytes, fileName);

      if (extractedText.trim().length < 50) {
        throw Exception(
            'Could not extract enough text from this file.\n\nTips:\n'
            '- Use a text-based PDF (not scanned)\n'
            '- Or try a .txt file');
      }

      _statusMessage = 'Sending to Gemini AI...';
      notifyListeners();

      final result = await GeminiService.generateFromText(
        text: extractedText,
        fileName: fileName,
      );

      _statusMessage = 'Done!';
      final note = result.note.copyWith(
        pageCount: pageCount,
        flashcardCount: result.flashcards.length,
      );

      _currentNote = note;
      _currentFlashcards = result.flashcards;
      _allNotes.insert(0, note);
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } catch (e) {
      _error = 'Unexpected error: $e';
    }

    _isLoading = false;
    _statusMessage = '';
    notifyListeners();
  }

  Future<void> generateFromFile(String fileName, String fileContent) async {
    _isLoading = true;
    _error = null;
    _statusMessage = 'Processing...';
    notifyListeners();

    try {
      if (fileContent.trim().isNotEmpty) {
        final result = await GeminiService.generateFromText(
          text: fileContent,
          fileName: fileName,
        );
        _currentNote = result.note;
        _currentFlashcards = result.flashcards;
        _allNotes.insert(0, result.note);
      } else {
        _isLoading = false;
        _statusMessage = '';
        _error = 'Content is empty.';
        notifyListeners();
        return;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    _statusMessage = '';
    notifyListeners();
  }

  void toggleBookmark(String noteId) {
    final index = _allNotes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _allNotes[index] = _allNotes[index].copyWith(
        isBookmarked: !_allNotes[index].isBookmarked,
      );
      if (_currentNote?.id == noteId) {
        _currentNote = _allNotes[index];
      }
      notifyListeners();
    }
  }

  void setCurrentNote(NoteModel note) {
    _currentNote = note;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
