import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

class PdfToImageService {
  Future<List<Uint8List>> renderPagesToImages(
      Uint8List pdfBytes) async {
    final start = DateTime.now();
    final images = <Uint8List>[];

    try {
      print('🖼️ PDF → Images');

      final document = await PdfDocument.openData(pdfBytes);

      print('📑 Pages: ${document.pagesCount}');

      for (int i = 1; i <= document.pagesCount; i++) {
        print('➡️ Rendering page $i');

        final page = await document.getPage(i);

        final imgPage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
        );

        if (imgPage != null) {
          images.add(imgPage.bytes);
          print('✅ Page $i done');
        }

        await page.close();
      }

      await document.close();

      print('🎉 Total images: ${images.length}');
    } catch (e) {
      print('❌ PDF→Image error: $e');
    }

    print(
        '⏱️ Took: ${DateTime.now().difference(start).inMilliseconds} ms');

    return images;
  }
}