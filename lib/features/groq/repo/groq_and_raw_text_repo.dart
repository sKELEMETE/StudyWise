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
    print('\n[AiTextRepo] ===== START =====');
    print('[AiTextRepo] folderName: $folderName');

    try {
      final texts = await remoteDataSource.getRawTexts(
        userId: userId,
        folderName: folderName,
      );

      print('[AiTextRepo] Number of texts fetched: ${texts.length}');
      print('[AiTextRepo] --- INDIVIDUAL TEXTS ---');

      for (int i = 0; i < texts.length; i++) {
        final text = texts[i];
        print('[Text $i]');
        print('Length: ${text.length}');
        print('Preview: ${text.length > 200 ? text.substring(0, 200) + "..." : text}');
      }

      if (texts.isEmpty) {
        throw Exception('No study materials found.');
      }

      print('[AiTextRepo] --- COMBINING TEXTS ---');

      final combinedText = texts.join('\n\n');

      print('[AiTextRepo] Combined text length: ${combinedText.length}');
      print('[AiTextRepo] Combined preview: '
          '${combinedText.length > 500 ? combinedText.substring(0, 500) + "..." : combinedText}');

      print('[AiTextRepo] --- SENDING TO GROQ ---');

      final summary = await groqDataSource.summarizeText(combinedText);

      print('[AiTextRepo] --- GROQ RESPONSE ---');
      print('[AiTextRepo] Summary length: ${summary.length}');
      print('[AiTextRepo] Summary preview: '
          '${summary.length > 300 ? summary.substring(0, 300) + "..." : summary}');

      print('[AiTextRepo] ===== END =====\n');

      return summary;
    } catch (e, stackTrace) {
      print('[AiTextRepo][ERROR] $e');
      print('[AiTextRepo][STACKTRACE] $stackTrace');
      rethrow;
    }
  }
}