import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Generic desktop-width list row card.
///
/// Layout: [leading] | [title + subtitle] | [details column] | [trailing]
///
/// - [details] is a list of [GamaListDetail] (icon + text) shown as a column
///   in the middle section. Typically contact info or metadata.
/// - [leading], [trailing] are free widgets — pass an avatar, chips, buttons.
class GamaListTile extends StatelessWidget {
  const GamaListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.details = const [],
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final List<GamaListDetail> details;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 14),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details
                      .map((d) => _DetailRow(detail: d))
                      .toList(),
                ),
              ),
            ] else
              const Spacer(),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class GamaListDetail {
  const GamaListDetail({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});
  final GamaListDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(detail.icon, size: 13, color: AppColors.ink3),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              detail.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
