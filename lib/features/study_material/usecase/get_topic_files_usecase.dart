import 'package:supabase_flutter/supabase_flutter.dart';
import '../repo/study_material_repository.dart';

class GetTopicFilesUseCase {
  final StudyMaterialRepository repository;

  GetTopicFilesUseCase(this.repository);

  Future<List<FileObject>> execute(String userId, String folderName) {
    return repository.listFilesInFolder(userId, folderName);
  }
}