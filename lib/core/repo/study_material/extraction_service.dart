import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class ExtractionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> processMaterial({
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(fileBytes);

    final inputImage = InputImage.fromFile(tempFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    await tempFile.delete();

    return {
      'fileName': fileName,
      'folderName': folderName,
      'extractedText': recognizedText.text,
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}