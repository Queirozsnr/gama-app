import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

final _imagePicker = ImagePicker();

Future<({Uint8List bytes, String name})?> pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes != null) return (bytes: file.bytes!, name: file.name);
  if (file.path != null) {
    return (bytes: await File(file.path!).readAsBytes(), name: file.name);
  }
  return null;
}

Future<({Uint8List bytes, String name})?> pickVideoBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.video,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes != null) return (bytes: file.bytes!, name: file.name);
  if (file.path != null) {
    return (bytes: await File(file.path!).readAsBytes(), name: file.name);
  }
  return null;
}

Future<({Uint8List bytes, String name})?> capturePhotoBytes() async {
  if (!isMobile) return null;
  final xfile = await _imagePicker.pickImage(source: ImageSource.camera);
  if (xfile == null) return null;
  return (bytes: await xfile.readAsBytes(), name: xfile.name);
}

Future<({Uint8List bytes, String name})?> captureVideoBytes() async {
  if (!isMobile) return null;
  final xfile = await _imagePicker.pickVideo(source: ImageSource.camera);
  if (xfile == null) return null;
  return (bytes: await xfile.readAsBytes(), name: xfile.name);
}
