import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadCsv(String conteudo, String nomeArquivo) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$nomeArquivo');
  await file.writeAsString(conteudo);
  await OpenFile.open(file.path);
}
