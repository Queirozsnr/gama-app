import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_service.dart';

sealed class UpdateCheckState {
  const UpdateCheckState();
}

class UpdateIdle extends UpdateCheckState {
  const UpdateIdle();
}

/// Há versão nova. [apkPath] vem preenchido se o APK já foi baixado antes.
class UpdateDisponivel extends UpdateCheckState {
  const UpdateDisponivel(this.info, this.apkPath);
  final UpdateInfo info;
  final String? apkPath;
}

/// Só verifica se há versão nova. O download (~70 MB) fica a cargo do diálogo,
/// que mostra o progresso e deixa a pessoa escolher quando baixar.
class UpdateNotifier extends StateNotifier<UpdateCheckState> {
  UpdateNotifier() : super(const UpdateIdle());

  Future<void> verificar() async {
    if (state is UpdateDisponivel) return;

    final info = await UpdateService.checkForUpdate();
    if (info == null) return;

    final cached = await UpdateService.cachedApk(info);
    state = UpdateDisponivel(info, cached);
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateCheckState>(
  (_) => UpdateNotifier(),
);
