import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRemoteDataSource {
  final supabase = Supabase.instance.client;

  Future<List<FileObject>> listUserFolders(String userId) async {
    return await supabase.storage.from('StudyMaterials').list(path: userId);
  }

  Future<List<FileObject>> listFilesInFolder(
    String userId,
    String folderName,
  ) async {
    final path = '$userId/$folderName';
    return await supabase.storage.from('StudyMaterials').list(path: path);
  }
}
