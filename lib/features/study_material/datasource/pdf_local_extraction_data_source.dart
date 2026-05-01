import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfLocalDataSource {
  Future<String> extractDirectText(Uint8List pdfBytes) async {
    try {
      final document = sf_pdf.PdfDocument(inputBytes: pdfBytes);
      final text = sf_pdf.PdfTextExtractor(document).extractText();
      document.dispose();
      return text.trim();
    } catch (e) {
      return '';
    }
  }

  Future<List<Uint8List>> renderPagesToImages(Uint8List pdfBytes) async {
    final images = <Uint8List>[];
    try {
      final document = await pdfx.PdfDocument.openData(pdfBytes);
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final imgPage = await page.render(
          width: page.width * 1.5,
          height: page.height * 1.5,
          format: pdfx.PdfPageImageFormat.jpeg,
        );
        if (imgPage != null) images.add(imgPage.bytes);
        await page.close();
      }
      await document.close();
    } catch (e) {
      throw Exception('PDF->Image error: $e');
    }
    return images;
  }
}
