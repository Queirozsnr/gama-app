import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> downloadFile(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async {
  Directory? dir;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    dir = await getDownloadsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
  return true;
}

Future<bool> downloadAndOpenZip(Uint8List bytes, String filename) =>
    downloadFile(bytes, filename, mimeType: 'application/zip');
