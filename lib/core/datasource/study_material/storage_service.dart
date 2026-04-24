import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final supabase = Supabase.instance.client;

  Future<void> createTopicFolder({
    required String userId,
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final path = '$userId/$folderName/$fileName';
    
    await supabase.storage
        .from('StudyMaterials')
        .uploadBinary(path, fileBytes);
  }

  Future<void> uploadFileToExistingFolder({
    required String userId,
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final path = '$userId/$folderName/$fileName';
    
    await supabase.storage
        .from('StudyMaterials')
        .uploadBinary(path, fileBytes);
  }

  Future<List<FileObject>> listUserFolders(String userId) async {
    return await supabase.storage.from('StudyMaterials').list(path: userId);
  }

  Future<List<FileObject>> listFilesInFolder(String userId, String folderName) async {
    final path = '$userId/$folderName';
    return await supabase.storage.from('StudyMaterials').list(path: path);
  }
}