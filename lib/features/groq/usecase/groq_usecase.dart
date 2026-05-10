import 'package:studywise/features/groq/repo/groq_and_raw_text_repo.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class GetSummariesUseCase {
  final AiTextRepo repository;

  GetSummariesUseCase(this.repository);

  Future<List<SummaryRecord>> call({
    required String folderName,
  }) {
    return repository.fetchSummaries(
      folderName: folderName,
    );
  }
}

class SummarizeStudyMaterialsUseCase {
  final AiTextRepo repository;

  SummarizeStudyMaterialsUseCase(this.repository);

  Future<SummaryRecord> call({
    required String folderName,
  }) async {
    return repository.summarizeStudyMaterials(
      folderName: folderName,
    );
  }
}