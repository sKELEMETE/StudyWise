import 'dart:convert';
import 'dart:typed_data';

class TextLocalDataSource {
  Future<String> extractText(Uint8List fileBytes) async {
    if (fileBytes.isEmpty) {
      throw Exception('Could not read the selected file.');
    }

    final text = utf8.decode(fileBytes, allowMalformed: true).trim();
    if (text.isEmpty) {
      throw Exception('No readable text was found in this file.');
    }

    return text;
  }
}
