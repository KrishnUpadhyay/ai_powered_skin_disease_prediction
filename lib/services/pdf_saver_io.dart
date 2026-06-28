import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> savePdfFile(Uint8List bytes, String filename) async {
  final String? outputFile = await FilePicker.saveFile(
    dialogTitle: 'Save Clinical Report PDF',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsBytes(bytes);
  }
}
