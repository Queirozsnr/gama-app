import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

class GamaLogoMark extends StatelessWidget {
  const GamaLogoMark({super.key, this.size = 34, this.radius = 8});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.sidebarBg,
        child: SvgPicture.asset(
          'assets/icon/icon_gama.svg',
          colorFilter: const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
