import 'package:supabase_flutter/supabase_flutter.dart';
import '../repo/study_material_repository.dart';

class GetTopicsUseCase {
  final StudyMaterialRepository repository;

  GetTopicsUseCase(this.repository);

  Future<List<FileObject>> execute(String userId) {
    return repository.listUserFolders(userId);
  }
}