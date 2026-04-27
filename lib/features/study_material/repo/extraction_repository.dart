import 'dart:typed_data';
import '../datasource/image_local_data_source.dart';
import '../datasource/pdf_local_data_source.dart';

class ExtractionRepository {
  final ImageLocalDataSource imageDataSource;
  final PdfLocalDataSource pdfDataSource;

  ExtractionRepository(this.imageDataSource, this.pdfDataSource);

  Future<String> extractText(String fileName, String fileType, Uint8List fileBytes) async {
    if (fileType.toLowerCase() == 'pdf') {
      final directText = await pdfDataSource.extractDirectText(fileBytes);
      if (directText.isNotEmpty) return directText;

      final pageImages = await pdfDataSource.renderPagesToImages(fileBytes);
      if (pageImages.isEmpty) return '';

      final results = await Future.wait(
        pageImages.asMap().entries.map((entry) async {
          return await imageDataSource.extractText('page_${entry.key}.jpg', entry.value);
        }),
      );
      return results.join('\n').trim();
    } else {
      return await imageDataSource.extractText(fileName, fileBytes);
    }
  }
}