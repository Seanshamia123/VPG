import 'dart:typed_data';
import 'dart:html' as html;

/// Create a web File from bytes and filename
Future<dynamic> createPlatformFile(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final file = html.File([blob], filename);
  return file;
}
