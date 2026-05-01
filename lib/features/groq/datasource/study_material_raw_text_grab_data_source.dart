import 'package:supabase_flutter/supabase_flutter.dart';

class GrabRawText {
  final supabase = Supabase.instance.client;

  Future<List<String>> getRawTexts({
    required String userId,
    required String folderName,
  }) async {
    final path = '$userId/$folderName/%';

    print('\n[GrabRawText] ===== DEBUG START =====');
    print('[GrabRawText] userId: $userId');
    print('[GrabRawText] folderName: $folderName');
    print('[GrabRawText] query path: $path');

    try {
      final response = await supabase
          .from('study_materials')
          .select('file_path, raw_text') // 👈 IMPORTANT
          .ilike('file_path', path);

      final data = response as List;

      print('[GrabRawText] Total matched rows: ${data.length}');
      print('[GrabRawText] --- FILES FOUND ---');

      for (var i = 0; i < data.length; i++) {
        final filePath = data[i]['file_path'];
        final text = data[i]['raw_text'] as String? ?? '';

        print('[File $i]');
        print('  path: $filePath');
        print('  text length: ${text.length}');
      }

      print('[GrabRawText] ===== DEBUG END =====\n');

      final result = data
          .map((e) => e['raw_text'] as String? ?? '')
          .toList();

      return result;
    } catch (e, stackTrace) {
      print('[GrabRawText][ERROR] $e');
      print('[GrabRawText][STACKTRACE] $stackTrace');
      rethrow;
    }
  }
}