//import 'package:studywise/features/ai/datasource/study_material_raw_text_grab_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrabRawText {
  final supabase = Supabase.instance.client;

  Future<List<String>> getRawTexts({
    required String userId,
    required String folderName,
  }) async {
    final response = await supabase
        .from('study_materials')
        .select('raw_text')
        .ilike('file_path', '$userId/$folderName/%');

    final data = response as List;

    return data
        .map((e) => e['raw_text'] as String? ?? '')
        .toList();
  }
}