import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<({Uint8List bytes, String name})?> pickImageBytes() async {
  final completer = Completer<({Uint8List bytes, String name})?>();

  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final bytes = Uint8List.fromList(reader.result as List<int>);
      completer.complete((bytes: bytes, name: file.name));
    });
    reader.onError.listen((_) => completer.complete(null));
  });

  return completer.future;
}
