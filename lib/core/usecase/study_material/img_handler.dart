import 'dart:typed_data';
import '../../repo/study_material/img_extraction_service.dart';
import '../../usecase/study_material/pdf_handler.dart';
import '../../datasource/study_material/upload_service.dart';

class MaterialProcessorService {
  final ExtractionService _imgExtractionService = ExtractionService();
  final PdfOrchestratorService _pdfOrchestrator = PdfOrchestratorService();
  final UploadService _uploadService = UploadService();

  Future<void> processAndUpload({
    required String folderName,
    required String fileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final startTime = DateTime.now();

    print('\n=== 🚀 PROCESS START ===');
    print('📁 Folder: $folderName');
    print('📄 File: $fileName');
    print('📦 Type: $fileType');
    print('📊 Size: ${fileBytes.length} bytes');

    String extractedText = '';

    try {
      if (fileType.toLowerCase() == 'pdf') {
        print('\n➡️ PDF detected → Using orchestrator');

        extractedText =
            await _pdfOrchestrator.processPdf(fileBytes, fileName);

        print('📄 FINAL extracted length: ${extractedText.length}');
      } else {
        print('\n🖼️ Image detected → Using ML Kit');

        final response = await _imgExtractionService.processMaterial(
          folderName: folderName,
          fileName: fileName,
          fileBytes: fileBytes,
        );

        extractedText = response?['extractedText'] ?? '';

        print('🧠 Extracted length: ${extractedText.length}');
      }

      print('\n⬆️ Uploading...');
      await _uploadService.saveMaterial(
        folderName: folderName,
        fileName: fileName,
        fileType: fileType,
        extractedText: extractedText,
        fileBytes: fileBytes,
      );

      print('✅ Upload successful');
    } catch (e, stack) {
      print('\n❌ PROCESS FAILED');
      print(e);
      print(stack);
    }

    print(
        '⏱️ Total time: ${DateTime.now().difference(startTime).inMilliseconds} ms');
    print('=== 🏁 PROCESS END ===\n');
  }
}