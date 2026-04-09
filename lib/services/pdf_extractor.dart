import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts readable text from PDF bytes or plain text files.
/// For web (Chrome), file_picker returns bytes directly.
/// For mobile, it returns a file path we can read.
class PdfExtractor {
  /// Extract text from raw file bytes.
  /// Handles PDF (using syncfusion_flutter_pdf) and plain text files.
  /// Runs extraction in a separate isolate to prevent UI freezing.
  static Future<String> extractText(Uint8List bytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();

    // Use Isolate / compute to prevent the UI from freezing
    // especially important for large PDF files
    if (ext == 'txt') {
      return await compute(_extractFromTxt, bytes);
    } else if (ext == 'pdf') {
      return await compute(_extractFromPdf, bytes);
    } else {
      // Fallback: try treating as UTF-8 text
      return await compute(_extractFromTxtFallback, bytes);
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

  static String _extractFromTxtFallback(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return '';
    }
  }

  /// PDF text extraction using syncfusion_flutter_pdf
  static String _extractFromPdf(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      
      final result = text.trim();
      
      // If we got very little text, the PDF might be scanned/encrypted
      if (result.length < 50) {
        return _fallbackMessage();
      }
      
      return result;
    } catch (e) {
      return _fallbackMessage();
    }
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

