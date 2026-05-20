import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class GamaBottomNav extends ConsumerWidget {
  const GamaBottomNav({super.key});

  static const _main = [
    _Item('Painel',   Icons.space_dashboard_outlined, '/home'),
    _Item('OS',       Icons.receipt_long_outlined,    '/ordens-servico'),
    _Item('Clientes', Icons.groups_outlined,          '/clientes'),
    _Item('Estoque',  Icons.inventory_2_outlined,     '/estoque'),
  ];

  static const _mais = [
    _Item('Veículos',     Icons.directions_car_outlined,   '/veiculos'),
    _Item('Funcionários', Icons.badge_outlined,             '/funcionarios'),
    _Item('Fornecedores', Icons.local_shipping_outlined,    '/fornecedores'),
    _Item('Pagamentos',   Icons.payments_outlined,          '/pagamentos'),
    _Item('Receitas',     Icons.trending_up_outlined,       '/receitas'),
    _Item('Configurações',Icons.settings_outlined,          '/configuracoes-oficina'),
  ];

  bool _isMainActive(String route, String current) =>
      current.startsWith(route) || (route == '/home' && current == '/');

  bool _isMaisActive(String current) =>
      _mais.any((i) => current.startsWith(i.route));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouterState.of(context).matchedLocation;

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
              for (final item in _main)
                Expanded(
                  child: _NavButton(
                    item: item,
                    isActive: _isMainActive(item.route, current),
                    onTap: () => context.go(item.route),
                  ),
                ),
              Expanded(
                child: _NavButton(
                  item: const _Item('Mais', Icons.menu_outlined, ''),
                  isActive: _isMaisActive(current),
                  onTap: () => _showMais(context, current),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMais(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MaisSheet(items: _mais, current: current),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.isActive, required this.onTap});
  final _Item item;
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
          Icon(item.icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(fontFamily: 'Inter', 
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

class _MaisSheet extends StatelessWidget {
  const _MaisSheet({required this.items, required this.current});
  final List<_Item> items;
  final String current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
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
                for (final item in items) _MaisItem(item: item, current: current),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaisItem extends StatelessWidget {
  const _MaisItem({required this.item, required this.current});
  final _Item item;
  final String current;

  @override
  Widget build(BuildContext context) {
    final isActive = current.startsWith(item.route);
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
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6, height: 6,
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

class _Item {
  const _Item(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
