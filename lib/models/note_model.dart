import 'dart:convert';

class NoteModel {
  final String id;
  String title;
  String summary;
  List<String> keyPoints;
  String sourceFile;
  int pageCount;
  int estimatedReadMinutes;
  int flashcardCount;
  bool isBookmarked;
  DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.sourceFile,
    this.pageCount = 0,
    this.estimatedReadMinutes = 5,
    this.flashcardCount = 0,
    this.isBookmarked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  NoteModel copyWith({
    String? id,
    String? title,
    String? summary,
    List<String>? keyPoints,
    String? sourceFile,
    int? pageCount,
    int? estimatedReadMinutes,
    int? flashcardCount,
    bool? isBookmarked,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      sourceFile: sourceFile ?? this.sourceFile,
      pageCount: pageCount ?? this.pageCount,
      estimatedReadMinutes: estimatedReadMinutes ?? this.estimatedReadMinutes,
      flashcardCount: flashcardCount ?? this.flashcardCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'keyPoints': keyPoints,
        'sourceFile': sourceFile,
        'pageCount': pageCount,
        'estimatedReadMinutes': estimatedReadMinutes,
        'flashcardCount': flashcardCount,
        'isBookmarked': isBookmarked,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'],
        title: json['title'],
        summary: json['summary'],
        keyPoints: List<String>.from(json['keyPoints'] ?? []),
        sourceFile: json['sourceFile'] ?? '',
        pageCount: json['pageCount'] ?? 0,
        estimatedReadMinutes: json['estimatedReadMinutes'] ?? 5,
        flashcardCount: json['flashcardCount'] ?? 0,
        isBookmarked: json['isBookmarked'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  String toJsonString() => jsonEncode(toJson());
  static NoteModel fromJsonString(String s) =>
      NoteModel.fromJson(jsonDecode(s));
}
