import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_service.dart';

sealed class UpdateDownloadState {
  const UpdateDownloadState();
}

class UpdateIdle extends UpdateDownloadState {
  const UpdateIdle();
}

class UpdateDownloading extends UpdateDownloadState {
  const UpdateDownloading(this.info, this.progress);
  final UpdateInfo info;
  final double progress;
}

class UpdateReady extends UpdateDownloadState {
  const UpdateReady(this.info, this.apkPath);
  final UpdateInfo info;
  final String apkPath;
}

class UpdateFailed extends UpdateDownloadState {
  const UpdateFailed();
}

class UpdateNotifier extends StateNotifier<UpdateDownloadState> {
  UpdateNotifier() : super(const UpdateIdle());

  CancelToken? _cancelToken;

  Future<void> checkAndDownload() async {
    if (state is UpdateDownloading || state is UpdateReady) return;

    final info = await UpdateService.checkForUpdate();
    if (info == null) return;

    // Se já tem cache, vai direto para ready
    final cached = await UpdateService.cachedApk(info.version);
    if (cached != null) {
      state = UpdateReady(info, cached);
      return;
    }

    _cancelToken = CancelToken();
    state = UpdateDownloading(info, 0);

    try {
      final path = await UpdateService.download(
        info,
        onProgress: (p) {
          if (state is UpdateDownloading) {
            state = UpdateDownloading(info, p);
          }
        },
        cancelToken: _cancelToken,
      );
      state = UpdateReady(info, path);
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) state = const UpdateFailed();
    } catch (_) {
      state = const UpdateFailed();
    }
  }

  void cancel() {
    _cancelToken?.cancel();
    state = const UpdateIdle();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateDownloadState>(
  (_) => UpdateNotifier(),
);
