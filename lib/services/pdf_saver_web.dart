import 'dart:html' as html;
import 'dart:typed_data';

Future<void> savePdfFile(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename);
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  // Delay revocation to allow browser to start the download event loop tick
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}
