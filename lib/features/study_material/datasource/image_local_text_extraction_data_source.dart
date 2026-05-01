import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class ImageLocalDataSource {
  Future<String> extractText(String fileName, Uint8List fileBytes) async {
    if (!_isValidImageBytes(fileBytes)) throw Exception('Invalid image bytes');

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final resizedBytes = await compute(_resizeImage, fileBytes);
      final inputImage = await _buildInputImage(resizedBytes);
      final recognizedText = await textRecognizer.processImage(inputImage);

      try {
        final file = File(inputImage.filePath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      return recognizedText.text;
    } catch (e) {
      throw Exception('ML Kit error: $e');
    } finally {
      textRecognizer.close();
    }
  }

  bool _isValidImageBytes(Uint8List bytes) => img.decodeImage(bytes) != null;

  static Uint8List _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    final resized =
        image.width > 1400 ? img.copyResize(image, width: 1400) : image;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  Future<InputImage> _buildInputImage(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/mlkit_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes);
    return InputImage.fromFilePath(file.path);
  }
}
