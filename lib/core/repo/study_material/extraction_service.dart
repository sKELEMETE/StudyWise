import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class ExtractionService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;

  Future<Map<String, dynamic>?> processMaterial({
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    if (_isProcessing) return null;

    if (!_isValidImageExtension(fileName) ||
        !_isValidImageBytes(fileBytes)) {
      print('=== INVALID FILE TYPE ===');
      return null;
    }

    _isProcessing = true;

    try {
      final resizedBytes = await compute(_resizeImage, fileBytes);
      final inputImage = await _buildInputImage(resizedBytes);
      final recognizedText =
          await _textRecognizer.processImage(inputImage);

      print('=== EXTRACTION SUCCESS ===');
      print(recognizedText.text);

      return {
        'fileName': fileName,
        'folderName': folderName,
        'extractedText': recognizedText.text,
      };
    } catch (e) {
      print('=== EXTRACTION FAILED ===');
      print(e);
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  bool _isValidImageExtension(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  bool _isValidImageBytes(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    return image != null;
  }

  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final resized = img.copyResize(image, width: 800);

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: 70),
    );
  }

  Future<InputImage> _buildInputImage(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_mlkit_image.jpg');
    await tempFile.writeAsBytes(bytes);

    return InputImage.fromFilePath(tempFile.path);
  }

  void dispose() {
    _textRecognizer.close();
  }
}