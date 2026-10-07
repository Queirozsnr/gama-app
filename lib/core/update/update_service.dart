import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const _kGithubRepo = 'queirozsnr/gama-app';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.tamanho,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;

  /// Tamanho do APK no GitHub, em bytes: é o que garante que o arquivo baixado está inteiro.
  final int tamanho;
}

class UpdateService {
  UpdateService._();

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/vnd.github+json'},
      ));

      final response = await dio.get(
        'https://api.github.com/repos/$_kGithubRepo/releases/latest',
      );

      final tag = response.data['tag_name'] as String? ?? '';
      final remoteVersion = tag.replaceFirst('v', '');
      final notes = response.data['body'] as String? ?? '';

      final info = await PackageInfo.fromPlatform();
      if (!_isNewer(remoteVersion, info.version)) return null;

      final assets = response.data['assets'] as List<dynamic>? ?? [];
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) return null;

      return UpdateInfo(
        version: remoteVersion,
        downloadUrl: apkAsset['browser_download_url'] as String,
        releaseNotes: notes,
        tamanho: apkAsset['size'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> _apkPath(String version) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/gama_update_$version.apk';
  }

  /// Retorna o caminho se o APK desta versão já foi baixado por inteiro.
  /// Um arquivo com outro tamanho (download cortado em versões antigas do app)
  /// é apagado para ser baixado de novo.
  static Future<String?> cachedApk(UpdateInfo info) async {
    final file = File(await _apkPath(info.version));
    if (!await file.exists()) return null;
    if (await file.length() == info.tamanho) return file.path;
    await file.delete();
    return null;
  }

  static Future<String> download(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final path = await _apkPath(info.version);
    // Baixa num .part e só renomeia no fim: se o Android encerrar o app no meio
    // (ex.: ao liberar a permissão de instalar), não sobra um APK pela metade
    // com cara de pronto.
    final parcial = '$path.part';

    final dio = Dio();
    await dio.download(
      info.downloadUrl,
      parcial,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    final arquivo = File(parcial);
    if (await arquivo.length() != info.tamanho) {
      await arquivo.delete();
      throw const FileSystemException('Download incompleto. Tente novamente.');
    }
    await arquivo.rename(path);
    return path;
  }

  static Future<bool> hasInstallPermission() async {
    if (!Platform.isAndroid) return true;
    return Permission.requestInstallPackages.isGranted;
  }

  /// Abre direto a tela "Instalar apps desconhecidos" do GAMA (não a página
  /// geral do app), onde a pessoa só precisa ligar a chave.
  static Future<bool> pedirPermissaoInstalacao() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.requestInstallPackages.request()).isGranted;
  }

  /// Abre o instalador do Android. Devolve null se abriu, ou o motivo da falha
  /// (ex.: sem permissão de "Instalar apps desconhecidos").
  static Future<String?> install(String apkPath) async {
    final result = await OpenFile.open(apkPath, type: 'application/vnd.android.package-archive');
    return result.type == ResultType.done ? null : result.message;
  }

  static bool _isNewer(String remote, String current) {
    final r = _parse(remote);
    final c = _parse(current);
    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }
}
