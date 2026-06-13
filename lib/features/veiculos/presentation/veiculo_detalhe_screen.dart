import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../ordens_servico/data/ordens_servico_remote_data_source.dart';
import '../../ordens_servico/domain/ordem_servico.dart';
import '../data/veiculos_remote_data_source.dart';
import '../domain/veiculo.dart';
import 'widgets/veiculo_form_dialog.dart';

final _veiculoDetalheProvider =
    FutureProvider.autoDispose.family<Veiculo, int>((ref, id) {
  return ref.read(veiculosRemoteDataSourceProvider).obter(id);
});

final _veiculoOsProvider =
    FutureProvider.autoDispose.family<List<OrdemServico>, int>((ref, veiculoId) async {
  final result = await ref
      .read(ordensServicoRemoteDataSourceProvider)
      .listar(veiculoId: veiculoId);
  return result.items;
});

class VeiculoDetalheScreen extends ConsumerStatefulWidget {
  const VeiculoDetalheScreen({super.key, required this.veiculoId});
  final int veiculoId;

  @override
  ConsumerState<VeiculoDetalheScreen> createState() =>
      _VeiculoDetalheScreenState();
}

class _VeiculoDetalheScreenState extends ConsumerState<VeiculoDetalheScreen>
    with TopBarSlotMixin<VeiculoDetalheScreen>, TickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot([Veiculo? v]) {
    setTopBarSlot(TopBarSlot(
      pageTitle: v != null ? '${v.marcaNome} ${v.modeloNome}' : 'Ficha do veículo',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: 'VEÍCULO',
      mobileAction: v == null
          ? null
          : IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () => _showMobileMenu(v),
            ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.veiculos),
        tooltip: 'Voltar',
      ),
      action: v == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editar(v),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _novaOs(v),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nova OS pra este veículo'),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'excluir',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Text('Excluir veículo', style: TextStyle(color: AppColors.danger)),
                      ]),
                    ),
                  ],
                  onSelected: (val) { if (val == 'excluir') _excluir(v); },
                ),
              ],
            ),
    ));
  }

  void _showMobileMenu(Veiculo v) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar veículo'),
              onTap: () {
                Navigator.pop(ctx);
                _editar(v);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('Excluir veículo', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _excluir(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _excluir(Veiculo v) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir veículo',
      message: 'Deseja excluir ${v.placa ?? '${v.marcaNome} ${v.modeloNome}'}? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.danger,
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref.read(veiculosRemoteDataSourceProvider).excluir(v.id);
      if (mounted) {
        GamaSnackBar.success(context, 'Veículo excluído.');
        context.canPop() ? context.pop() : context.go(AppRoutes.veiculos);
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _mensagemErro(e));
    }
  }

  String _mensagemErro(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return 'Erro ao excluir veículo.';
  }

  Future<void> _editar(Veiculo v) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(veiculo: v),
    );
    if (result == true && mounted) {
      ref.invalidate(_veiculoDetalheProvider(widget.veiculoId));
    }
  }

  void _novaOs(Veiculo v) =>
      context.go(AppRoutes.ordensServicoNova, extra: v.clienteId);

  Future<void> _atualizarKm(Veiculo v) async {
    final ctrl = TextEditingController(text: v.quilometragem?.toString() ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atualizar hodômetro'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quilometragem (km)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (saved == null || saved.isEmpty || !mounted) return;
    final km = int.tryParse(saved);
    if (km == null) return;
    try {
      await ref.read(veiculosRemoteDataSourceProvider).atualizar(v.id, {
        'clienteId': v.clienteId,
        'modeloId': v.modeloId,
        'placa': v.placa,
        'ano': v.ano,
        'cor': v.cor,
        'combustivel': v.combustivel,
        'quilometragem': km,
        'observacoes': v.observacoes,
        'ativo': v.ativo,
      });
      ref.invalidate(_veiculoDetalheProvider(widget.veiculoId));
      if (mounted) GamaSnackBar.success(context, 'Hodômetro atualizado!');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao atualizar hodômetro.');
    }
  }

  Future<void> _editarNotas(Veiculo v) async {
    final ctrl = TextEditingController(text: v.observacoes ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notas técnicas'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Observações técnicas do veículo…',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (saved == null || !mounted) return;
    try {
      await ref.read(veiculosRemoteDataSourceProvider).atualizar(v.id, {
        'clienteId': v.clienteId,
        'modeloId': v.modeloId,
        'placa': v.placa,
        'ano': v.ano,
        'cor': v.cor,
        'combustivel': v.combustivel,
        'quilometragem': v.quilometragem,
        'observacoes': saved.isEmpty ? null : saved,
        'ativo': v.ativo,
      });
      ref.invalidate(_veiculoDetalheProvider(widget.veiculoId));
      if (mounted) GamaSnackBar.success(context, 'Notas atualizadas!');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao salvar notas.');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final veiculoAsync = ref.watch(_veiculoDetalheProvider(widget.veiculoId));
    final osAsync = ref.watch(_veiculoOsProvider(widget.veiculoId));

    return veiculoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink2),
            const SizedBox(height: 12),
            const Text('Erro ao carregar veículo',
                style: TextStyle(color: AppColors.ink2)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(_veiculoDetalheProvider(widget.veiculoId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (v) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncSlot(v);
        });
        final isMobile = MediaQuery.of(context).size.width < 800;
        return isMobile
            ? _buildMobileBody(v, osAsync)
            : _buildDesktopBody(v, osAsync);
      },
    );
  }

  // ─── Desktop ──────────────────────────────────────────────────────────────

  Widget _buildDesktopBody(Veiculo v, AsyncValue<List<OrdemServico>> osAsync) {
    final osList = osAsync.valueOrNull ?? [];
    final totalGasto = osList
        .where((os) => os.status != 'Cancelada')
        .fold(0.0, (sum, os) => sum + os.total);
    final osAbertas = osList
        .where((os) => !['Entregue', 'Cancelada'].contains(os.status))
        .length;
    final gastoPorAno = <int, double>{};
    for (final os in osList.where((os) => os.status != 'Cancelada')) {
      final ano = os.dataEntrada.year;
      gastoPorAno[ano] = (gastoPorAno[ano] ?? 0) + os.total;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(v, totalGasto, osAbertas, osList),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildIdentidade(v),
                    const SizedBox(height: 16),
                    _buildHistoricoOs(osList),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 272,
                child: Column(
                  children: [
                    _buildDonoCard(v),
                    if (gastoPorAno.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildGastoPorAno(gastoPorAno),
                    ],
                    const SizedBox(height: 16),
                    _buildNotas(v),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Mobile ───────────────────────────────────────────────────────────────

  Widget _buildMobileBody(Veiculo v, AsyncValue<List<OrdemServico>> osAsync) {
    final osList = osAsync.valueOrNull ?? [];
    final totalGasto = osList
        .where((os) => os.status != 'Cancelada')
        .fold(0.0, (sum, os) => sum + os.total);
    final osVida =
        osList.where((os) => os.status != 'Cancelada').length;
    final naOficina =
        osList.any((os) => !['Entregue', 'Cancelada'].contains(os.status));

    return Column(
      children: [
        // ── Header escuro (continuação da topbar) ──
        Container(
          color: AppColors.sidebarBg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placa + specs + status
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      v.placa ?? '—',
                      style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (v.ano != null) v.ano.toString(),
                            if (v.cor != null) v.cor!,
                          ].join(' · '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        if (v.combustivel != null)
                          Text(
                            v.combustivel!,
                            style: const TextStyle(
                                color: AppColors.sidebarText, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (naOficina)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'NA OFICINA',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _novaOs(v),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nova OS'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _atualizarKm(v),
                      icon: const Icon(Icons.speed_outlined, size: 16),
                      label: const Text('KM'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.sidebarLine),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('${AppRoutes.clientes}/${v.clienteId}'),
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('Dono'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.sidebarLine),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── KPIs ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MobileKpi(
                    label: 'HODÔMETRO',
                    value: v.quilometragem != null
                        ? '${_formatKm(v.quilometragem!)} km'
                        : '—',
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.line),
                Expanded(
                  child: _MobileKpi(
                    label: 'OS · VIDA',
                    value: osVida.toString(),
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.line),
                Expanded(
                  child: _MobileKpi(
                    label: 'TOTAL GASTO',
                    value: _formatCurrencyShort(totalGasto),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Tabs ──
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.ink2,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Resumo'),
              Tab(text: 'Histórico'),
              Tab(text: 'Manutenção'),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildResumoTab(v, osList),
              _buildHistoricoTabMobile(osList),
              _buildManutencaoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoTab(Veiculo v, List<OrdemServico> osList) {
    final recentes = ([...osList]
          ..sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada)))
        .take(5)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Dono
        _MobileCard(
          child: InkWell(
            onTap: () => context.push('${AppRoutes.clientes}/${v.clienteId}'),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.accentSoft,
                    child: Text(
                      v.clienteNome.isNotEmpty
                          ? v.clienteNome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(v.clienteNome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.ink2, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Identidade resumida
        _buildIdentidade(v),
        const SizedBox(height: 20),

        // OS Recentes
        if (recentes.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OS RECENTES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink2,
                      letterSpacing: 0.5)),
              GestureDetector(
                onTap: () => context.go(AppRoutes.ordensServico),
                child: const Text('Ver todas',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentes.map((os) => _MobileOsCard(
                os: os,
                onTap: () =>
                    context.push('${AppRoutes.ordensServico}/${os.id}'),
              )),
        ],

        // Notas
        if (v.observacoes?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          _buildNotas(v),
        ],
      ],
    );
  }

  Widget _buildHistoricoTabMobile(List<OrdemServico> osList) {
    final sorted = ([...osList]
          ..sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada)));

    if (sorted.isEmpty) {
      return const Center(
        child: Text('Nenhuma OS registrada para este veículo.',
            style: TextStyle(color: AppColors.ink2, fontSize: 13)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _MobileOsCard(
        os: sorted[i],
        onTap: () =>
            context.push('${AppRoutes.ordensServico}/${sorted[i].id}'),
      ),
    );
  }

  Widget _buildManutencaoTab() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined, size: 48, color: AppColors.ink3),
          SizedBox(height: 12),
          Text('Plano de manutenção em breve',
              style: TextStyle(color: AppColors.ink2, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Desktop sub-widgets ─────────────────────────────────────────────────

  Widget _buildKpiRow(Veiculo v, double totalGasto, int osAbertas,
      List<OrdemServico> osList) {
    final osCount =
        osList.where((os) => os.status != 'Cancelada').length;
    final primeiraAberta = osList
        .where((os) => !['Entregue', 'Cancelada'].contains(os.status))
        .map((os) => '#${os.id}')
        .take(1)
        .join('');

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
              child: _KpiCard(
            label: 'HODÔMETRO',
            value: v.quilometragem != null
                ? _formatKm(v.quilometragem!)
                : '—',
            sublabel: v.quilometragem != null ? 'km' : null,
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _KpiCard(
            label: 'TOTAL GASTO',
            value: _formatCurrency(totalGasto),
            sublabel: 'em $osCount OS',
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _KpiCard(
            label: 'OS ABERTAS',
            value: osAbertas.toString(),
            sublabel: osAbertas > 0 ? primeiraAberta : null,
            valueColor: osAbertas > 0 ? AppColors.accent : null,
          )),
        ],
      ),
    );
  }

  Widget _buildIdentidade(Veiculo v) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Identidade do veículo',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                OutlinedButton.icon(
                  onPressed: () => _atualizarKm(v),
                  icon: const Icon(Icons.speed_outlined, size: 15),
                  label: const Text('Atualizar KM'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 40,
              runSpacing: 16,
              children: [
                _InfoField(
                    label: 'MODELO',
                    value: '${v.marcaNome} ${v.modeloNome}'),
                _InfoField(
                    label: 'ANO', value: v.ano?.toString() ?? '—'),
                _InfoField(label: 'COR', value: v.cor ?? '—'),
                _InfoField(
                    label: 'COMBUST.', value: v.combustivel ?? '—'),
                if (v.placa != null)
                  _InfoField(
                      label: 'PLACA', value: v.placa!, mono: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoOs(List<OrdemServico> osList) {
    final sorted = [...osList]
      ..sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Histórico de OS · ${sorted.length}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => context.go(AppRoutes.ordensServico),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                  'Nenhuma OS registrada para este veículo.',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.ink2)),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                      width: 56,
                      child: Text('OS', style: _kHeaderStyle)),
                  SizedBox(
                      width: 92,
                      child: Text('DATA', style: _kHeaderStyle)),
                  Expanded(
                      child: Text('SERVIÇO', style: _kHeaderStyle)),
                  SizedBox(
                      width: 88,
                      child: Text('STATUS', style: _kHeaderStyle)),
                  SizedBox(
                      width: 88,
                      child: Text('VALOR',
                          style: _kHeaderStyle,
                          textAlign: TextAlign.right)),
                ],
              ),
            ),
            const Divider(height: 12),
            ...sorted.map((os) => _OsRow(
                  os: os,
                  onTap: () => context
                      .push('${AppRoutes.ordensServico}/${os.id}'),
                )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDonoCard(Veiculo v) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dono',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  v.clienteNome.isNotEmpty
                      ? v.clienteNome[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      fontSize: 15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(v.clienteNome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context
                  .push('${AppRoutes.clientes}/${v.clienteId}'),
              child: const Text('Ver ficha do cliente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGastoPorAno(Map<int, double> gastoPorAno) {
    final anos = gastoPorAno.keys.toList()..sort();
    final maxVal =
        gastoPorAno.values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gasto por ano',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('todas as OS pagas',
              style: TextStyle(fontSize: 11, color: AppColors.ink2)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: anos.map((ano) {
              final val = gastoPorAno[ano]!;
              final frac = maxVal > 0 ? val / maxVal : 0.0;
              final barH = (frac * 72).clamp(6.0, 72.0);
              return Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(_formatCurrencyShort(val),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Container(
                        height: barH,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(ano.toString(),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.ink2)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotas(Veiculo v) {
    final hasNotas = v.observacoes?.isNotEmpty == true;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notas técnicas',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => _editarNotas(v),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Editar notas',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasNotas
                ? v.observacoes!
                : 'Nenhuma nota técnica registrada.',
            style: TextStyle(
              fontSize: 13,
              color:
                  hasNotas ? AppColors.ink : AppColors.ink2,
              fontStyle: hasNotas
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Formatters ───────────────────────────────────────────────────────────

  String _formatKm(int km) => km
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  String _formatCurrency(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  String _formatCurrencyShort(double v) {
    if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }
}

// ─── Shared constants ─────────────────────────────────────────────────────────

const _kHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.ink2,
  letterSpacing: 0.3,
);

// ─── Desktop widgets ──────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.sublabel,
    this.valueColor,
  });
  final String label;
  final String value;
  final String? sublabel;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.ink)),
          if (sublabel != null)
            Text(sublabel!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField(
      {required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'JetBrains Mono' : null,
              )),
        ],
      ),
    );
  }
}

class _OsRow extends StatelessWidget {
  const _OsRow({required this.os, required this.onTap});
  final OrdemServico os;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = os.dataEntrada;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final (bg, fg) = switch (os.status) {
      'Entregue'    => (AppColors.okSoft, AppColors.ok),
      'Cancelada'   => (AppColors.dangerSoft, AppColors.danger),
      'EmAndamento' => (AppColors.infoSoft, AppColors.info),
      'Aguardando'  => (AppColors.warnSoft, AppColors.warn),
      _             => (AppColors.surface2, AppColors.ink2),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.surface2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text('#${os.id}',
                    style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 92,
                child: Text(date,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.ink2)),
              ),
              Expanded(
                child: Text(
                  os.primeiroServico ?? os.veiculoDescricao,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 88,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(os.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: fg),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              SizedBox(
                width: 88,
                child: Text(
                  _formatVal(os.total),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono'),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVal(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

// ─── Mobile widgets ───────────────────────────────────────────────────────────

class _MobileKpi extends StatelessWidget {
  const _MobileKpi({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class _MobileOsCard extends StatelessWidget {
  const _MobileOsCard({required this.os, required this.onTap});
  final OrdemServico os;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = os.dataEntrada;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final (dotColor, label) = switch (os.status) {
      'Entregue'    => (AppColors.ok, 'PRONTO'),
      'Cancelada'   => (AppColors.danger, 'CANCELADA'),
      'EmAndamento' => (AppColors.info, 'EM ANDAMENTO'),
      'Aguardando'  => (AppColors.warn, 'AGUARDANDO'),
      _             => (AppColors.ink2, os.status.toUpperCase()),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('#${os.id}',
                            style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.ink2)),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: dotColor)),
                      ],
                    ),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.ink2)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  os.primeiroServico ?? os.veiculoDescricao,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (os.mecanicoNomes.isNotEmpty)
                      Text(os.mecanicoNomes.first,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.ink2)),
                    Text(
                      _formatVal(os.total),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'JetBrains Mono'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatVal(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}
