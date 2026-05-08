import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../widgets/gama_avatar.dart';

class GamaSidebar extends ConsumerWidget {
  const GamaSidebar({super.key});

  static const _sections = [
    _NavSection('Principal', [
      _NavItem('Dashboard',         Icons.dashboard_outlined,      '/home'),
      _NavItem('Ordens de Serviço', Icons.receipt_long_outlined,   '/ordens-servico'),
      _NavItem('Clientes',          Icons.people_outline,          '/clientes'),
      _NavItem('Veículos',          Icons.directions_car_outlined, '/veiculos'),
    ]),
    _NavSection('Operação', [
      _NavItem('Estoque',       Icons.inventory_2_outlined, '/estoque'),
      _NavItem('Funcionários',  Icons.badge_outlined,       '/funcionarios'),
      _NavItem('Pagamentos',    Icons.payments_outlined,    '/pagamentos'),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final currentRoute = GoRouterState.of(context).matchedLocation;

    final groups = auth?.availableGroups ?? [];
    final currentGroupId = auth?.grupoOficinaId;
    final currentGroup = groups.isEmpty
        ? null
        : groups.cast<GrupoItem?>().firstWhere(
            (g) => g?.id == currentGroupId,
            orElse: () => groups.first,
          );
    final groupName = currentGroup?.nome ?? 'Minha Oficina';
    final groupInitials = _initials(groupName);

    final token = auth?.token ?? '';
    final userName = token.isNotEmpty ? (JwtDecoder.nome(token) ?? 'Usuário') : 'Usuário';
    final userCargo = token.isNotEmpty ? (JwtDecoder.cargo(token) ?? '') : '';
    final userInitials = _initials(userName);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(),
          _GroupCard(
            initials: groupInitials,
            name: groupName,
            groups: groups,
            currentGroupId: currentGroupId,
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
                      isActive: currentRoute.startsWith(item.route) ||
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
          _UserProfile(initials: userInitials, name: userName, role: userCargo),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.substring(0, name.length.clamp(0, 2));
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
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

class _GroupCard extends ConsumerStatefulWidget {
  const _GroupCard({
    required this.initials,
    required this.name,
    required this.groups,
    this.currentGroupId,
  });

  final String initials;
  final String name;
  final List<GrupoItem> groups;
  final int? currentGroupId;

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  int? _loadingId;

  Future<void> _switchGroup(int grupoId) async {
    if (grupoId == widget.currentGroupId) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _loadingId = grupoId);
    try {
      await ref.read(authNotifierProvider.notifier).selectGroup(grupoId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  void _showSwitcher() {
    if (widget.groups.length <= 1) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trocar oficina',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (final group in widget.groups) ...[
                _GroupOption(
                  group: group,
                  isCurrent: group.id == widget.currentGroupId,
                  isLoading: _loadingId == group.id,
                  isDisabled: _loadingId != null,
                  onTap: () {
                    setModalState(() {});
                    _switchGroup(group.id);
                  },
                ),
                if (group != widget.groups.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSwitch = widget.groups.length > 1;

    return GestureDetector(
      onTap: canSwitch ? _showSwitcher : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            GamaAvatar(initials: widget.initials, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'PLANO PRO',
                    style: TextStyle(fontSize: 10, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (canSwitch)
              const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _GroupOption extends StatelessWidget {
  const _GroupOption({
    required this.group,
    required this.isCurrent,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final GrupoItem group;
  final bool isCurrent;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: GamaAvatar(initials: group.nome.substring(0, 2), size: 36),
      title: Text(
        group.nome,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isCurrent
              ? const Icon(Icons.check, size: 18, color: AppColors.primary)
              : null,
      onTap: isDisabled ? null : onTap,
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
        if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
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
                if (role.isNotEmpty)
                  Text(role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
