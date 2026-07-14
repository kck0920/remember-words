import 'dart:io';
import 'package:file_picker/file_picker.dart';

Future<String?> pickJsonFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    if (file.path != null) {
      final ioFile = File(file.path!);
      return await ioFile.readAsString();
    }
  }
  return null;
}
