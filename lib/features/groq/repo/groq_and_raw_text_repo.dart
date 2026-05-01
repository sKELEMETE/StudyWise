import 'package:studywise/features/groq/datasource/groq_data_source.dart';
import 'package:studywise/features/groq/datasource/study_material_raw_text_grab_data_source.dart';

class AiTextRepo {
  final GrabRawText remoteDataSource;
  final GroqDataSource groqDataSource;

  AiTextRepo({
    required this.remoteDataSource,
    required this.groqDataSource,
  });

  Future<String> summarizeStudyMaterials({
    required String userId,
    required String folderName,
  }) async {
    final texts = await remoteDataSource.getRawTexts(
      userId: userId,
      folderName: folderName,
    );

    if (texts.isEmpty) {
      throw Exception('No study materials found.');
    }

    final combinedText = texts.join('\n\n');
    return groqDataSource.summarizeText(combinedText);
  }
}
