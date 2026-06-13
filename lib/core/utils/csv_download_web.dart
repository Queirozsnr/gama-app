import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadCsv(String conteudo, String nomeArquivo) async {
  final bytes = utf8.encode(conteudo);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = nomeArquivo;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
