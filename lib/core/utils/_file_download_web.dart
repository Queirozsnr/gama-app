import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<bool> downloadAndOpenZip(Uint8List bytes, String filename) async {
  final blob = web.Blob(
    [bytes.buffer.toJS as JSAny].toJS,
    web.BlobPropertyBag(type: 'application/zip'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  web.URL.revokeObjectURL(url);
  return true;
}
