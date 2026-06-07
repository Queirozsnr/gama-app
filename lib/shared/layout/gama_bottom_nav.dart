import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../features/auth/presentation/auth_notifier.dart';

class GamaBottomNav extends ConsumerWidget {
  const GamaBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branches 0–3: botões fixos no nav bar.
  // Branch 4 ("Mais"): acessado via bottom sheet.
  static const _tabs = [
    _Tab('Painel',   Icons.space_dashboard_outlined, 0),
    _Tab('OS',       Icons.receipt_long_outlined,    1),
    _Tab('Clientes', Icons.groups_outlined,          2),
    _Tab('Estoque',  Icons.inventory_2_outlined,     3),
  ];

  static const _maisRoutes = [
    _Item('Veículos',      Icons.directions_car_outlined,   '/veiculos'),
    _Item('Funcionários',  Icons.badge_outlined,             '/funcionarios'),
    _Item('Fornecedores',  Icons.local_shipping_outlined,    '/fornecedores'),
    _Item('Pagamentos',    Icons.payments_outlined,          '/pagamentos'),
    _Item('Receitas',      Icons.trending_up_outlined,       '/receitas'),
    _Item('Assinatura',    Icons.workspace_premium_outlined, '/assinatura'),
    _Item('Configurações', Icons.settings_outlined,          '/configuracoes-oficina'),
  ];

  static const _adminRoute = _Item('Admin', Icons.shield_outlined, '/admin');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final token = ref.watch(authNotifierProvider).valueOrNull?.token ?? '';
    final adminMode = token.isNotEmpty && JwtDecoder.isAdmin(token);
    final isGestor = token.isNotEmpty && JwtDecoder.isGestor(token);
    final maisActive = currentIndex == 4;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: _NavButton(
                    label: tab.label,
                    icon: tab.icon,
                    isActive: currentIndex == tab.branchIndex,
                    onTap: () => navigationShell.goBranch(
                      tab.branchIndex,
                      initialLocation: currentIndex == tab.branchIndex,
                    ),
                  ),
                ),
              Expanded(
                child: _NavButton(
                  label: 'Mais',
                  icon: Icons.menu_outlined,
                  isActive: maisActive,
                  onTap: () => _showMais(context, adminMode, isGestor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMais(BuildContext context, bool adminMode, bool isGestor) {
    const restricted = {'/funcionarios', '/receitas', '/configuracoes-oficina'};
    final base = isGestor
        ? _maisRoutes
        : _maisRoutes.where((i) => !restricted.contains(i.route)).toList();
    final items = adminMode ? [...base, _adminRoute] : base;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MaisSheet(
        items: items,
        currentLocation: GoRouterState.of(context).matchedLocation,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.ink3;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaisSheet extends ConsumerWidget {
  const _MaisSheet({required this.items, required this.currentLocation});

  final List<_Item> items;
  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (final item in items)
                  _MaisItem(item: item, currentLocation: currentLocation),
                const Divider(height: 20),
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_outlined, size: 20, color: AppColors.danger),
                        SizedBox(width: 14),
                        Text(
                          'Sair',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaisItem extends StatelessWidget {
  const _MaisItem({required this.item, required this.currentLocation});

  final _Item item;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocation.startsWith(item.route);
    final color = isActive ? AppColors.accent : AppColors.ink2;
    final textColor = isActive ? AppColors.accent : AppColors.ink;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(item.route);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.branchIndex);
  final String label;
  final IconData icon;
  final int branchIndex;
}

class _Item {
  const _Item(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
