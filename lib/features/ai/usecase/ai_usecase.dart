import 'package:studywise/features/ai/repo/ai_and_raw_text_repo.dart';

class SummarizeStudyMaterialsUseCase {
  final AiTextRepo repository;

  SummarizeStudyMaterialsUseCase(this.repository);

  Future<String> call({
    required String userId,
    required String folderName,
  }) async {
    return await repository.summarizeStudyMaterials(
      userId: userId,
      folderName: folderName,
    );
  }
}