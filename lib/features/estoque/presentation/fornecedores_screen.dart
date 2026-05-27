import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_fab.dart';
import '../../../shared/widgets/gama_list_tile.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/estoque.dart';
import 'fornecedores_notifier.dart';

enum _Filtro { todos, comEmail, comTelefone, semContato }

class FornecedoresScreen extends ConsumerStatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  ConsumerState<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends ConsumerState<FornecedoresScreen>
    with TopBarSlotMixin<FornecedoresScreen> {
  final _searchController = TextEditingController();
  _Filtro _filtro = _Filtro.todos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final nome = oficinas
        .where((o) => o.id == auth?.oficinaId)
        .map((o) => o.nome)
        .firstOrNull;
    setTopBarSlot(TopBarSlot(
      pageTitle: 'Fornecedores',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      searchController: _searchController,
      searchHint: 'Buscar por nome, e-mail ou telefone…',
      onSearchChanged: (v) =>
          ref.read(fornecedoresNotifierProvider.notifier).buscar(v),
      mobileAction: const SizedBox(),
      action: FilledButton.icon(
        onPressed: _openForm,
        icon: const Icon(Icons.add, size: 17),
        label: const Text('Novo fornecedor'),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.dispose());
  }

  Future<void> _openForm({FornecedorEstoque? fornecedor}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FornecedorFormDialog(fornecedor: fornecedor),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        fornecedor == null ? 'Fornecedor criado!' : 'Fornecedor atualizado!',
      );
    }
  }

  Future<void> _excluir(FornecedorEstoque f) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir fornecedor',
      message:
          'Deseja excluir "${f.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.danger,
    );
    if (ok && mounted) {
      try {
        await ref.read(fornecedoresNotifierProvider.notifier).excluir(f.id);
        if (mounted) GamaSnackBar.success(context, 'Fornecedor removido.');
      } catch (_) {
        if (mounted) {
          GamaSnackBar.error(context, 'Erro ao excluir fornecedor.');
        }
      }
    }
  }

  List<FornecedorEstoque> _aplicarFiltro(List<FornecedorEstoque> lista) {
    bool hasEmail(FornecedorEstoque f) => f.email != null && f.email!.isNotEmpty;
    bool hasTel(FornecedorEstoque f) => f.telefone != null && f.telefone!.isNotEmpty;
    return switch (_filtro) {
      _Filtro.todos       => lista,
      _Filtro.comEmail    => lista.where(hasEmail).toList(),
      _Filtro.comTelefone => lista.where(hasTel).toList(),
      _Filtro.semContato  =>
          lista.where((f) => !hasEmail(f) && !hasTel(f)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(fornecedoresNotifierProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
            const SizedBox(height: 12),
            const Text('Erro ao carregar fornecedores',
                style: TextStyle(color: AppColors.ink2)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(fornecedoresNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (lista) => isDesktop
          ? _buildDesktop(lista)
          : _buildMobile(lista),
    );
  }

  Widget _buildDesktop(List<FornecedorEstoque> lista) {
    final filtrados = _aplicarFiltro(lista);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(
          filtro: _filtro,
          lista: lista,
          onFiltro: (f) => setState(() => _filtro = f),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? _EmptyView(hasItems: lista.isNotEmpty, onAdd: _openForm)
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(fornecedoresNotifierProvider.notifier)
                      .buscar(_searchController.text.isEmpty
                          ? null
                          : _searchController.text),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) {
                      final f = filtrados[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FornecedorRow(
                          fornecedor: f,
                          onEdit: () => _openForm(fornecedor: f),
                          onDelete: () => _excluir(f),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMobile(List<FornecedorEstoque> lista) {
    final filtrados = _aplicarFiltro(lista);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FornecedorDarkArea(
                searchController: _searchController,
                onSearch: (v) =>
                    ref.read(fornecedoresNotifierProvider.notifier).buscar(v),
              ),
              _MobileFiltroTabs(
                filtro: _filtro,
                lista: lista,
                onChanged: (f) => setState(() => _filtro = f),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? _EmptyView(hasItems: lista.isNotEmpty, onAdd: _openForm)
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(fornecedoresNotifierProvider.notifier)
                            .buscar(_searchController.text.isEmpty
                                ? null
                                : _searchController.text),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) => _FornecedorMobileCard(
                            fornecedor: filtrados[i],
                            onEdit: () => _openForm(fornecedor: filtrados[i]),
                            onDelete: () => _excluir(filtrados[i]),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
          child: GamaFab(
            label: 'Novo fornecedor',
            icon: Icons.local_shipping_outlined,
            onTap: _openForm,
          ),
        ),
      ],
    );
  }
}

// ── filter bar ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filtro,
    required this.lista,
    required this.onFiltro,
  });

  final _Filtro filtro;
  final List<FornecedorEstoque> lista;
  final ValueChanged<_Filtro> onFiltro;

  @override
  Widget build(BuildContext context) {
    bool hasEmail(FornecedorEstoque f) => f.email != null && f.email!.isNotEmpty;
    bool hasTel(FornecedorEstoque f) => f.telefone != null && f.telefone!.isNotEmpty;

    final counts = {
      _Filtro.todos:       lista.length,
      _Filtro.comEmail:    lista.where(hasEmail).length,
      _Filtro.comTelefone: lista.where(hasTel).length,
      _Filtro.semContato:
          lista.where((f) => !hasEmail(f) && !hasTel(f)).length,
    };
    const labels = {
      _Filtro.todos:       'Todos',
      _Filtro.comEmail:    'Com e-mail',
      _Filtro.comTelefone: 'Com telefone',
      _Filtro.semContato:  'Sem contato',
    };

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ..._Filtro.values.map((f) {
            final isActive = f == filtro;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onFiltro(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isActive ? AppColors.ink : AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[f]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive ? Colors.white : AppColors.ink2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${counts[f]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white70
                              : AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Text(
            '${lista.length} fornecedor${lista.length != 1 ? 'es' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}

// ── fornecedor row ─────────────────────────────────────────────────────────────

class _FornecedorRow extends StatelessWidget {
  const _FornecedorRow({
    required this.fornecedor,
    required this.onEdit,
    required this.onDelete,
  });

  final FornecedorEstoque fornecedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _initials {
    final parts = fornecedor.nome.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fornecedor.nome
        .substring(0, fornecedor.nome.length.clamp(0, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final semContato = (fornecedor.email == null || fornecedor.email!.isEmpty) &&
        (fornecedor.telefone == null || fornecedor.telefone!.isEmpty);

    return GamaListTile(
      onTap: onEdit,
      leading: GamaAvatar(initials: _initials, size: 44),
      title: fornecedor.nome,
      subtitle: 'FORNECEDOR',
      details: [
        if (fornecedor.email != null && fornecedor.email!.isNotEmpty)
          GamaListDetail(
              icon: Icons.email_outlined, text: fornecedor.email!),
        if (fornecedor.telefone != null && fornecedor.telefone!.isNotEmpty)
          GamaListDetail(
              icon: Icons.phone_outlined, text: fornecedor.telefone!),
        if (semContato)
          const GamaListDetail(
              icon: Icons.remove_circle_outline,
              text: 'Sem contato cadastrado'),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppColors.ink3,
            tooltip: 'Editar',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz,
                size: 18, color: AppColors.ink3),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'excluir',
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text('Excluir',
                      style: TextStyle(color: AppColors.danger)),
                ]),
              ),
            ],
            onSelected: (v) {
              if (v == 'excluir') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ── empty view ─────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasItems, required this.onAdd});
  final bool hasItems;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping_outlined,
              size: 56, color: AppColors.ink3),
          const SizedBox(height: 12),
          Text(
            hasItems
                ? 'Nenhum resultado neste filtro'
                : 'Nenhum fornecedor cadastrado',
            style: const TextStyle(fontSize: 15, color: AppColors.ink2),
          ),
          if (!hasItems) ...[
            const SizedBox(height: 8),
            const Text(
              'Adicione o primeiro fornecedor',
              style: TextStyle(fontSize: 13, color: AppColors.ink3),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Novo fornecedor'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── mobile dark area ───────────────────────────────────────────────────────────

class _FornecedorDarkArea extends StatelessWidget {
  const _FornecedorDarkArea({
    required this.searchController,
    required this.onSearch,
  });
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.sidebarLine,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 17, color: AppColors.sidebarText),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome, e-mail ou telefone…',
                  hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.sidebarText),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── mobile filter tabs ─────────────────────────────────────────────────────────

class _MobileFiltroTabs extends StatelessWidget {
  const _MobileFiltroTabs({
    required this.filtro,
    required this.lista,
    required this.onChanged,
  });
  final _Filtro filtro;
  final List<FornecedorEstoque> lista;
  final ValueChanged<_Filtro> onChanged;

  @override
  Widget build(BuildContext context) {
    bool hasEmail(FornecedorEstoque f) => f.email != null && f.email!.isNotEmpty;
    bool hasTel(FornecedorEstoque f) => f.telefone != null && f.telefone!.isNotEmpty;

    final counts = {
      _Filtro.todos:       lista.length,
      _Filtro.comEmail:    lista.where(hasEmail).length,
      _Filtro.comTelefone: lista.where(hasTel).length,
      _Filtro.semContato:  lista.where((f) => !hasEmail(f) && !hasTel(f)).length,
    };
    const labels = {
      _Filtro.todos:       'Todos',
      _Filtro.comEmail:    'Com e-mail',
      _Filtro.comTelefone: 'Com telefone',
      _Filtro.semContato:  'Sem contato',
    };

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _Filtro.values.map((f) {
            final isActive = f == filtro;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: isActive ? AppColors.ink : AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[f]!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.ink2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${counts[f]}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white70 : AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── mobile card ────────────────────────────────────────────────────────────────

class _FornecedorMobileCard extends StatelessWidget {
  const _FornecedorMobileCard({
    required this.fornecedor,
    required this.onEdit,
    required this.onDelete,
  });
  final FornecedorEstoque fornecedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _initials {
    final parts = fornecedor.nome.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fornecedor.nome
        .substring(0, fornecedor.nome.length.clamp(0, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail =
        fornecedor.email != null && fornecedor.email!.isNotEmpty;
    final hasTel =
        fornecedor.telefone != null && fornecedor.telefone!.isNotEmpty;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            GamaAvatar(initials: _initials, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedor.nome,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (hasEmail || hasTel) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (hasEmail) ...[
                          const Icon(Icons.email_outlined,
                              size: 11, color: AppColors.ink3),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              fornecedor.email!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.ink2),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (hasEmail && hasTel)
                          const Text('  ·  ',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.ink3)),
                        if (hasTel) ...[
                          const Icon(Icons.phone_outlined,
                              size: 11, color: AppColors.ink3),
                          const SizedBox(width: 3),
                          Text(
                            fornecedor.telefone!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.ink2),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 3),
                    const Text(
                      'Sem contato cadastrado',
                      style: TextStyle(fontSize: 11, color: AppColors.ink3),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.ink3),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.ink2),
                    const SizedBox(width: 8),
                    const Text('Editar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: Row(children: [
                    Icon(Icons.delete_outline,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Excluir',
                        style: TextStyle(color: AppColors.danger)),
                  ]),
                ),
              ],
              onSelected: (v) {
                if (v == 'editar') onEdit();
                if (v == 'excluir') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── form dialog ────────────────────────────────────────────────────────────────

class _FornecedorFormDialog extends ConsumerStatefulWidget {
  const _FornecedorFormDialog({this.fornecedor});
  final FornecedorEstoque? fornecedor;

  @override
  ConsumerState<_FornecedorFormDialog> createState() =>
      _FornecedorFormDialogState();
}

class _FornecedorFormDialogState
    extends ConsumerState<_FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl =
      TextEditingController(text: widget.fornecedor?.nome ?? '');
  late final _telCtrl =
      TextEditingController(text: widget.fornecedor?.telefone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.fornecedor?.email ?? '');
  bool _loading = false;

  bool get _isEdit => widget.fornecedor != null;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(fornecedoresNotifierProvider.notifier);
      if (!_isEdit) {
        await notifier.criar(
          nome: _nomeCtrl.text.trim(),
          telefone: _telCtrl.text.trim().isEmpty
              ? null
              : _telCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
        );
      } else {
        await notifier.atualizar(
          id: widget.fornecedor!.id,
          nome: _nomeCtrl.text.trim(),
          telefone: _telCtrl.text.trim().isEmpty
              ? null
              : _telCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        GamaSnackBar.error(context, 'Erro ao salvar fornecedor.');
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEdit
                          ? 'Editar fornecedor'
                          : 'Novo fornecedor',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.ink2,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _campo(_nomeCtrl, 'Nome *',
                    obrigatorio: true,
                    caps: TextCapitalization.words),
                const SizedBox(height: 12),
                _campo(_telCtrl, 'Telefone',
                    teclado: TextInputType.phone),
                const SizedBox(height: 12),
                _campo(_emailCtrl, 'E-mail',
                    teclado: TextInputType.emailAddress),
                const SizedBox(height: 24),
                GamaButton(
                  label: _isEdit
                      ? 'Salvar alterações'
                      : 'Criar fornecedor',
                  onPressed: _submit,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    bool obrigatorio = false,
    TextInputType teclado = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      textCapitalization: caps,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.ink2, fontSize: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.accent, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColors.surface,
      ),
      validator: obrigatorio
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'Campo obrigatório'
              : null
          : null,
    );
  }
}
