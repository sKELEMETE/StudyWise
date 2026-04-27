import 'dart:typed_data';
import '../../repo/study_material/pdf_to_text_service.dart';
import '../../repo/study_material/pdf_to_img_service.dart';
import '../../repo/study_material/img_extraction_service.dart';

class PdfOrchestratorService {
  final DirectPdfTextExtractor _pdfTextExtractor =
      DirectPdfTextExtractor();
  final PdfToImageService _pdfToImageService =
      PdfToImageService();
  final ExtractionService _ocrService = ExtractionService();

  Future<String> processPdf(
      Uint8List pdfBytes, String fileName) async {
    final startTime = DateTime.now();

    print('\n=== 📄 PDF ORCHESTRATOR START ===');
    print('File: $fileName');

    print('➡️ Trying direct text extraction...');
    final directText =
        await _pdfTextExtractor.extractText(pdfBytes);

    if (directText.trim().isNotEmpty) {
      print('✅ TEXT PDF detected');
      print('Length: ${directText.length}');
      return directText;
    }

    print('⚠️ No text → Scanned PDF');
    print('🖼️ Converting to images...');

    final pageImages =
        await _pdfToImageService.renderPagesToImages(pdfBytes);

    print('📑 Pages rendered: ${pageImages.length}');

    if (pageImages.isEmpty) {
      print('❌ No images generated');
      return '';
    }

    print('🧠 Running OCR on all pages...');

    final results = await Future.wait(
      pageImages.asMap().entries.map((entry) async {
        final index = entry.key;
        final bytes = entry.value;

        print('➡️ OCR page ${index + 1}');

        final result = await _ocrService.processMaterial(
          folderName: 'temp_pdf',
          fileName: 'page_$index.jpg',
          fileBytes: bytes,
        );

        final text = result?['extractedText'] ?? '';

        print(
            '📄 Page ${index + 1} text length: ${text.length}');

        return text;
      }),
    );

    final combinedText = results.join('\n');

    print('📄 FINAL OCR TEXT LENGTH: ${combinedText.length}');
    print(
        '⏱️ PDF total time: ${DateTime.now().difference(startTime).inMilliseconds} ms');
    print('=== 🏁 PDF ORCHESTRATOR END ===\n');

    return combinedText.trim();
  }
}