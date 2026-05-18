import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_fab.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../oficinas/domain/oficina_model.dart';
import '../../oficinas/presentation/oficinas_notifier.dart';
import '../../veiculos/data/veiculos_remote_data_source.dart';
import '../../veiculos/domain/veiculo.dart';
import '../../veiculos/presentation/widgets/veiculo_form_dialog.dart';
import '../domain/cliente.dart';
import '../domain/veiculo_resumo.dart';
import 'clientes_notifier.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_list_tile.dart';
import 'widgets/cliente_card.dart';
import 'widgets/cliente_form_dialog.dart';

enum _Filtro { todos, comVeiculo, semVeiculo, novos }
enum _FiltroDesktop { todos, ativos, inativos, semVeiculo }
enum _Ordem { recentes, antigos, aZ, zA }

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen>
    with TopBarSlotMixin<ClientesScreen> {
  final _searchController = TextEditingController();
  _Filtro _filtro = _Filtro.todos;
  _FiltroDesktop _filtroDesktop = _FiltroDesktop.todos;
  _Ordem _ordem = _Ordem.recentes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final oficinas =
        ref.read(oficinasNotifierProvider).valueOrNull ?? <OficinaModel>[];
    final nome = oficinas
        .where((o) => o.id == authState?.oficinaId)
        .firstOrNull
        ?.nome;
    setTopBarSlot(TopBarSlot(
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      searchController: _searchController,
      searchHint: 'Buscar nome, telefone, placa…',
      onSearchChanged: _onSearch,
      mobileAction: IconButton(
        icon: const Icon(Icons.tune_outlined, color: Colors.white, size: 20),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      action: FilledButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined, size: 17),
        label: const Text('Novo cliente'),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.dispose());
  }

  void _onSearch(String value) {
    ref.read(clientesNotifierProvider.notifier).buscar(value);
  }

  Future<void> _openVeiculoForm(int clienteId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(clienteIdFixo: clienteId),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(context, 'Veículo cadastrado!');
    }
  }

  Future<void> _openEditVeiculo(VeiculoResumo resumo) async {
    Veiculo veiculo;
    try {
      veiculo =
          await ref.read(veiculosRemoteDataSourceProvider).obter(resumo.id);
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao carregar veículo.');
      return;
    }
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(veiculo: veiculo),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(context, 'Veículo atualizado!');
      ref.invalidate(clientesNotifierProvider);
    }
  }

  Future<void> _openForm({Cliente? cliente}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ClienteFormDialog(cliente: cliente),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        cliente == null ? 'Cliente criado com sucesso!' : 'Cliente atualizado!',
      );
    }
  }

  Future<void> _excluir(Cliente cliente) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir cliente',
      message:
          'Deseja excluir "${cliente.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (confirmar && mounted) {
      try {
        await ref
            .read(clientesNotifierProvider.notifier)
            .excluir(cliente.id);
        if (mounted) GamaSnackBar.success(context, 'Cliente removido.');
      } catch (e) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir cliente.');
      }
    }
  }

  List<Cliente> _aplicarFiltro(List<Cliente> lista) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return switch (_filtro) {
      _Filtro.todos       => lista,
      _Filtro.comVeiculo  => lista.where((c) => c.veiculos.isNotEmpty).toList(),
      _Filtro.semVeiculo  => lista.where((c) => c.veiculos.isEmpty).toList(),
      _Filtro.novos       => lista.where((c) => c.criadoEm.isAfter(cutoff)).toList(),
    };
  }

  List<Cliente> _aplicarFiltroDesktop(List<Cliente> lista) {
    return switch (_filtroDesktop) {
      _FiltroDesktop.todos      => lista,
      _FiltroDesktop.ativos     => lista.where((c) => c.ativo).toList(),
      _FiltroDesktop.inativos   => lista.where((c) => !c.ativo).toList(),
      _FiltroDesktop.semVeiculo => lista.where((c) => c.veiculos.isEmpty).toList(),
    };
  }

  List<Cliente> _aplicarOrdem(List<Cliente> lista) {
    final sorted = [...lista];
    switch (_ordem) {
      case _Ordem.recentes: sorted.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      case _Ordem.antigos:  sorted.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
      case _Ordem.aZ:       sorted.sort((a, b) => a.nome.compareTo(b.nome));
      case _Ordem.zA:       sorted.sort((a, b) => b.nome.compareTo(a.nome));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final todos = clientesAsync.valueOrNull ?? const [];

    ref.listen(authNotifierProvider, (_, _) { if (mounted) _syncSlot(); });
    ref.listen(oficinasNotifierProvider, (_, _) { if (mounted) _syncSlot(); });

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopFilterBar(
            filtro: _filtroDesktop,
            lista: todos,
            ordem: _ordem,
            onFiltro: (f) => setState(() => _filtroDesktop = f),
            onOrdem: (o) => setState(() => _ordem = o),
          ),
          Expanded(
            child: clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.invalidate(clientesNotifierProvider),
              ),
              data: (clientes) {
                final filtrados = _aplicarFiltroDesktop(clientes);
                final ordenados = _aplicarOrdem(filtrados);
                if (ordenados.isEmpty) return const _EmptyView();
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(clientesNotifierProvider.notifier).buscar(null),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: ordenados.length,
                    itemBuilder: (_, i) {
                      final c = ordenados[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ClienteDesktopRow(
                          cliente: c,
                          onTap: () => context.go(
                            AppRoutes.clientesDetalhe.replaceAll(':id', '${c.id}'),
                          ),
                          onEdit: () => context.go(
                            AppRoutes.clientesDetalhe.replaceAll(':id', '${c.id}'),
                          ),
                          onLongPress: () => _excluir(c),
                          onAddVeiculo: () => _openVeiculoForm(c.id),
                          onEditVeiculo: _openEditVeiculo,
                          onExcluir: () => _excluir(c),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ClienteDarkArea(
                lista: todos,
                searchController: _searchController,
                onSearch: _onSearch,
              ),
              _FiltroTabs(
                filtro: _filtro,
                lista: todos,
                onChanged: (f) => setState(() => _filtro = f),
              ),
              Expanded(
                child: clientesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    onRetry: () => ref.invalidate(clientesNotifierProvider),
                  ),
                  data: (clientes) {
                    final filtrados = _aplicarFiltro(clientes);
                    if (filtrados.isEmpty) return const _EmptyView();
                    return _ClienteMobileList(
                      lista: filtrados,
                      onTap: (c) => context.go(
                        AppRoutes.clientesDetalhe.replaceAll(':id', '${c.id}'),
                      ),
                      onDelete: _excluir,
                      onAddVeiculo: (c) => _openVeiculoForm(c.id),
                      onEditVeiculo: _openEditVeiculo,
                      onRefresh: () => ref
                          .read(clientesNotifierProvider.notifier)
                          .buscar(null),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: GamaFab(
            label: 'Novo cliente',
            icon: Icons.person_add_alt_1,
            onTap: () => _openForm(),
          ),
        ),
      ],
    );
  }
}

// ── Desktop filter bar ────────────────────────────────────────────────────────

class _DesktopFilterBar extends StatelessWidget {
  const _DesktopFilterBar({
    required this.filtro,
    required this.lista,
    required this.ordem,
    required this.onFiltro,
    required this.onOrdem,
  });
  final _FiltroDesktop filtro;
  final List<Cliente> lista;
  final _Ordem ordem;
  final ValueChanged<_FiltroDesktop> onFiltro;
  final ValueChanged<_Ordem> onOrdem;

  @override
  Widget build(BuildContext context) {
    final counts = {
      _FiltroDesktop.todos:      lista.length,
      _FiltroDesktop.ativos:     lista.where((c) => c.ativo).length,
      _FiltroDesktop.inativos:   lista.where((c) => !c.ativo).length,
      _FiltroDesktop.semVeiculo: lista.where((c) => c.veiculos.isEmpty).length,
    };
    const labels = {
      _FiltroDesktop.todos:      'Todos',
      _FiltroDesktop.ativos:     'Ativos',
      _FiltroDesktop.inativos:   'Inativos',
      _FiltroDesktop.semVeiculo: 'Sem veículo',
    };
    const ordemLabels = {
      _Ordem.recentes: 'Mais recentes',
      _Ordem.antigos:  'Mais antigos',
      _Ordem.aZ:       'A → Z',
      _Ordem.zA:       'Z → A',
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
          ...(_FiltroDesktop.values.map((f) {
            final isActive = f == filtro;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onFiltro(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? AppColors.ink : AppColors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[f]!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.ink2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${counts[f]}',
                        style: GoogleFonts.inter(
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
          })),
          const Spacer(),
          Row(
            children: [
              Text(
                'ORDENAR:',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink3,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<_Ordem>(
                  value: ordem,
                  isDense: true,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0.3,
                  ),
                  items: _Ordem.values
                      .map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(ordemLabels[o]!.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (o) { if (o != null) onOrdem(o); },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Desktop row ───────────────────────────────────────────────────────────────

class _ClienteDesktopRow extends StatelessWidget {
  const _ClienteDesktopRow({
    required this.cliente,
    this.onTap,
    this.onEdit,
    this.onLongPress,
    this.onAddVeiculo,
    this.onEditVeiculo,
    this.onExcluir,
  });
  final Cliente cliente;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddVeiculo;
  final void Function(VeiculoResumo)? onEditVeiculo;
  final VoidCallback? onExcluir;

  String get _initials {
    final parts = cliente.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return cliente.nome.substring(0, cliente.nome.length.clamp(0, 2)).toUpperCase();
  }

  String get _desde {
    final d = cliente.criadoEm;
    return 'CLIENTE · DESDE ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final veiculos = cliente.veiculos;

    return GamaListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: GamaAvatar(initials: _initials, size: 44),
      title: cliente.nome,
      subtitle: _desde,
      details: [
        if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
          GamaListDetail(icon: Icons.phone_outlined, text: cliente.telefone!),
        if (cliente.email != null && cliente.email!.isNotEmpty)
          GamaListDetail(icon: Icons.email_outlined, text: cliente.email!),
        if (cliente.cidade != null && cliente.cidade!.isNotEmpty)
          GamaListDetail(icon: Icons.location_on_outlined, text: cliente.cidade!),
      ],
      trailing: SizedBox(
        width: 280,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VEÍCULOS · ${veiculos.length}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink3,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (veiculos.isEmpty)
                    Text(
                      'Sem veículos cadastrados',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink3,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...veiculos.take(2).map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              if (v.placa != null)
                                _DesktopPlateChip(v.placa!),
                              if (v.placa != null) const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  v.modeloNome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.ink2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: AppColors.ink3,
              tooltip: 'Editar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.ink3),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'veiculo',
                  child: Row(children: [
                    const Icon(Icons.directions_car_outlined, size: 16),
                    const SizedBox(width: 8),
                    const Text('Adicionar veículo'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: AppColors.danger)),
                  ]),
                ),
              ],
              onSelected: (v) {
                if (v == 'veiculo') onAddVeiculo?.call();
                if (v == 'excluir') onExcluir?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopPlateChip extends StatelessWidget {
  const _DesktopPlateChip(this.plate);
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        plate,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

// ── Dark area: stats + search ──────────────────────────────────────────────────

class _ClienteDarkArea extends StatelessWidget {
  const _ClienteDarkArea({
    required this.lista,
    required this.searchController,
    required this.onSearch,
  });
  final List<Cliente> lista;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final ativos = lista.where((c) => c.ativo).length;
    final comVeiculo = lista.where((c) => c.veiculos.isNotEmpty).length;
    final now = DateTime.now();
    final novos = lista
        .where((c) =>
            c.criadoEm.month == now.month && c.criadoEm.year == now.year)
        .length;

    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatBox(value: '$ativos', label: 'ATIVOS'),
              _StatBox(value: '$comVeiculo', label: 'COM VEÍCULO', accent: true),
              _StatBox(value: '$novos', label: 'NOVOS/MÊS'),
              const _StatBox(value: '—', label: 'TICKET MÉD'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
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
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar nome, telefone, placa…',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.sidebarText),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
                const Icon(Icons.mic_none_outlined,
                    size: 17, color: AppColors.sidebarText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    this.accent = false,
  });
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent ? AppColors.accent : Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.sidebarText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter tabs ────────────────────────────────────────────────────────────────

class _FiltroTabs extends StatelessWidget {
  const _FiltroTabs({
    required this.filtro,
    required this.lista,
    required this.onChanged,
  });
  final _Filtro filtro;
  final List<Cliente> lista;
  final ValueChanged<_Filtro> onChanged;

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final counts = {
      _Filtro.todos:      lista.length,
      _Filtro.comVeiculo: lista.where((c) => c.veiculos.isNotEmpty).length,
      _Filtro.semVeiculo: lista.where((c) => c.veiculos.isEmpty).length,
      _Filtro.novos:      lista.where((c) => c.criadoEm.isAfter(cutoff)).length,
    };
    const labels = {
      _Filtro.todos:      'Todos',
      _Filtro.comVeiculo: 'Com veículo',
      _Filtro.semVeiculo: 'Sem veículo',
      _Filtro.novos:      'Novos',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.ink2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${counts[f]}',
                        style: GoogleFonts.inter(
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

// ── Mobile alphabetical list ───────────────────────────────────────────────────

class _ClienteMobileList extends StatelessWidget {
  const _ClienteMobileList({
    required this.lista,
    required this.onTap,
    required this.onDelete,
    required this.onAddVeiculo,
    required this.onEditVeiculo,
    required this.onRefresh,
  });
  final List<Cliente> lista;
  final ValueChanged<Cliente> onTap;
  final Future<void> Function(Cliente) onDelete;
  final ValueChanged<Cliente> onAddVeiculo;
  final void Function(VeiculoResumo) onEditVeiculo;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final sorted = [...lista]..sort((a, b) => a.nome.compareTo(b.nome));

    final groups = <String, List<Cliente>>{};
    for (final c in sorted) {
      final letter = c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '#';
      groups.putIfAbsent(letter, () => []).add(c);
    }

    final items = <({String? header, Cliente? cliente, int? count})>[];
    for (final e in groups.entries) {
      items.add((header: e.key, cliente: null, count: e.value.length));
      for (final c in e.value) {
        items.add((header: null, cliente: c, count: null));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item.header != null) {
            return _AlphaHeader(letter: item.header!, count: item.count!);
          }
          final c = item.cliente!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClienteCard(
              cliente: c,
              onTap: () => onTap(c),
              onLongPress: () => onDelete(c),
              onAddVeiculo: () => onAddVeiculo(c),
              onEditVeiculo: onEditVeiculo,
            ),
          );
        },
      ),
    );
  }
}

class _AlphaHeader extends StatelessWidget {
  const _AlphaHeader({required this.letter, required this.count});
  final String letter;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Text(
            letter,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 56, color: AppColors.ink3),
            const SizedBox(height: 12),
            Text('Nenhum cliente encontrado',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink2)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
            const SizedBox(height: 12),
            Text('Erro ao carregar clientes',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink2)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
}
