import 'package:supabase_flutter/supabase_flutter.dart';

class GrabRawText {
  final supabase = Supabase.instance.client;

  Future<List<String>> getRawTexts({
    required String userId,
    required String folderName,
  }) async {
    final folderPath = '$userId/$folderName';
    final files = await supabase.storage
        .from('StudyMaterials')
        .list(path: folderPath);

    if (files.isEmpty) return [];

    final filePaths = files
        .where((file) => file.name.trim().isNotEmpty)
        .map((file) => '$folderPath/${file.name}')
        .toList(growable: false);

    if (filePaths.isEmpty) return [];

    final response = await supabase
        .from('study_materials')
        .select('file_path, raw_text')
        .eq('student_id', userId)
        .inFilter('file_path', filePaths)
        .order('file_path');

    final data = response as List;

    return data
        .map((item) => item['raw_text'] as String? ?? '')
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: false);
  }
}
