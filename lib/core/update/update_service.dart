import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

// Repositório GitHub no formato "owner/repo"
const _kGithubRepo = 'queirozsnr/gama-app';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;
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
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndInstall(
    UpdateInfo info, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final apkPath = '${dir.path}/gama_update.apk';

    final dio = Dio();
    await dio.download(
      info.downloadUrl,
      apkPath,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    await OpenFile.open(apkPath, type: 'application/vnd.android.package-archive');
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
