import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    this.hasNotification = false,
    this.onTap,
  });

  final bool hasNotification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, size: 24),
            if (hasNotification)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6D00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
