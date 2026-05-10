import 'dart:typed_data';
import 'package:studywise/features/study_material/datasource/study_content_remote_data_source.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasource/storage_remote_data_source.dart';
import '../datasource/upload_remote_data_source.dart';

class StudyMaterialRepository {
  final StorageRemoteDataSource storageDataSource;
  final UploadRemoteDataSource uploadDataSource;
  final StudyContentRemoteDataSource contentDataSource;

  StudyMaterialRepository(
    this.storageDataSource,
    this.uploadDataSource,
    this.contentDataSource,
  );

  Future<List<FileObject>> listUserFolders(String userId) {
    return storageDataSource.listUserFolders(userId);
  }

  Future<List<FileObject>> listFilesInFolder(String userId, String folderName) {
    return storageDataSource.listFilesInFolder(userId, folderName);
  }

  Future<StudyMaterialRecord> saveMaterial({
    required String userId,
    required String folderName,
    required String fileName,
    required String fileType,
    required String extractedText,
    required Uint8List fileBytes,
  }) async {
    final filePath = await uploadDataSource.uploadMaterialFile(
      folderName: folderName,
      fileName: fileName,
      fileType: fileType,
      fileBytes: fileBytes,
    );

    final material = await contentDataSource.insertStudyMaterial(
      fileType: fileType,
      filePath: filePath,
      rawText: extractedText,
    );

    await contentDataSource.saveProcessedText(
      materialId: material.id,
      processedText: extractedText,
    );

    return material;
  }
}