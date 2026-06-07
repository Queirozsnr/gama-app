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

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info});
  final UpdateInfo info;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress; // null = não iniciou, 0..1 = baixando, 1.0 = concluído

  @override
  Widget build(BuildContext context) {
    final downloading = _progress != null && _progress! < 1.0;
    final done = _progress == 1.0;

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
            child: const Icon(Icons.system_update_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova versão disponível',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'v${widget.info.version}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
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
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.info.releaseNotes,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ink2,
                  height: 1.5,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (downloading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${((_progress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ],
          if (done) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: AppColors.ok, size: 16),
                SizedBox(width: 6),
                Text(
                  'Download concluído — instale para continuar.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ok,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (_progress == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não',
                style: TextStyle(color: AppColors.ink3)),
          ),
          FilledButton.icon(
            onPressed: _iniciarDownload,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Atualizar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ] else if (done) ...[
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.install_mobile_outlined, size: 16),
            label: const Text('Fechar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _iniciarDownload() async {
    setState(() => _progress = 0.0);
    try {
      await UpdateService.downloadAndInstall(
        widget.info,
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() => _progress = 1.0);
    } catch (_) {
      if (mounted) {
        setState(() => _progress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao baixar atualização.')),
        );
      }
    }
  }
}
