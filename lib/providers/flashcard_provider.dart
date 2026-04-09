import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardModel> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  Map<String, FlashcardDifficulty> _ratings = {};

  List<FlashcardModel> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  FlashcardModel? get currentCard =>
      _flashcards.isEmpty ? null : _flashcards[_currentIndex];
  int get total => _flashcards.length;
  bool get hasNext => _currentIndex < _flashcards.length - 1;
  bool get hasPrev => _currentIndex > 0;
  double get progress =>
      _flashcards.isEmpty ? 0 : (_currentIndex + 1) / _flashcards.length;

  FlashcardProvider();

  /// Load a fresh set of flashcards (called after Gemini generates them)
  void loadFlashcards(List<FlashcardModel> cards) {
    _flashcards = cards;
    _currentIndex = 0;
    _isFlipped = false;
    _ratings = {};
    notifyListeners();
  }

  void flip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void next() {
    if (hasNext) {
      _currentIndex++;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void previous() {
    if (hasPrev) {
      _currentIndex--;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void rate(FlashcardDifficulty difficulty) {
    if (currentCard != null) {
      _ratings[currentCard!.id] = difficulty;
      final idx = _flashcards.indexWhere((c) => c.id == currentCard!.id);
      if (idx != -1) {
        _flashcards[idx] = _flashcards[idx].copyWith(
          difficulty: difficulty,
          reviewCount: _flashcards[idx].reviewCount + 1,
          lastReviewed: DateTime.now(),
        );
      }
      if (hasNext) {
        next();
      } else {
        notifyListeners();
      }
    }
  }

  void reset() {
    _currentIndex = 0;
    _isFlipped = false;
    _ratings = {};
    notifyListeners();
  }

  int get easyCount =>
      _ratings.values.where((d) => d == FlashcardDifficulty.easy).length;
  int get mediumCount =>
      _ratings.values.where((d) => d == FlashcardDifficulty.medium).length;
  int get hardCount =>
      _ratings.values.where((d) => d == FlashcardDifficulty.hard).length;

  bool get isComplete =>
      _flashcards.isNotEmpty &&
      _currentIndex == _flashcards.length - 1 &&
      _ratings.containsKey(currentCard?.id);
}
