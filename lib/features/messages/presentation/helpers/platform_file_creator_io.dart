import 'dart:io';
import 'dart:typed_data';

/// Create a temporary io.File from bytes and filename
Future<dynamic> createPlatformFile(Uint8List bytes, String filename) async {
  final tempDir = Directory.systemTemp;
  final sanitized = filename.replaceAll(RegExp(r'[^A-Za-z0-9_\-\.]'), '_');
  final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$sanitized');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
