import 'package:flutter/material.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({
    super.key,
    required this.groupName,
    required this.groupLocation,
    required this.greeting,
    required this.subtitle,
    this.onAction,
    this.actionLabel = 'Abrir nova OS',
  });

  final String groupName;
  final String groupLocation;
  final String greeting;
  final String subtitle;
  final VoidCallback? onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C35C5), Color(0xFF3B6ECC)],
        ),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _Content(groupName: groupName, groupLocation: groupLocation, greeting: greeting, subtitle: subtitle)),
                _ActionButton(label: actionLabel, onTap: onAction),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Content(groupName: groupName, groupLocation: groupLocation, greeting: greeting, subtitle: subtitle),
                const SizedBox(height: 20),
                _ActionButton(label: actionLabel, onTap: onAction),
              ],
            ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.groupName,
    required this.groupLocation,
    required this.greeting,
    required this.subtitle,
  });

  final String groupName;
  final String groupLocation;
  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8C42),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$groupName • $groupLocation'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8C42),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
