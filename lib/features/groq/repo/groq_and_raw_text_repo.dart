import 'package:studywise/features/groq/datasource/groq_data_source.dart';
import 'package:studywise/features/study_material/datasource/study_content_remote_data_source.dart';
import 'package:studywise/features/study_material/model/study_content_models.dart';

class AiTextRepo {
  final StudyContentRemoteDataSource contentDataSource;
  final GroqDataSource groqDataSource;

  AiTextRepo({
    required this.contentDataSource,
    required this.groqDataSource,
  });

  Future<List<SummaryRecord>> fetchSummaries({
    required String folderName,
  }) async {
    final materials =
        await contentDataSource.fetchMaterialsByFolder(
      folderName: folderName,
    );

    return contentDataSource.fetchSummariesByMaterial(
      materialIds:
          materials.map((e) => e.id).toList(),
    );
  }

  Future<SummaryRecord>
      summarizeStudyMaterials({
    required String folderName,
  }) async {
    final materials =
        await contentDataSource.fetchMaterialsByFolder(
      folderName: folderName,
    );

    if (materials.isEmpty) {
      throw Exception(
        'No study materials found.',
      );
    }

    final combinedText = materials
        .map((e) => e.rawText.trim())
        .where((e) => e.isNotEmpty)
        .join('\n\n');

    if (combinedText.isEmpty) {
      throw Exception(
        'No readable text was found in this folder.',
      );
    }

    final summary =
        await groqDataSource.summarizeText(
      combinedText,
    );

    return contentDataSource.saveSummary(
      materialId: materials.first.id,
      summaryText: summary,
    );
  }
}