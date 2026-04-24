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
    print('DEBUG: saveMaterial started');

    final session = _supabase.auth.currentSession;
    print('DEBUG: session exists = ${session != null}');

    if (session == null) {
      print('DEBUG: no session found');
      throw Exception('User authentication required');
    }

    final String edgeFunctionUrl =
        '${EnvService.supabaseUrl}/functions/v1/upload_material';

    print('DEBUG: edge function url = $edgeFunctionUrl');

    final uri = Uri.parse(edgeFunctionUrl);
    final request = http.MultipartRequest('POST', uri);

    print('DEBUG: building request');

    request.headers['Authorization'] =
        'Bearer ${session.accessToken}';

    print('DEBUG: auth header set');

    request.fields['folderName'] = folderName;
    request.fields['fileName'] = fileName;
    request.fields['fileType'] = fileType;
    request.fields['extractedText'] = extractedText;

    print('DEBUG: fields added');
    print('DEBUG: fileName = $fileName');
    print('DEBUG: fileType = $fileType');
    print('DEBUG: fileBytes length = ${fileBytes.length}');

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    print('DEBUG: file attached, sending request');

    final streamedResponse = await request.send();

    print('DEBUG: response received, status = ${streamedResponse.statusCode}');

    final response =
        await http.Response.fromStream(streamedResponse);

    print('DEBUG: response body = ${response.body}');

    if (response.statusCode != 200) {
      print('DEBUG: upload failed');
      throw Exception(
        'Upload failed: ${response.statusCode} - ${response.body}',
      );
    }

    print('DEBUG: upload success');
  }
}