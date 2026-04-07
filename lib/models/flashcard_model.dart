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

// Mock data for testing
class MockFlashcards {
  static List<FlashcardModel> get biologySample => [
        FlashcardModel(
          id: '1',
          question: 'What is the powerhouse of the cell?',
          answer:
              'The Mitochondria. It produces ATP through cellular respiration via the Krebs cycle and the Electron Transport Chain.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
        FlashcardModel(
          id: '2',
          question: 'What is the function of the cell membrane?',
          answer:
              'The cell membrane is a semi-permeable phospholipid bilayer that controls what enters and exits the cell, maintaining homeostasis.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
        FlashcardModel(
          id: '3',
          question: 'What do ribosomes do?',
          answer:
              'Ribosomes translate mRNA into proteins (translation). They can be found free in the cytoplasm or attached to the rough endoplasmic reticulum.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
        FlashcardModel(
          id: '4',
          question:
              'What is the key difference between prokaryotes and eukaryotes?',
          answer:
              'Eukaryotes have a true nucleus and membrane-bound organelles. Prokaryotes (like bacteria) have no nucleus — their DNA floats freely in the cytoplasm.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
        FlashcardModel(
          id: '5',
          question: 'What role does the nucleus play in a cell?',
          answer:
              'The nucleus is the control centre of the cell. It contains DNA and directs gene expression by producing mRNA for protein synthesis.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
        FlashcardModel(
          id: '6',
          question:
              'What is the difference between smooth and rough endoplasmic reticulum?',
          answer:
              'Rough ER has ribosomes attached and synthesises proteins. Smooth ER lacks ribosomes and is involved in lipid synthesis and detoxification.',
          sourceDocument: 'Biology_Chapter5.pdf',
        ),
      ];
}
