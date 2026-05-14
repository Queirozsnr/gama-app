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
  const GamaSidebar({super.key, this.collapsed = false});

  final bool collapsed;

  static const _sections = [
    _NavSection('Principal', [
      _NavItem('Dashboard',         Icons.dashboard_outlined,      '/home'),
      _NavItem('Ordens de Serviço', Icons.receipt_long_outlined,   '/ordens-servico'),
      _NavItem('Clientes',          Icons.people_outline,          '/clientes'),
      _NavItem('Veículos',          Icons.directions_car_outlined, '/veiculos'),
    ]),
    _NavSection('Operação', [
      _NavItem('Estoque',       Icons.inventory_2_outlined,  '/estoque'),
      _NavItem('Fornecedores',  Icons.local_shipping_outlined, '/fornecedores'),
      _NavItem('Funcionários',  Icons.badge_outlined,        '/funcionarios'),
      _NavItem('Pagamentos',    Icons.payments_outlined,     '/pagamentos'),
      _NavItem('Receitas',      Icons.trending_up_outlined,  '/receitas'),
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

    final oficinas = auth?.availableOficinas ?? [];
    final currentOficinaId = auth?.oficinaId;
    final currentOficina = oficinas.cast<OficinaItem?>().firstWhere(
      (o) => o?.id == currentOficinaId,
      orElse: () => null,
    );
    final oficinaNome = currentOficina?.nome;

    final token = auth?.token ?? '';
    final userName = token.isNotEmpty ? (JwtDecoder.nome(token) ?? 'Usuário') : 'Usuário';
    final userCargo = token.isNotEmpty ? (JwtDecoder.cargoLabel(token) ?? '') : '';
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
          _Logo(collapsed: collapsed),
          _GroupCard(
            initials: groupInitials,
            name: groupName,
            oficinaNome: oficinaNome,
            groups: groups,
            currentGroupId: currentGroupId,
            oficinas: oficinas,
            currentOficinaId: currentOficinaId,
            collapsed: collapsed,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 14),
              children: [
                for (final section in _sections) ...[
                  if (!collapsed)
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
                    )
                  else
                    const SizedBox(height: 12),
                  for (final item in section.items)
                    _SidebarNavItem(
                      item: item,
                      isActive: currentRoute.startsWith(item.route) ||
                          (item.route == '/home' && currentRoute == '/'),
                      collapsed: collapsed,
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 14, vertical: 8),
            child: Column(
              children: [
                _SidebarNavItem(
                  item: const _NavItem('Ajuda', Icons.help_outline, '/ajuda'),
                  isActive: false,
                  collapsed: collapsed,
                ),
                _SidebarNavItem(
                  item: const _NavItem('Configurações', Icons.settings_outlined, '/configuracoes'),
                  isActive: false,
                  collapsed: collapsed,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _UserProfile(
            initials: userInitials,
            name: userName,
            role: userCargo,
            collapsed: collapsed,
          ),
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
  const _Logo({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(collapsed ? 0 : 16, 20, collapsed ? 0 : 16, 12),
      child: collapsed
          ? Center(
              child: Container(
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
            )
          : Row(
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
    required this.oficinas,
    required this.collapsed,
    this.oficinaNome,
    this.currentGroupId,
    this.currentOficinaId,
  });

  final String initials;
  final String name;
  final String? oficinaNome;
  final List<GrupoItem> groups;
  final List<OficinaItem> oficinas;
  final int? currentGroupId;
  final int? currentOficinaId;
  final bool collapsed;

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  int? _loadingGrupoId;
  int? _loadingOficinaId;

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
    final token = ref.read(authNotifierProvider).valueOrNull?.token ?? '';
    final isGestor = token.isNotEmpty && JwtDecoder.permissaoGerenciarOficinas(token);

    _overlay = OverlayEntry(builder: (_) => _DropdownOverlay(
      layerLink: _layerLink,
      groups: widget.groups,
      oficinas: widget.oficinas,
      currentGroupId: widget.currentGroupId,
      currentOficinaId: widget.currentOficinaId,
      loadingGrupoId: _loadingGrupoId,
      loadingOficinaId: _loadingOficinaId,
      showGerenciar: isGestor,
      onSelectGrupo: _switchGroup,
      onSelectOficina: _switchOficina,
      onDismiss: _hide,
    ));
    Overlay.of(context).insert(_overlay!);
  }

  Future<void> _switchGroup(int grupoId) async {
    if (grupoId == widget.currentGroupId) { _hide(); return; }
    setState(() => _loadingGrupoId = grupoId);
    _overlay?.markNeedsBuild();
    try {
      await ref.read(authNotifierProvider.notifier).selectGroup(grupoId);
      if (mounted) _hide();
    } catch (e) {
      if (mounted) { _hide(); GamaSnackBar.error(context, e.toString()); }
    } finally {
      if (mounted) setState(() => _loadingGrupoId = null);
    }
  }

  Future<void> _switchOficina(int oficinaId) async {
    if (oficinaId == widget.currentOficinaId) { _hide(); return; }
    setState(() => _loadingOficinaId = oficinaId);
    _overlay?.markNeedsBuild();
    try {
      await ref.read(authNotifierProvider.notifier).selectOficina(oficinaId);
      if (mounted) _hide();
    } catch (e) {
      if (mounted) { _hide(); GamaSnackBar.error(context, e.toString()); }
    } finally {
      if (mounted) setState(() => _loadingOficinaId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: Tooltip(
            message: widget.name,
            child: InkWell(
              onTap: _show,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(child: GamaAvatar(initials: widget.initials, size: 32)),
              ),
            ),
          ),
        ),
      );
    }

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
                    Text(
                      widget.oficinaNome ?? 'PLANO PRO',
                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
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
    required this.oficinas,
    required this.currentGroupId,
    required this.currentOficinaId,
    required this.loadingGrupoId,
    required this.loadingOficinaId,
    required this.showGerenciar,
    required this.onSelectGrupo,
    required this.onSelectOficina,
    required this.onDismiss,
  });

  final LayerLink layerLink;
  final List<GrupoItem> groups;
  final List<OficinaItem> oficinas;
  final int? currentGroupId;
  final int? currentOficinaId;
  final int? loadingGrupoId;
  final int? loadingOficinaId;
  final bool showGerenciar;
  final void Function(int) onSelectGrupo;
  final void Function(int) onSelectOficina;
  final VoidCallback onDismiss;

  static String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nome.substring(0, nome.length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    final anyLoading = loadingGrupoId != null || loadingOficinaId != null;

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
              width: 232,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (oficinas.isNotEmpty) ...[
                    _SectionLabel('UNIDADES'),
                    for (final o in oficinas)
                      _DropdownItem(
                        initials: _initials(o.nome),
                        nome: o.nome,
                        isCurrent: o.id == currentOficinaId,
                        isLoading: loadingOficinaId == o.id,
                        isDisabled: anyLoading,
                        onTap: () => onSelectOficina(o.id),
                      ),
                  ],
                  if (groups.length > 1) ...[
                    if (oficinas.isNotEmpty) const Divider(height: 1),
                    _SectionLabel('GRUPOS'),
                    for (final g in groups)
                      _DropdownItem(
                        initials: _initials(g.nome),
                        nome: g.nome,
                        isCurrent: g.id == currentGroupId,
                        isLoading: loadingGrupoId == g.id,
                        isDisabled: anyLoading,
                        onTap: () => onSelectGrupo(g.id),
                      ),
                  ],
                  if (showGerenciar) ...[
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
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
              Text(label, style: TextStyle(fontSize: 13, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.collapsed,
  });

  final _NavItem item;
  final bool isActive;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      item.icon,
      size: 20,
      color: isActive ? AppColors.primary : AppColors.textSecondary,
    );

    final tile = InkWell(
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
        context.go(item.route);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: collapsed
            ? Center(child: icon)
            : Row(
                children: [
                  icon,
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

    if (collapsed) {
      return Tooltip(message: item.label, preferBelow: false, child: tile);
    }
    return tile;
  }
}

class _UserProfile extends ConsumerWidget {
  const _UserProfile({
    required this.initials,
    required this.name,
    required this.role,
    required this.collapsed,
  });

  final String initials;
  final String name;
  final String role;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
        child: Tooltip(
          message: '$name${role.isNotEmpty ? ' · $role' : ''}',
          child: Center(child: GamaAvatar(initials: initials, size: 36)),
        ),
      );
    }

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
          IconButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Sair',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
