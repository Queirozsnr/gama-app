import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../state/top_bar_scope.dart';
import '../widgets/notification_bell.dart';

class GamaTopBar extends StatelessWidget {
  const GamaTopBar({
    super.key,
    required this.isDesktop,
    this.pageTitle,
    this.pageSubtitle,
  });

  final bool isDesktop;
  final String? pageTitle;
  final String? pageSubtitle;

  @override
  Widget build(BuildContext context) {
    final slot = TopBarScope.maybeOf(context)?.slot;

    return isDesktop
        ? _DesktopTopBar(
            pageTitle: pageTitle,
            pageSubtitle: pageSubtitle,
            slot: slot,
          )
        : _MobileTopBar(
            pageTitle: pageTitle,
            slot: slot,
          );
  }
}

// ── Desktop: single row with search ──────────────────────────────
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    this.pageTitle,
    this.pageSubtitle,
    this.slot,
  });

  final String? pageTitle;
  final String? pageSubtitle;
  final TopBarSlot? slot;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = slot?.pageTitle ?? pageTitle;
    if (effectiveTitle == null && (slot == null || !slot!.hasContent)) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Optional leading (back button, close, etc.)
          if (slot?.leading != null) ...[
            slot!.leading!,
            const SizedBox(width: 8),
          ],
          // Title block
          if (effectiveTitle != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  effectiveTitle,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                if (slot?.desktopSubtitle != null || pageSubtitle != null)
                  Text(
                    slot?.desktopSubtitle ?? pageSubtitle!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          const SizedBox(width: 20),
          const Spacer(),
          if (slot?.hasSearch == true) ...[
            SizedBox(
              width: 300,
              child: _SearchBar(
                controller: slot!.searchController,
                hint: slot!.searchHint ?? 'Buscar…',
                onChanged: slot!.onSearchChanged,
              ),
            ),
            const SizedBox(width: 16),
          ],
          const NotificationBell(),
          if (slot?.action != null) ...[
            const SizedBox(width: 12),
            slot!.action!,
          ],
        ],
      ),
    );
  }
}

// ── Mobile: 2-row (title row + optional search row) ──────────────
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    this.pageTitle,
    this.slot,
  });

  final String? pageTitle;
  final TopBarSlot? slot;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = slot?.pageTitle ?? pageTitle;
    if (effectiveTitle == null && (slot == null || !slot!.hasContent)) {
      return const SizedBox.shrink();
    }

    final isDark = slot?.mobileStyle == MobileTopBarStyle.dark;
    return isDark
        ? _DarkMobileHeader(slot: slot, title: effectiveTitle)
        : _LightMobileHeader(slot: slot, title: effectiveTitle);
  }
}

// ── Dark variant: detail pages (OS detalhe, etc.) ────────────────
class _DarkMobileHeader extends StatelessWidget {
  const _DarkMobileHeader({this.slot, this.title});
  final TopBarSlot? slot;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final mobileAction = slot?.mobileAction ?? slot?.action;
    final hasSubtitle = slot?.mobileSubtitle != null;

    return Container(
      decoration: const BoxDecoration(color: AppColors.sidebarBg),
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: hasSubtitle ? 68 : 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading (back button) — recolored white
              if (slot?.leading != null)
                IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: slot!.leading!,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 4),
              // Title block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasSubtitle)
                      Text(
                        slot!.mobileSubtitle!,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Trailing actions
              ?mobileAction,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Light variant: forms, wizards, and main screens ───────────────
class _LightMobileHeader extends StatelessWidget {
  const _LightMobileHeader({
    this.slot,
    this.title,
  });
  final TopBarSlot? slot;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final hasSearch = slot?.hasSearch == true;
    final mobileAction = slot?.mobileAction ?? slot?.action;
    final hasSubtitle = slot?.mobileSubtitle != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: hasSearch ? AppColors.surface2 : AppColors.line,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: hasSubtitle ? 64 : 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (slot?.leading != null)
                    slot!.leading!
                  else
                    const SizedBox(width: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasSubtitle)
                          Text(
                            slot!.mobileSubtitle!,
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        if (title != null)
                          Text(
                            title!,
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                  if (mobileAction != null) ...[
                    const SizedBox(width: 8),
                    mobileAction,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasSearch)
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: _SearchBar(
              controller: slot!.searchController,
              hint: slot!.searchHint ?? 'Buscar…',
              onChanged: slot!.onSearchChanged,
            ),
          ),
      ],
    );
  }
}

// ── Shared search bar ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({this.controller, this.hint, this.onChanged});

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: AppColors.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
