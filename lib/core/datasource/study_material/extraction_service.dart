import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../service/env_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExtractionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> processMaterial({
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('User authentication required');
    }

    final String edgeFunctionUrl = '${EnvService.supabaseUrl}/functions/v1/process_material';
    final uri = Uri.parse(edgeFunctionUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    request.fields['folderName'] = folderName;
    request.fields['fileName'] = fileName;

    String mimeType = 'application/octet-stream';
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) mimeType = 'image/png';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) mimeType = 'image/jpeg';
    if (lowerName.endsWith('.pdf')) mimeType = 'application/pdf';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Processing failed: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body);
  }
}