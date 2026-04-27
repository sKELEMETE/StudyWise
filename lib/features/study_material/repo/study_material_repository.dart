import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasource/storage_remote_data_source.dart';
import '../datasource/upload_remote_data_source.dart';

class StudyMaterialRepository {
  final StorageRemoteDataSource storageDataSource;
  final UploadRemoteDataSource uploadDataSource;

  StudyMaterialRepository(this.storageDataSource, this.uploadDataSource);

  Future<List<FileObject>> listUserFolders(String userId) {
    return storageDataSource.listUserFolders(userId);
  }

  Future<List<FileObject>> listFilesInFolder(String userId, String folderName) {
    return storageDataSource.listFilesInFolder(userId, folderName);
  }

  Future<void> saveMaterial({
    required String folderName,
    required String fileName,
    required String fileType,
    required String extractedText,
    required Uint8List fileBytes,
  }) {
    return uploadDataSource.saveMaterial(
      folderName: folderName,
      fileName: fileName,
      fileType: fileType,
      extractedText: extractedText,
      fileBytes: fileBytes,
    );
  }
}