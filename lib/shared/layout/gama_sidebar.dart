import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../utils/data_refresh.dart';
import '../widgets/gama_avatar.dart';
import '../widgets/gama_logo.dart';
import '../widgets/gama_snack_bar.dart';

class GamaSidebar extends ConsumerWidget {
  const GamaSidebar({super.key, this.collapsed = false, this.onToggle});

  final bool collapsed;
  final VoidCallback? onToggle;

  static List<_NavSection> _buildSections(bool isGestor) => [
    const _NavSection('Principal', [
      _NavItem('Painel',            Icons.space_dashboard_outlined,   '/home'),
      _NavItem('Ordens de Serviço', Icons.receipt_long_outlined,      '/ordens-servico'),
      _NavItem('Clientes',          Icons.groups_outlined,            '/clientes'),
      _NavItem('Veículos',          Icons.directions_car_outlined,    '/veiculos'),
    ]),
    _NavSection('Operação', [
      const _NavItem('Estoque',      Icons.inventory_2_outlined,    '/estoque'),
      const _NavItem('Fornecedores', Icons.local_shipping_outlined, '/fornecedores'),
      const _NavItem('Pagamentos',   Icons.payments_outlined,       '/pagamentos'),
      if (isGestor) const _NavItem('Funcionários', Icons.badge_outlined,       '/funcionarios'),
      if (isGestor) const _NavItem('Receitas',     Icons.trending_up_outlined, '/receitas'),
      if (isGestor) const _NavItem('Assinatura',   Icons.workspace_premium_outlined, '/assinatura'),
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
    final adminMode = token.isNotEmpty && JwtDecoder.isAdmin(token);
    final isGestor = token.isNotEmpty && JwtDecoder.isGestor(token);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: const Border(
          right: BorderSide(color: AppColors.sidebarLine),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(collapsed: collapsed, onToggle: onToggle),
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
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 10),
              children: [
                for (final section in _buildSections(isGestor)) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                      child: Text(
                        section.label.toUpperCase(),
                        style: TextStyle(fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sidebarText.withValues(alpha: 0.5),
                          letterSpacing: 1.2,
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
                if (adminMode) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                      child: Text(
                        'SISTEMA',
                        style: TextStyle(fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  _SidebarNavItem(
                    item: const _NavItem('Admin', Icons.shield_outlined, '/admin'),
                    isActive: currentRoute.startsWith('/admin'),
                    collapsed: collapsed,
                  ),
                ],
              ],
            ),
          ),
          if (isGestor) ...[
            Container(
              height: 1,
              color: AppColors.sidebarLine,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 10, vertical: 8),
              child: _SidebarNavItem(
                item: const _NavItem('Configurações', Icons.settings_outlined, '/configuracoes-oficina'),
                isActive: currentRoute.startsWith('/configuracoes-oficina'),
                collapsed: collapsed,
              ),
            ),
          ],
          Container(height: 1, color: AppColors.sidebarLine),
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
  const _Logo({required this.collapsed, this.onToggle});
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        collapsed ? 0 : 20, 20, collapsed ? 0 : 20, 16,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sidebarLine)),
      ),
      child: collapsed
          ? Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onToggle,
                  child: GamaLogoMark(size: 34, radius: 8),
                ),
              ),
            )
          : Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icon/icon_windows.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAMA',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'oficina · v1.0',
                      style: TextStyle(fontFamily: 'JetBrains Mono', 
                        fontSize: 9,
                        color: AppColors.sidebarText,
                        letterSpacing: 1,
                      ),
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
      invalidateAllData(ref);
      if (mounted) {
        _hide();
        context.go('/home');
      }
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: CompositedTransformTarget(
          link: _layerLink,
          child: Tooltip(
            message: widget.name,
            child: InkWell(
              onTap: _show,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF26221D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.sidebarLine),
          ),
          child: Row(
            children: [
              GamaAvatar(initials: widget.initials, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.oficinaNome ?? 'PLANO PRO',
                      style: TextStyle(fontFamily: 'JetBrains Mono', 
                        fontSize: 9,
                        color: AppColors.accent,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.unfold_more, size: 16, color: AppColors.sidebarText),
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
            borderRadius: BorderRadius.circular(10),
            shadowColor: Colors.black26,
            child: Container(
              width: 232,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
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
                    if (oficinas.isNotEmpty)
                      Container(height: 1, color: AppColors.line),
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
                    Container(height: 1, color: AppColors.line),
                    _DropdownAction(
                      icon: Icons.settings_outlined,
                      label: 'Gerenciar oficinas',
                      color: AppColors.ink2,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'JetBrains Mono', 
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.ink3,
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
            GamaAvatar(initials: initials, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nome,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
              )
            else if (isCurrent)
              const Icon(Icons.check, size: 16, color: AppColors.accent),
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
          ? const BorderRadius.vertical(bottom: Radius.circular(10))
          : BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: color),
              ),
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
      color: isActive ? const Color(0xFF1A1714) : AppColors.sidebarText,
    );

    final tile = InkWell(
      onTap: () {
        if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
        context.go(item.route);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 10,
          vertical: 9,
        ),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: collapsed
            ? Center(child: icon)
            : Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? const Color(0xFF1A1714) : AppColors.sidebarText,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (collapsed) {
      return _CollapsedHoverLabel(label: item.label, child: tile);
    }
    return tile;
  }
}

class _CollapsedHoverLabel extends StatefulWidget {
  const _CollapsedHoverLabel({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  State<_CollapsedHoverLabel> createState() => _CollapsedHoverLabelState();
}

class _CollapsedHoverLabelState extends State<_CollapsedHoverLabel> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _controller.show(),
        onExit: (_) => _controller.hide(),
        child: OverlayPortal(
          controller: _controller,
          overlayChildBuilder: (_) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.centerRight,
            followerAnchor: Alignment.centerLeft,
            offset: const Offset(6, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.sidebarLine),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0))],
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.sidebarText,
                  ),
                ),
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          GamaAvatar(initials: initials, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty)
                  Text(
                    role,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.sidebarText),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 16),
            color: AppColors.sidebarText,
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
