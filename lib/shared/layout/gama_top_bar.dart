import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/gama_search_bar.dart';
import '../widgets/notification_bell.dart';

class GamaTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GamaTopBar({
    super.key,
    required this.isDesktop,
    this.onMenuTap,
    this.pageTitle,
    this.pageSubtitle,
    this.action,
    this.hasNotification = true,
  });

  final bool isDesktop;
  final VoidCallback? onMenuTap;
  final String? pageTitle;
  final String? pageSubtitle;
  final Widget? action;
  final bool hasNotification;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isDesktop ? _DesktopBar(
        pageTitle: pageTitle,
        pageSubtitle: pageSubtitle,
        action: action,
        hasNotification: hasNotification,
      ) : _MobileBar(
        onMenuTap: onMenuTap,
        action: action,
        hasNotification: hasNotification,
      ),
    );
  }
}

class _DesktopBar extends StatelessWidget {
  const _DesktopBar({
    this.pageTitle,
    this.pageSubtitle,
    this.action,
    required this.hasNotification,
  });

  final String? pageTitle;
  final String? pageSubtitle;
  final Widget? action;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.table_rows_outlined, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        if (pageTitle != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pageTitle!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (pageSubtitle != null)
                Text(
                  pageSubtitle!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(width: 24),
        ],
        Expanded(
          child: GamaSearchBar(hint: 'Buscar OS, cliente, placa...'),
        ),
        const SizedBox(width: 16),
        NotificationBell(hasNotification: hasNotification),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}

class _MobileBar extends StatelessWidget {
  const _MobileBar({
    this.onMenuTap,
    this.action,
    required this.hasNotification,
  });

  final VoidCallback? onMenuTap;
  final Widget? action;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.table_rows_outlined, size: 22),
          onPressed: onMenuTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        NotificationBell(hasNotification: hasNotification),
        if (action != null) ...[
          const SizedBox(width: 8),
          action!,
        ],
      ],
    );
  }
}
