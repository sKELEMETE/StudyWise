import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../service/env_service.dart';

class UploadRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadMaterialFile({
    required String folderName,
    required String fileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User authentication required');
    if (fileBytes.isEmpty) throw Exception('Missing file');

    final String edgeFunctionUrl =
        '${EnvService.supabaseUrl}/functions/v1/upload_material';
    final uri = Uri.parse(edgeFunctionUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    request.fields['folderName'] = folderName;
    request.fields['fileName'] = fileName;
    request.fields['fileType'] = fileType;

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(_errorMessageFromResponse(response.body));
    }

    final data = jsonDecode(response.body);
    final filePath = data['filePath']?.toString() ?? '';
    if (filePath.isEmpty) throw Exception('Upload failed. Please try again.');
    return filePath;
  }

  String _errorMessageFromResponse(String body) {
    try {
      final data = jsonDecode(body);
      final message = data['error']?.toString().trim() ?? '';
      if (message.isNotEmpty && message.length <= 120) return message;
    } catch (_) {}

    return 'Upload failed. Please try again.';
  }
}
