import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../state/top_bar_scope.dart';
import '../widgets/notification_bell.dart';

class GamaTopBar extends StatelessWidget {
  const GamaTopBar({
    super.key,
    required this.isDesktop,
    this.pageTitle,
    this.pageSubtitle,
    this.hasNotification = true,
  });

  final bool isDesktop;
  final String? pageTitle;
  final String? pageSubtitle;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    final slot = TopBarScope.maybeOf(context)?.slot;

    return isDesktop
        ? _DesktopTopBar(
            pageTitle: pageTitle,
            pageSubtitle: pageSubtitle,
            slot: slot,
            hasNotification: hasNotification,
          )
        : _MobileTopBar(
            pageTitle: pageTitle,
            slot: slot,
            hasNotification: hasNotification,
          );
  }
}

// ── Desktop: single row with search ──────────────────────────────
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    this.pageTitle,
    this.pageSubtitle,
    this.slot,
    required this.hasNotification,
  });

  final String? pageTitle;
  final String? pageSubtitle;
  final TopBarSlot? slot;
  final bool hasNotification;

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
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                if (pageSubtitle != null)
                  Text(
                    pageSubtitle!,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2),
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
          NotificationBell(hasNotification: hasNotification),
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
    required this.hasNotification,
  });

  final String? pageTitle;
  final TopBarSlot? slot;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = slot?.pageTitle ?? pageTitle;
    if (effectiveTitle == null && (slot == null || !slot!.hasContent)) {
      return const SizedBox.shrink();
    }
    final hasSearch = slot?.hasSearch == true;
    final mobileAction = slot?.mobileAction ?? slot?.action;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: leading/hamburger + title + notification + action
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: hasSearch ? AppColors.surface2 : AppColors.line,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (slot?.leading != null)
                slot!.leading!,
              const SizedBox(width: 10),
              if (effectiveTitle != null)
                Expanded(
                  child: Text(
                    effectiveTitle,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              NotificationBell(hasNotification: hasNotification),
              if (mobileAction != null) ...[
                const SizedBox(width: 8),
                mobileAction,
              ],
            ],
          ),
        ),
        // Row 2: search (only when slot has search)
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
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
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
