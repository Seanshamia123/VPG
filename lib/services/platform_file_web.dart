import 'dart:html' as html;
import 'dart:typed_data';

Future<Map<String, dynamic>> readFileAsBytes(html.File file) async {
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoadEnd.first;
  final result = reader.result;
  Uint8List bytes;
  if (result is ByteBuffer) {
    bytes = result.asUint8List();
  } else if (result is Uint8List) {
    bytes = result;
  } else {
    bytes = Uint8List.fromList(List<int>.from(result as List));
  }
  return {
    'bytes': bytes,
    'name': file.name,
  };
}
