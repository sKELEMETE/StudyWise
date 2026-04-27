import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class ExtractionService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>?> processMaterial({
    required String folderName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final startTime = DateTime.now();

    if (!_isValidImageBytes(fileBytes)) {
      print('❌ Invalid image bytes');
      return null;
    }

    try {
      print('\n=== 🧠 ML KIT START ===');
      print('📄 File: $fileName');
      print('📊 Original size: ${fileBytes.length}');

      final resizedBytes = await compute(_resizeImage, fileBytes);
      print('📉 Resized size: ${resizedBytes.length}');

      final inputImage = await _buildInputImage(resizedBytes);

      final recognizedText =
          await _textRecognizer.processImage(inputImage);

      print('📝 Text length: ${recognizedText.text.length}');
      print('📦 Blocks: ${recognizedText.blocks.length}');

      // 🧹 cleanup temp file
      try {
        final file = File(inputImage.filePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      return {
        'fileName': fileName,
        'folderName': folderName,
        'extractedText': recognizedText.text,
      };
    } catch (e) {
      print('❌ ML Kit error: $e');
      return null;
    } finally {
      print(
          '⏱️ Took: ${DateTime.now().difference(startTime).inMilliseconds} ms');
    }
  }

  bool _isValidImageBytes(Uint8List bytes) {
    return img.decodeImage(bytes) != null;
  }

  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final resized = img.copyResize(image, width: 1200);

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: 80),
    );
  }

  Future<InputImage> _buildInputImage(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/mlkit_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await file.writeAsBytes(bytes);

    return InputImage.fromFilePath(file.path);
  }

  void dispose() {
    _textRecognizer.close();
  }
}