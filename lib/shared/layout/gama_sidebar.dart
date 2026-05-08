import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../widgets/gama_avatar.dart';
import '../widgets/gama_snack_bar.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final section in _sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      section.label,
                      style: const TextStyle(
                        fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  int? _loadingId;

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  void _hide() {
    _overlay?.remove();
    _overlay = null;
  }

  void _show() {
    _overlay = OverlayEntry(builder: (_) => _DropdownOverlay(
      layerLink: _layerLink,
      groups: widget.groups,
      currentGroupId: widget.currentGroupId,
      loadingId: _loadingId,
      onSelect: _switchGroup,
      onDismiss: _hide,
    ));
    Overlay.of(context).insert(_overlay!);
  }

  Future<void> _switchGroup(int grupoId) async {
    if (grupoId == widget.currentGroupId) {
      _hide();
      return;
    }
    setState(() => _loadingId = grupoId);
    _overlay?.markNeedsBuild();
    try {
      await ref.read(authNotifierProvider.notifier).selectGroup(grupoId);
      if (mounted) _hide();
    } catch (e) {
      if (mounted) {
        _hide();
        GamaSnackBar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _show,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
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
                        fontSize: 13,
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
              const Icon(Icons.expand_more, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownOverlay extends StatelessWidget {
  const _DropdownOverlay({
    required this.layerLink,
    required this.groups,
    required this.currentGroupId,
    required this.loadingId,
    required this.onSelect,
    required this.onDismiss,
  });

  final LayerLink layerLink;
  final List<GrupoItem> groups;
  final int? currentGroupId;
  final int? loadingId;
  final void Function(int) onSelect;
  final VoidCallback onDismiss;

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nome.substring(0, nome.length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: Container(
              width: 216,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(
                      'SUAS OFICINAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final g in groups)
                    _DropdownItem(
                      initials: _initials(g.nome),
                      nome: g.nome,
                      isCurrent: g.id == currentGroupId,
                      isLoading: loadingId == g.id,
                      isDisabled: loadingId != null,
                      onTap: () => onSelect(g.id),
                    ),
                  const Divider(height: 1),
                  _DropdownAction(
                    icon: Icons.settings_outlined,
                    label: 'Gerenciar oficinas',
                    color: AppColors.textSecondary,
                    isLast: true,
                    onTap: () {
                      onDismiss();
                      context.go('/gerenciar-oficinas');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownItem extends StatelessWidget {
  const _DropdownItem({
    required this.initials,
    required this.nome,
    required this.isCurrent,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final String initials;
  final String nome;
  final bool isCurrent;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GamaAvatar(initials: initials, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nome,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isCurrent)
              const Icon(Icons.check, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _DropdownAction extends StatelessWidget {
  const _DropdownAction({
    required this.icon,
    required this.label,
    required this.color,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(12))
          : BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ],
          ),
        ),
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
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
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
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
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
                    fontSize: 14,
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
