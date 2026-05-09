import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum GamaSnackType { error, success, info }

abstract final class GamaSnackBar {
  static void show(
    BuildContext context,
    String message, {
    GamaSnackType type = GamaSnackType.error,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GamaToast(
        message: message,
        type: type,
        isDesktop: isDesktop,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void error(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.error);

  static void success(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.success);

  static void info(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.info);

  static (Color, IconData) _typeAssets(GamaSnackType type) => switch (type) {
    GamaSnackType.error   => (AppColors.error,   Icons.error_outline_rounded),
    GamaSnackType.success => (AppColors.success, Icons.check_circle_outline_rounded),
    GamaSnackType.info    => (AppColors.primary,  Icons.info_outline_rounded),
  };
}

class _GamaToast extends StatefulWidget {
  const _GamaToast({
    required this.message,
    required this.type,
    required this.isDesktop,
    required this.onDismiss,
  });

  final String message;
  final GamaSnackType type;
  final bool isDesktop;
  final VoidCallback onDismiss;

  @override
  State<_GamaToast> createState() => _GamaToastState();
}

class _GamaToastState extends State<_GamaToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, icon) = GamaSnackBar._typeAssets(widget.type);
    final toast = _buildToast(bg, icon);

    return widget.isDesktop
        ? Positioned(top: 24, right: 24, child: toast)
        : Positioned(top: 24, left: 24, right: 24, child: toast);
  }

  Widget _buildToast(Color bg, IconData icon) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
