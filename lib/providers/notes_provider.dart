import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';

class NotesProvider extends ChangeNotifier {
  NoteModel? _currentNote;
  List<NoteModel> _allNotes = [];
  bool _isLoading = false;
  String? _error;

  NoteModel? get currentNote => _currentNote;
  List<NoteModel> get allNotes => _allNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NoteModel> get bookmarkedNotes =>
      _allNotes.where((n) => n.isBookmarked).toList();

  NotesProvider() {
    _allNotes = [MockNotes.biologySample];
    _currentNote = _allNotes.first;
  }

  Future<void> generateFromFile(String fileName, String fileContent) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate AI processing delay
      await Future.delayed(const Duration(seconds: 3));

      // In production, call your AI service here
      final note = MockNotes.biologySample.copyWith(
        sourceFile: fileName,
      );
      _currentNote = note;
      _allNotes.insert(0, note);
    } catch (e) {
      _error = 'Failed to generate summary. Please try again.';
    }

    _isLoading = false;
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
}
