import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/note_model.dart';
import '../models/flashcard_model.dart';

/// Result returned after Groq processes a document.
class GeminiResult {
  final NoteModel note;
  final List<FlashcardModel> flashcards;
  GeminiResult({required this.note, required this.flashcards});
}

class GeminiService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? 'YOUR_GROQ_API_KEY';
  static bool get hasApiKey => _apiKey.length > 10 && _apiKey != 'YOUR_GROQ_API_KEY';

  static const String _model = 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // ── Main entry point ────────────────────────────────────────────
  /// Takes extracted text from a PDF and returns a NoteModel + flashcards.
  static Future<GeminiResult> generateFromText({
    required String text,
    required String fileName,
  }) async {
    if (!hasApiKey) {
      throw Exception(
          'Please add your Groq API key in lib/services/gemini_service.dart.\n'
          'Get a free key at: console.groq.com');
    }

    // Truncate to ~12,000 chars to stay within token limits
    final truncated = text.length > 12000 ? text.substring(0, 12000) : text;

    final prompt = _buildPrompt(truncated, fileName);
    final raw = await _callGroq(prompt);
    return _parseResponse(raw, fileName);
  }

  // ── Prompt engineering ──────────────────────────────────────────
  static String _buildPrompt(String text, String fileName) {
    return '''
You are an expert academic tutor. Analyse the following document and respond ONLY with valid JSON — no markdown, no backticks, no extra text.

Document name: $fileName
Document content:
"""
$text
"""

Return exactly this JSON structure:
{
  "title": "Short descriptive title of the document (max 8 words)",
  "summary": "A clear 3-5 sentence paragraph summarising the main concepts and their significance. Write in plain English suitable for a student.",
  "keyPoints": [
    "First key concept or fact from the document",
    "Second key concept or fact",
    "Third key concept or fact",
    "Fourth key concept or fact",
    "Fifth key concept or fact",
    "Sixth key concept or fact (if applicable)",
    "Seventh key concept or fact (if applicable)"
  ],
  "flashcards": [
    {
      "question": "A specific question testing understanding of a key concept",
      "answer": "A clear, complete answer (2-3 sentences)"
    },
    {
      "question": "Another question",
      "answer": "Another answer"
    }
  ],
  "estimatedReadMinutes": 8
}

Rules:
- keyPoints: minimum 5, maximum 8 items. Each must be a complete sentence.
- flashcards: minimum 6, maximum 12 cards. Questions must test understanding, not just recall.
- estimatedReadMinutes: realistic reading time as an integer.
- All text must be in English.
- Return ONLY the JSON object. No other text whatsoever.
''';
  }

  // ── HTTP call ───────────────────────────────────────────────────
  static Future<String> _callGroq(String prompt) async {
    final url = Uri.parse(_baseUrl);

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': 'You are an expert academic tutor. Always respond with valid JSON only. No markdown, no backticks.',
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.3,
      'max_tokens': 2048,
    });

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      String msg = 'Unknown error';
      try {
        final err = jsonDecode(response.body);
        msg = err['error']?['message'] ?? msg;
      } catch (_) {
        msg = 'Invalid response. Please check your Groq API key.';
      }
      throw Exception('Groq API error ${response.statusCode}: $msg');
    }

    final data = jsonDecode(response.body);

    // Extract text from Groq response
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq returned no response');
    }

    final content = choices[0]['message']?['content'];
    if (content == null || content.toString().isEmpty) {
      throw Exception('Groq returned empty content');
    }

    return content.toString();
  }

  // ── Parse JSON response ─────────────────────────────────────────
  static GeminiResult _parseResponse(String raw, String fileName) {
    // Strip any accidental markdown fences
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```json?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }

    late Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned);
    } catch (e) {
      throw Exception('Failed to parse AI response as JSON: $e\n\nRaw: $raw');
    }

    // Build NoteModel
    final keyPoints = (json['keyPoints'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final flashcardsJson = json['flashcards'] as List<dynamic>? ?? [];
    final flashcards = flashcardsJson.asMap().entries.map((entry) {
      final i = entry.key;
      final fc = entry.value as Map<String, dynamic>;
      return FlashcardModel(
        id: 'fc_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: fc['question']?.toString() ?? '',
        answer: fc['answer']?.toString() ?? '',
        sourceDocument: fileName,
      );
    }).toList();

    final note = NoteModel(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? fileName,
      summary: json['summary']?.toString() ?? '',
      keyPoints: keyPoints,
      sourceFile: fileName,
      estimatedReadMinutes: (json['estimatedReadMinutes'] as num?)?.toInt() ?? 5,
      flashcardCount: flashcards.length,
    );

    return GeminiResult(note: note, flashcards: flashcards);
  }
}