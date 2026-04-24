import 'extraction_service.dart';
import 'upload_service.dart';

class MaterialProcessorService {
  final ExtractionService _extractionService = ExtractionService();
  final UploadService _uploadService = UploadService();

  Future<void> processAndUpload({
    required String folderName,
    required String fileName,
    required String fileType,
    required List<int> fileBytes,
  }) async {
    final response = await _extractionService.processMaterial(
      folderName: folderName,
      fileName: fileName,
      fileBytes: fileBytes as dynamic,
    );

    await _uploadService.saveMaterial(
      folderName: folderName,
      fileName: fileName,
      fileType: fileType,
      extractedText: response?['extractedText'],
      fileBytes: fileBytes as dynamic,
    );
  }
}