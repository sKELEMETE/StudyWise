import 'dart:typed_data';
import '../repo/extraction_repository.dart';
import '../repo/study_material_repository.dart';

class ProcessAndUploadMaterialUseCase {
  final ExtractionRepository extractionRepository;
  final StudyMaterialRepository studyMaterialRepository;

  ProcessAndUploadMaterialUseCase(
    this.extractionRepository,
    this.studyMaterialRepository,
  );

  Future<void> execute({
    required String folderName,
    required String fileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final cleanFolderName = folderName.trim();
    if (cleanFolderName.isEmpty) {
      throw Exception('Enter a topic name.');
    }

    if (cleanFolderName.contains('/') || cleanFolderName.contains('\\')) {
      throw Exception('Topic name cannot contain slashes.');
    }

    final extractedText = await extractionRepository.extractText(
      fileName,
      fileType,
      fileBytes,
    );

    if (extractedText.trim().isEmpty) {
      throw Exception('No readable text was found in this file.');
    }

    await studyMaterialRepository.saveMaterial(
      folderName: cleanFolderName,
      fileName: fileName,
      fileType: fileType,
      extractedText: extractedText,
      fileBytes: fileBytes,
    );
  }
}
