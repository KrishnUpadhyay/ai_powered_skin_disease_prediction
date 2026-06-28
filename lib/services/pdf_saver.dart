import 'dart:typed_data';
import 'pdf_saver_stub.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    if (dart.library.io) 'pdf_saver_io.dart';

class PdfSaver {
  static Future<void> save(Uint8List bytes, String filename) async {
    await savePdfFile(bytes, filename);
  }
}
