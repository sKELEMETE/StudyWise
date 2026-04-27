import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DirectPdfTextExtractor {
  Future<String> extractText(Uint8List pdfBytes) async {
    final start = DateTime.now();

    try {
      print('📄 Opening PDF...');

      final document = PdfDocument(inputBytes: pdfBytes);

      print('📑 Pages: ${document.pages.count}');

      final text =
          PdfTextExtractor(document).extractText();

      document.dispose();

      print('📝 Text length: ${text.length}');

      if (text.trim().isEmpty) {
        print('⚠️ No selectable text');
      }

      print(
          '⏱️ Took: ${DateTime.now().difference(start).inMilliseconds} ms');

      return text.trim();
    } catch (e) {
      print('❌ PDF extraction error: $e');
      return '';
    }
  }
}