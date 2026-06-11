import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'update_service.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(info: info),
  );
}

enum _UpdateState { idle, needsPermission, downloading, done, error }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info});
  final UpdateInfo info;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> with WidgetsBindingObserver {
  _UpdateState _state = _UpdateState.idle;
  double _progress = 0;
  String? _apkPath;
  String? _errorMsg;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCached();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _state == _UpdateState.needsPermission) {
      _iniciarDownload();
    }
  }

  Future<void> _checkCached() async {
    final cached = await UpdateService.cachedApk(widget.info.version);
    if (cached != null && mounted) {
      setState(() { _state = _UpdateState.done; _apkPath = cached; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.system_update_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova versão disponível',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  'v${widget.info.version}',
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
              child: Text(
                widget.info.releaseNotes,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2, height: 1.5),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          if (_state == _UpdateState.needsPermission) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF57F17)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para instalar a atualização, permita que o GAMA instale apps externos.\n\nVá em Configurações → Instalar apps desconhecidos → GAMA e habilite a opção.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_state == _UpdateState.downloading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
          ],

          if (_state == _UpdateState.done) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.ok, size: 16),
                SizedBox(width: 6),
                Text(
                  'Download concluído — toque em Instalar.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ok),
                ),
              ],
            ),
          ],

          if (_state == _UpdateState.error) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMsg ?? 'Erro ao baixar atualização.',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (_state == _UpdateState.idle) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não', style: TextStyle(color: AppColors.ink3)),
          ),
          FilledButton.icon(
            onPressed: _iniciarDownload,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Atualizar'),
            style: _accentStyle,
          ),
        ] else if (_state == _UpdateState.needsPermission) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.ink3)),
          ),
          FilledButton.icon(
            onPressed: () async {
              await UpdateService.openInstallSettings();
            },
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('Abrir configurações'),
            style: _accentStyle,
          ),
        ] else if (_state == _UpdateState.downloading) ...[
          TextButton(
            onPressed: _cancelarDownload,
            child: const Text('Cancelar', style: TextStyle(color: AppColors.ink3)),
          ),
        ] else if (_state == _UpdateState.done) ...[
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              if (_apkPath != null) await UpdateService.install(_apkPath!);
            },
            icon: const Icon(Icons.install_mobile_outlined, size: 16),
            label: const Text('Instalar'),
            style: _accentStyle,
          ),
        ] else if (_state == _UpdateState.error) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar', style: TextStyle(color: AppColors.ink3)),
          ),
          FilledButton.icon(
            onPressed: _iniciarDownload,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente'),
            style: _accentStyle,
          ),
        ],
      ],
    );
  }

  ButtonStyle get _accentStyle => FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

  Future<void> _iniciarDownload() async {
    final hasPermission = await UpdateService.hasInstallPermission();
    if (!mounted) return;

    if (!hasPermission) {
      setState(() => _state = _UpdateState.needsPermission);
      return;
    }

    // Checa cache antes de baixar
    final cached = await UpdateService.cachedApk(widget.info.version);
    if (cached != null && mounted) {
      setState(() { _state = _UpdateState.done; _apkPath = cached; });
      return;
    }

    _cancelToken = CancelToken();
    setState(() { _state = _UpdateState.downloading; _progress = 0; });

    try {
      final path = await UpdateService.download(
        widget.info,
        onProgress: (p) { if (mounted) setState(() => _progress = p); },
        cancelToken: _cancelToken,
      );
      if (mounted) setState(() { _state = _UpdateState.done; _apkPath = path; });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.cancel) {
        setState(() => _state = _UpdateState.idle);
      } else {
        setState(() {
          _state = _UpdateState.error;
          _errorMsg = 'Falha na conexão. Verifique sua internet e tente novamente.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _UpdateState.error;
          _errorMsg = 'Erro inesperado ao baixar a atualização.';
        });
      }
    }
  }

  void _cancelarDownload() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
