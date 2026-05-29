import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'file_picker_helper_exceptions.dart';

bool get isMobile => false;

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

Future<List<({Uint8List bytes, String name})>> pickMultipleImageBytes() async {
  final completer = Completer<List<({Uint8List bytes, String name})>>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  input.click();

  input.onChange.listen((event) async {
    final fileList = input.files;
    if (fileList == null || fileList.isEmpty) {
      completer.complete([]);
      return;
    }
    final results = <({Uint8List bytes, String name})>[];
    var pending = fileList.length;
    for (final file in fileList) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        results.add((
          bytes: Uint8List.fromList(reader.result as List<int>),
          name: file.name,
        ));
        pending--;
        if (pending == 0) completer.complete(results);
      });
      reader.onError.listen((_) {
        pending--;
        if (pending == 0) completer.complete(results);
      });
    }
  });

  return completer.future;
}

Future<({Uint8List bytes, String name})?> pickVideoBytes() async => null;

Future<({Uint8List bytes, String name})?> capturePhotoBytes() async => null;

Future<({Uint8List bytes, String name})?> captureVideoBytes() async => null;
