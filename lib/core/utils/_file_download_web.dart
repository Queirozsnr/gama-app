import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<bool> downloadFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async {
  final blob = web.Blob(
    [bytes.buffer.toJS as JSAny].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  web.URL.revokeObjectURL(url);
  return true;
}

Future<bool> downloadAndOpenZip(Uint8List bytes, String filename) =>
    downloadFile(bytes, filename, mimeType: 'application/zip');
