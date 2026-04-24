import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../service/env_service.dart';

class UploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveMaterial({
    required String folderName,
    required String fileName,
    required String fileType,
    required String extractedText,
    required Uint8List fileBytes,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User authentication required');
    }

    final String edgeFunctionUrl = '${EnvService.supabaseUrl}/functions/v1/upload_material';
    final uri = Uri.parse(edgeFunctionUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    
    request.fields['folderName'] = folderName;
    request.fields['fileName'] = fileName;
    request.fields['fileType'] = fileType;
    request.fields['extractedText'] = extractedText;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }
  }
}