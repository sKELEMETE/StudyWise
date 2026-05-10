import 'dart:typed_data';
import '../datasource/image_local_text_extraction_data_source.dart';
import '../datasource/pdf_local_extraction_data_source.dart';

class ExtractionRepository {
  final ImageLocalDataSource imageDataSource;
  final PdfLocalDataSource pdfDataSource;

  ExtractionRepository(this.imageDataSource, this.pdfDataSource);

  Future<String> extractText(
    String fileName,
    String fileType,
    Uint8List fileBytes,
  ) async {
    final normalizedType = fileType.toLowerCase();

    if (normalizedType == 'pdf') {
      final directText = await pdfDataSource.extractDirectText(fileBytes);
      if (directText.isNotEmpty) return directText;

      final pageImages = await pdfDataSource.renderPagesToImages(fileBytes);
      if (pageImages.isEmpty) return '';

      final results = await Future.wait(
        pageImages.asMap().entries.map((entry) async {
          return await imageDataSource.extractText(
            'page_${entry.key}.jpg',
            entry.value,
          );
        }),
      );
      return results.join('\n').trim();
    }

    if (_isImage(normalizedType)) {
      return await imageDataSource.extractText(fileName, fileBytes);
    }

    throw Exception('Unsupported file type. Upload PDF or image.');
  }

  bool _isImage(String fileType) {
    return fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png';
  }
}
