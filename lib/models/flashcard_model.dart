import 'dart:convert';

enum FlashcardDifficulty { easy, medium, hard }

class FlashcardModel {
  final String id;
  String question;
  String answer;
  String? hint;
  FlashcardDifficulty difficulty;
  int reviewCount;
  DateTime? lastReviewed;
  String sourceDocument;

  FlashcardModel({
    required this.id,
    required this.question,
    required this.answer,
    this.hint,
    this.difficulty = FlashcardDifficulty.medium,
    this.reviewCount = 0,
    this.lastReviewed,
    this.sourceDocument = '',
  });

  FlashcardModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? hint,
    FlashcardDifficulty? difficulty,
    int? reviewCount,
    DateTime? lastReviewed,
    String? sourceDocument,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      hint: hint ?? this.hint,
      difficulty: difficulty ?? this.difficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      sourceDocument: sourceDocument ?? this.sourceDocument,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'hint': hint,
        'difficulty': difficulty.index,
        'reviewCount': reviewCount,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'sourceDocument': sourceDocument,
      };

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
        id: json['id'],
        question: json['question'],
        answer: json['answer'],
        hint: json['hint'],
        difficulty: FlashcardDifficulty.values[json['difficulty'] ?? 1],
        reviewCount: json['reviewCount'] ?? 0,
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'])
            : null,
        sourceDocument: json['sourceDocument'] ?? '',
      );

  String toJsonString() => jsonEncode(toJson());
  static FlashcardModel fromJsonString(String s) =>
      FlashcardModel.fromJson(jsonDecode(s));
}
