import 'dart:typed_data';
import '../datasource/image_local_text_extraction_data_source.dart';
import '../datasource/pdf_local_extraction_data_source.dart';
import '../datasource/text_local_extraction_data_source.dart';

class ExtractionRepository {
  final ImageLocalDataSource imageDataSource;
  final PdfLocalDataSource pdfDataSource;
  final TextLocalDataSource textDataSource;

  ExtractionRepository(
    this.imageDataSource,
    this.pdfDataSource,
    this.textDataSource,
  );

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

    if (_isText(normalizedType)) {
      return await textDataSource.extractText(fileBytes);
    }

    throw Exception('Unsupported file type. Upload PDF, image, or text.');
  }

  bool _isImage(String fileType) {
    return fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png';
  }

  bool _isText(String fileType) {
    return fileType == 'txt' || fileType == 'md';
  }
}
