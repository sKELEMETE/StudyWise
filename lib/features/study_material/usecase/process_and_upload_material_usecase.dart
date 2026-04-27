import 'dart:typed_data';
import '../repo/extraction_repository.dart';
import '../repo/study_material_repository.dart';

class ProcessAndUploadMaterialUseCase {
  final ExtractionRepository extractionRepository;
  final StudyMaterialRepository studyMaterialRepository;

  ProcessAndUploadMaterialUseCase(this.extractionRepository, this.studyMaterialRepository);

  Future<void> execute({
    required String folderName,
    required String fileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final extractedText = await extractionRepository.extractText(fileName, fileType, fileBytes);
    
    await studyMaterialRepository.saveMaterial(
      folderName: folderName,
      fileName: fileName,
      fileType: fileType,
      extractedText: extractedText,
      fileBytes: fileBytes,
    );
  }
}