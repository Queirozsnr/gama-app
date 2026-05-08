import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/gama_avatar.dart';

class GamaSidebar extends StatelessWidget {
  const GamaSidebar({
    super.key,
    required this.groupName,
    required this.groupInitials,
    required this.userName,
    required this.userInitials,
    required this.userRole,
    this.planLabel = 'PLANO PRO',
  });

  final String groupName;
  final String groupInitials;
  final String userName;
  final String userInitials;
  final String userRole;
  final String planLabel;

  static const _sections = [
    _NavSection('Principal', [
      _NavItem('Dashboard',          Icons.dashboard_outlined,      '/home'),
      _NavItem('Ordens de Serviço',  Icons.receipt_long_outlined,   '/ordens-servico'),
      _NavItem('Clientes',           Icons.people_outline,          '/clientes'),
      _NavItem('Veículos',           Icons.directions_car_outlined, '/veiculos'),
    ]),
    _NavSection('Operação', [
      _NavItem('Estoque',            Icons.inventory_2_outlined,    '/estoque'),
      _NavItem('Funcionários',       Icons.badge_outlined,          '/funcionarios'),
      _NavItem('Pagamentos',         Icons.payments_outlined,       '/pagamentos'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Container(
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(),
          _GroupCard(
            initials: groupInitials,
            name: groupName,
            planLabel: planLabel,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final section in _sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  for (final item in section.items)
                    _SidebarNavItem(
                      item: item,
                      isActive: currentRoute == item.route ||
                          (item.route == '/home' && currentRoute == '/'),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _SidebarNavItem(
                  item: const _NavItem('Ajuda', Icons.help_outline, '/ajuda'),
                  isActive: false,
                ),
                _SidebarNavItem(
                  item: const _NavItem('Configurações', Icons.settings_outlined, '/configuracoes'),
                  isActive: false,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _UserProfile(
            initials: userInitials,
            name: userName,
            role: userRole,
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GAMA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'ERP Automotivo',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.initials,
    required this.name,
    required this.planLabel,
  });

  final String initials;
  final String name;
  final String planLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GamaAvatar(initials: initials, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  planLabel,
                  style: const TextStyle(fontSize: 10, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
        context.go(item.route);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfile extends StatelessWidget {
  const _UserProfile({
    required this.initials,
    required this.name,
    required this.role,
  });

  final String initials;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GamaAvatar(initials: initials, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection {
  const _NavSection(this.label, this.items);
  final String label;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
