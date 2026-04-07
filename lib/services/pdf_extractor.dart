import 'dart:typed_data';

/// Extracts readable text from PDF bytes or plain text files.
/// For web (Chrome), file_picker returns bytes directly.
/// For mobile, it returns a file path we can read.
class PdfExtractor {
  /// Extract text from raw file bytes.
  /// Handles PDF (basic extraction) and plain text files.
  static String extractText(Uint8List bytes, String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    if (ext == 'txt') {
      return _extractFromTxt(bytes);
    } else if (ext == 'pdf') {
      return _extractFromPdf(bytes);
    } else {
      // Fallback: try treating as UTF-8 text
      try {
        return String.fromCharCodes(bytes);
      } catch (_) {
        return '';
      }
    }
  }

  /// Plain text — just decode UTF-8
  static String _extractFromTxt(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return '';
    }
  }

  /// Basic PDF text extraction.
  /// Finds text between BT (Begin Text) and ET (End Text) markers,
  /// and extracts content from Tj and TJ PDF operators.
  /// This handles most simple/unencrypted PDFs without a native plugin.
  static String _extractFromPdf(Uint8List bytes) {
    try {
      // Try to decode the raw PDF as Latin-1 (PDFs use this internally)
      final raw = String.fromCharCodes(bytes);

      final buffer = StringBuffer();

      // Strategy 1: Extract text between stream...endstream blocks
      final streamRegex = RegExp(r'stream([\s\S]*?)endstream', multiLine: true);
      for (final match in streamRegex.allMatches(raw)) {
        final streamContent = match.group(1) ?? '';
        buffer.write(_extractTextOps(streamContent));
      }

      // Strategy 2: Find parenthesised strings (PDF string objects)
      if (buffer.isEmpty) {
        final parenRegex = RegExp(r'\(([^)]{3,})\)');
        for (final match in parenRegex.allMatches(raw)) {
          final text = match.group(1) ?? '';
          // Filter out binary/control chars
          final cleaned = text.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), ' ').trim();
          if (cleaned.length > 3 && _looksLikeText(cleaned)) {
            buffer.write('$cleaned ');
          }
        }
      }

      final result = buffer.toString().trim();

      // If we got very little text, the PDF might be scanned/encrypted
      if (result.length < 100) {
        return _fallbackMessage();
      }

      // Clean up excess whitespace
      return result
          .replaceAll(RegExp(r'\s{3,}'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } catch (e) {
      return _fallbackMessage();
    }
  }

  /// Extracts text from PDF stream content using Tj/TJ operators
  static String _extractTextOps(String stream) {
    final buffer = StringBuffer();

    // Match (text) Tj  — single string show
    final tjRegex = RegExp(r'\(([^)]*)\)\s*Tj');
    for (final match in tjRegex.allMatches(stream)) {
      final text = _decodePdfString(match.group(1) ?? '');
      if (text.isNotEmpty) buffer.write('$text ');
    }

    // Match [(text)(text)] TJ  — array show
    final tjArrayRegex = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
    for (final match in tjArrayRegex.allMatches(stream)) {
      final inner = match.group(1) ?? '';
      final innerStrings = RegExp(r'\(([^)]*)\)').allMatches(inner);
      for (final s in innerStrings) {
        final text = _decodePdfString(s.group(1) ?? '');
        if (text.isNotEmpty) buffer.write(text);
      }
      buffer.write(' ');
    }

    return buffer.toString();
  }

  /// Decode PDF escape sequences in strings
  static String _decodePdfString(String s) {
    return s
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', '\\')
        .replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '');
  }

  /// Simple heuristic: does this string look like English text?
  static bool _looksLikeText(String s) {
    // Must have some letters
    final letters = s.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    return letters.length > s.length * 0.4;
  }

  static String _fallbackMessage() {
    return '''
This PDF could not be parsed automatically. It may be:
- A scanned document (image-based PDF)  
- Password-protected
- Using a non-standard encoding

Please try copying and pasting the text content directly, or use a plain text (.txt) file.
''';
  }
}
