import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'file_picker_helper_exceptions.dart';

bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

final _imagePicker = ImagePicker();

Future<({Uint8List bytes, String name})?> pickImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.size > kMaxMediaBytes) throw FileTooLargeException(file.name);
  if (file.bytes != null) return (bytes: file.bytes!, name: file.name);
  if (file.path != null) {
    return (bytes: await File(file.path!).readAsBytes(), name: file.name);
  }
  return null;
}

Future<List<({Uint8List bytes, String name})>> pickMultipleImageBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: true,
  );
  if (result == null || result.files.isEmpty) return [];
  final files = <({Uint8List bytes, String name})>[];
  for (final file in result.files) {
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes != null) files.add((bytes: bytes, name: file.name));
  }
  return files;
}

Future<({Uint8List bytes, String name})?> pickVideoBytes() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.video,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.size > kMaxMediaBytes) throw FileTooLargeException(file.name);
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
  if (await xfile.length() > kMaxMediaBytes) throw FileTooLargeException(xfile.name);
  return (bytes: await xfile.readAsBytes(), name: xfile.name);
}

Future<({Uint8List bytes, String name})?> captureVideoBytes() async {
  if (!isMobile) return null;
  final xfile = await _imagePicker.pickVideo(source: ImageSource.camera);
  if (xfile == null) return null;
  if (await xfile.length() > kMaxMediaBytes) throw FileTooLargeException(xfile.name);
  return (bytes: await xfile.readAsBytes(), name: xfile.name);
}
