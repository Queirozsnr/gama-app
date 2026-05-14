import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/chips/status_chip.dart';
import '../../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../../../shared/widgets/gama_searchable_select.dart';
import '../../funcionarios/data/funcionarios_remote_data_source.dart';
import '../../funcionarios/domain/funcionario.dart';
import '../data/ordens_servico_remote_data_source.dart';
import '../domain/desconto_os.dart';
import '../domain/item_os.dart';
import '../domain/ordem_servico_detalhe.dart';
import '../domain/os_mecanico.dart';
import 'ordens_servico_notifier.dart';
import '../../estoque/data/estoque_remote_data_source.dart';
import '../../estoque/domain/estoque.dart';

const _statusTransicoes = {
  'Aberta':           ['EmAndamento'],
  'EmAndamento':      ['AguardandoPecas', 'Concluida'],
  'AguardandoPecas':  ['EmAndamento', 'Concluida'],
  'Concluida':        ['Entregue'],
  'Entregue':         <String>[],
};

const _statusLabels = {
  'Aberta':           'Aberta',
  'EmAndamento':      'Em andamento',
  'AguardandoPecas':  'Aguardando peças',
  'Concluida':        'Concluída',
  'Entregue':         'Entregue',
};

const _formasPagamentoLabels = {
  'Dinheiro':       'Dinheiro',
  'Pix':            'Pix',
  'CartaoDebito':   'Cartão de débito',
  'CartaoCredito':  'Cartão de crédito',
  'Transferencia':  'Transferência',
  'Outro':          'Outro',
};

const _origensLabels = {
  'Estoque':         'Do estoque',
  'Comprado':        'Comprado',
  'ClienteTrouxe':   'Cliente trouxe',
};

// Cores por status para o bottom sheet
const _statusColors = {
  'Aberta':           Color(0xFF757575),
  'EmAndamento':      Color(0xFF1565C0),
  'AguardandoPecas':  Color(0xFFE65100),
  'Concluida':        Color(0xFF2E7D32),
  'Entregue':         Color(0xFF546E7A),
};

class OsDetalheScreen extends ConsumerStatefulWidget {
  const OsDetalheScreen({super.key, required this.osId});
  final int osId;

  @override
  ConsumerState<OsDetalheScreen> createState() => _OsDetalheScreenState();
}

class _OsDetalheScreenState extends ConsumerState<OsDetalheScreen> {
  bool _actionLoading = false;

  String _dioError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'] as String;
    }
    return fallback;
  }

  Future<void> _alterarStatus(OrdemServicoDetalhe os) async {
    final proximos = _statusTransicoes[os.status] ?? [];
    if (proximos.isEmpty) return;

    final escolhido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _StatusBottomSheet(
        statusAtual: os.status,
        proximos: proximos,
      ),
    );
    if (escolhido == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).alterarStatus(os.id, escolhido);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Status atualizado para ${_statusLabels[escolhido]}.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao atualizar status.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _ingressar(int osId) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).ingressar(osId);
      ref.invalidate(osDetalheProvider(widget.osId));
      if (mounted) GamaSnackBar.success(context, 'Você ingressou na OS.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao ingressar na OS.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _adicionarMecanico(int osId) async {
    final escolhido = await showDialog<Funcionario>(
      context: context,
      builder: (ctx) => const _MecanicoPickerDialog(),
    );
    if (escolhido == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).adicionarMecanico(osId, escolhido.id);
      ref.invalidate(osDetalheProvider(widget.osId));
      if (mounted) GamaSnackBar.success(context, '${escolhido.nome} adicionado.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao adicionar mecânico.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removerMecanico(int osId, OsMecanico mecanico) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Remover mecânico',
      message: 'Remover ${mecanico.nome} desta OS?',
      confirmLabel: 'Remover',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).removerMecanico(osId, mecanico.funcionarioId);
      ref.invalidate(osDetalheProvider(widget.osId));
      if (mounted) GamaSnackBar.success(context, 'Mecânico removido.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao remover mecânico.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _adicionarItem(int osId, String tipo) async {
    final item = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ItemFormDialog(tipoInicial: tipo),
    );
    if (item == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).adicionarItem(osId, item);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Item adicionado.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao adicionar item.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removerItem(int osId, ItemOs item) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Remover item',
      message: 'Remover "${item.descricao}" desta OS?',
      confirmLabel: 'Remover',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).removerItem(osId, item.id);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Item removido.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao remover item.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _adicionarDesconto(int osId) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _DescontoFormDialog(),
    );
    if (data == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).adicionarDesconto(osId, data);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Desconto adicionado.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao adicionar desconto.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removerDesconto(int osId, DescontoOs desconto) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Remover desconto',
      message: 'Remover "${desconto.descricao}"?',
      confirmLabel: 'Remover',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).removerDesconto(osId, desconto.id);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Desconto removido.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao remover desconto.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _editarConclusao(OrdemServicoDetalhe os) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _EditarConclusaoDialog(os: os),
    );
    if (data == null || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).atualizar(os.id, data);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Dados atualizados.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao atualizar OS.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _excluir(OrdemServicoDetalhe os) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir OS #${os.id}',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).excluir(os.id);
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) {
        GamaSnackBar.success(context, 'OS excluída.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao excluir OS.'));
      setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalheAsync = ref.watch(osDetalheProvider(widget.osId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: detalheAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar OS', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(osDetalheProvider(widget.osId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (os) => _Body(
          os: os,
          actionLoading: _actionLoading,
          podeEditar: os.status != 'Entregue',
          onAlterarStatus: () => _alterarStatus(os),
          onIngressar: () => _ingressar(os.id),
          onAdicionarMecanico: () => _adicionarMecanico(os.id),
          onRemoverMecanico: (m) => _removerMecanico(os.id, m),
          onAdicionarServico: () => _adicionarItem(os.id, 'Servico'),
          onAdicionarPeca: () => _adicionarItem(os.id, 'Peca'),
          onRemoverItem: (item) => _removerItem(os.id, item),
          onAdicionarDesconto: () => _adicionarDesconto(os.id),
          onRemoverDesconto: (d) => _removerDesconto(os.id, d),
          onEditarConclusao: () => _editarConclusao(os),
          onExcluir: () => _excluir(os),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.os,
    required this.actionLoading,
    required this.podeEditar,
    required this.onAlterarStatus,
    required this.onIngressar,
    required this.onAdicionarMecanico,
    required this.onRemoverMecanico,
    required this.onAdicionarServico,
    required this.onAdicionarPeca,
    required this.onRemoverItem,
    required this.onAdicionarDesconto,
    required this.onRemoverDesconto,
    required this.onEditarConclusao,
    required this.onExcluir,
  });

  final OrdemServicoDetalhe os;
  final bool actionLoading;
  final bool podeEditar;
  final VoidCallback onAlterarStatus;
  final VoidCallback onIngressar;
  final VoidCallback onAdicionarMecanico;
  final void Function(OsMecanico) onRemoverMecanico;
  final VoidCallback onAdicionarServico;
  final VoidCallback onAdicionarPeca;
  final void Function(ItemOs) onRemoverItem;
  final VoidCallback onAdicionarDesconto;
  final void Function(DescontoOs) onRemoverDesconto;
  final VoidCallback onEditarConclusao;
  final VoidCallback onExcluir;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final status = OsStatus.fromString(os.status);
    final proximos = _statusTransicoes[os.status] ?? [];
    final podeExcluir = os.status == 'Aberta';
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final servicos = os.itens.where((i) => !i.isPeca).toList();
    final pecas    = os.itens.where((i) =>  i.isPeca).toList();

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          leading: const BackButton(color: AppColors.textPrimary),
          title: Text('OS #${os.id}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          actions: [
            if (actionLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Status card ─────────────────────────────────────────────
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(status: status),
                        const Spacer(),
                        _InfoTag(Icons.calendar_today_outlined, 'Entrada: ${_fmt(os.dataEntrada)}'),
                      ],
                    ),
                    if (os.previsaoEntrega != null) ...[
                      const SizedBox(height: 8),
                      _InfoTag(
                        Icons.schedule_outlined,
                        'Previsão: ${_fmt(os.previsaoEntrega!)}',
                        color: DateTime.now().isAfter(os.previsaoEntrega!) &&
                                os.status != 'Concluida' &&
                                os.status != 'Entregue'
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ],
                    if (os.dataConclusao != null) ...[
                      const SizedBox(height: 8),
                      _InfoTag(Icons.check_circle_outline, 'Concluída: ${_fmt(os.dataConclusao!)}',
                          color: AppColors.success),
                    ],
                    if (proximos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: onAlterarStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text('Alterar status',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              const Spacer(),
                              Text(
                                proximos.map((s) => _statusLabels[s]).join(' / '),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Cliente + Veículo ────────────────────────────────────────
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(Icons.person_outline, 'Cliente', os.clienteNome),
                    if (os.clienteTelefone != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(Icons.phone_outlined, 'Telefone', os.clienteTelefone!),
                    ],
                    const SizedBox(height: 8),
                    _DetailRow(
                      Icons.directions_car_outlined,
                      'Veículo',
                      os.veiculoPlaca != null
                          ? '${os.veiculoDescricao} · ${os.veiculoPlaca}'
                          : os.veiculoDescricao,
                    ),
                    if (os.veiculoCor != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(Icons.palette_outlined, 'Cor', os.veiculoCor!),
                    ],
                    if (os.formaPagamento != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(Icons.payment_outlined, 'Pagamento',
                          _formasPagamentoLabels[os.formaPagamento] ?? os.formaPagamento!),
                    ],
                    if (os.observacoes != null && os.observacoes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailRow(Icons.notes_outlined, 'Observações', os.observacoes!),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: os.status == 'Entregue' ? null : onEditarConclusao,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14,
                              color: os.status == 'Entregue' ? AppColors.textSecondary : AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Editar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: os.status == 'Entregue' ? AppColors.textSecondary : AppColors.primary,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Mecânicos ────────────────────────────────────────────────
              _SectionHeader(
                label: 'Mecânicos',
                actions: podeEditar ? [
                  _HeaderBtn(Icons.engineering_outlined, 'Ingressar', onIngressar),
                  _HeaderBtn(Icons.person_add_outlined, 'Adicionar', onAdicionarMecanico),
                ] : [],
              ),
              const SizedBox(height: 6),
              if (os.mecanicos.isEmpty)
                _EmptyHint('Nenhum mecânico atribuído.')
              else
                _Section(
                  child: Column(
                    children: [
                      for (int i = 0; i < os.mecanicos.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _MecanicoTile(
                          mecanico: os.mecanicos[i],
                          onRemove: podeEditar ? () => onRemoverMecanico(os.mecanicos[i]) : null,
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Serviços ─────────────────────────────────────────────────
              _SectionHeader(
                label: 'Serviços',
                actions: podeEditar ? [_HeaderBtn(Icons.add, 'Adicionar', onAdicionarServico)] : [],
              ),
              const SizedBox(height: 6),
              if (servicos.isEmpty)
                _EmptyHint('Nenhum serviço cadastrado.')
              else
                _Section(
                  child: Column(
                    children: [
                      for (int i = 0; i < servicos.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ItemTile(item: servicos[i], onRemove: podeEditar ? () => onRemoverItem(servicos[i]) : null),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Peças ────────────────────────────────────────────────────
              _SectionHeader(
                label: 'Peças',
                actions: podeEditar ? [_HeaderBtn(Icons.add, 'Adicionar', onAdicionarPeca)] : [],
              ),
              const SizedBox(height: 6),
              if (pecas.isEmpty)
                _EmptyHint('Nenhuma peça cadastrada.')
              else
                _Section(
                  child: Column(
                    children: [
                      for (int i = 0; i < pecas.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _ItemTile(item: pecas[i], onRemove: podeEditar ? () => onRemoverItem(pecas[i]) : null),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // ── Totais + Descontos ───────────────────────────────────────
              _SectionHeader(
                label: 'Descontos',
                actions: podeEditar ? [_HeaderBtn(Icons.add, 'Adicionar', onAdicionarDesconto)] : [],
              ),
              const SizedBox(height: 6),
              _Section(
                child: Column(
                  children: [
                    _TotalRow('Serviços', os.totalServicos),
                    const SizedBox(height: 6),
                    _TotalRow('Peças', os.totalPecas),
                    if (os.descontos.isNotEmpty) ...[
                      const Divider(height: 16),
                      for (final d in os.descontos) ...[
                        _DescontoTile(desconto: d, onRemove: podeEditar ? () => onRemoverDesconto(d) : null),
                        const SizedBox(height: 4),
                      ],
                    ],
                    const Divider(height: 16),
                    if (os.totalDescontos > 0) ...[
                      _TotalRow('Subtotal', os.total),
                      const SizedBox(height: 6),
                      _TotalRow('Descontos', -os.totalDescontos, color: AppColors.error),
                      const SizedBox(height: 6),
                    ],
                    _TotalRow('Total', os.total - os.totalDescontos, bold: true),
                  ],
                ),
              ),

              if (podeExcluir) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
                  child: FilledButton(
                    onPressed: onExcluir,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('Excluir OS'),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Center(
                child: Text('Criado por ${os.criadoPorNome}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.actions});
  final String label;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          ...actions,
        ],
      );
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn(this.icon, this.label, this.onPressed);
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6)),
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
        ],
      );
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.text, {this.color = AppColors.textSecondary});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false, this.color});
  final String label;
  final double value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (bold ? AppColors.textPrimary : AppColors.textSecondary);
    final absValue = value.abs();
    final prefix = value < 0 ? '- R\$ ' : 'R\$ ';
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              color: effectiveColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            )),
        const Spacer(),
        Text(
          '$prefix${absValue.toStringAsFixed(2).replaceAll('.', ',')}',
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}

class _DescontoTile extends StatelessWidget {
  const _DescontoTile({required this.desconto, required this.onRemove});
  final DescontoOs desconto;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(desconto.descricao,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text(
            '- R\$ ${desconto.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 14),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
}

class _MecanicoTile extends StatelessWidget {
  const _MecanicoTile({required this.mecanico, required this.onRemove});
  final OsMecanico mecanico;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(mecanico.nome[0].toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mecanico.nome,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(mecanico.cargo, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onRemove});
  final ItemOs item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.descricao,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  Text(
                    '${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade} × R\$ ${item.valorUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (item.origemPeca != null)
                    Text(_origensLabels[item.origemPeca] ?? item.origemPeca!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}

// ── Status bottom sheet ───────────────────────────────────────────────────────

class _StatusBottomSheet extends StatelessWidget {
  const _StatusBottomSheet({required this.statusAtual, required this.proximos});
  final String statusAtual;
  final List<String> proximos;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Alterar status',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Status atual: ${_statusLabels[statusAtual]}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            for (final s in proximos) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context, s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: (_statusColors[s] ?? AppColors.primary).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (_statusColors[s] ?? AppColors.primary).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _statusColors[s] ?? AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusLabels[s] ?? s,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _statusColors[s] ?? AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: _statusColors[s] ?? AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mechanic picker dialog ────────────────────────────────────────────────────

class _MecanicoPickerDialog extends ConsumerStatefulWidget {
  const _MecanicoPickerDialog();

  @override
  ConsumerState<_MecanicoPickerDialog> createState() => _MecanicoPickerDialogState();
}

class _MecanicoPickerDialogState extends ConsumerState<_MecanicoPickerDialog> {
  Funcionario? _selecionado;

  Future<List<Funcionario>> _buscar(String q) =>
      ref.read(funcionariosRemoteDataSourceProvider).listar(busca: q.isEmpty ? null : q);

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adicionar mecânico',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                GamaSearchableSelect<Funcionario>(
                  label: 'Mecânico',
                  selectedValue: _selecionado,
                  optionsBuilder: _buscar,
                  displayString: (f) => '${f.nome} · ${f.cargo}',
                  onChanged: (f) => setState(() => _selecionado = f),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _selecionado == null ? null : () => Navigator.pop(context, _selecionado),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Desconto form dialog ──────────────────────────────────────────────────────

class _DescontoFormDialog extends StatefulWidget {
  const _DescontoFormDialog();

  @override
  State<_DescontoFormDialog> createState() => _DescontoFormDialogState();
}

class _DescontoFormDialogState extends State<_DescontoFormDialog> {
  final _descCtrl  = TextEditingController();
  final _valorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    final canSave = _descCtrl.text.trim().isNotEmpty;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Novo desconto',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: _descCtrl, decoration: _dec('Descrição'), autofocus: true),
              const SizedBox(height: 10),
              TextField(
                controller: _valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Valor (R\$)'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canSave
                        ? () => Navigator.pop(context, {
                              'descricao': _descCtrl.text.trim(),
                              'valor': double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0,
                            })
                        : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Editar conclusão dialog ───────────────────────────────────────────────────

class _EditarConclusaoDialog extends StatefulWidget {
  const _EditarConclusaoDialog({required this.os});
  final OrdemServicoDetalhe os;

  @override
  State<_EditarConclusaoDialog> createState() => _EditarConclusaoDialogState();
}

class _EditarConclusaoDialogState extends State<_EditarConclusaoDialog> {
  late final TextEditingController _obsCtrl;
  String? _formaPagamento;
  late DateTime _dataEntrada;
  DateTime? _previsaoEntrega;

  @override
  void initState() {
    super.initState();
    _obsCtrl = TextEditingController(text: widget.os.observacoes ?? '');
    _formaPagamento = widget.os.formaPagamento;
    _dataEntrada = widget.os.dataEntrada;
    _previsaoEntrega = widget.os.previsaoEntrega;
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDataEntrada() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataEntrada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dataEntrada = d);
  }

  Future<void> _pickPrevisao() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _previsaoEntrega ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _previsaoEntrega = d);
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap, {bool canClear = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value != null ? _fmtDate(value) : label,
                  style: TextStyle(
                    fontSize: 13,
                    color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              if (canClear && value != null)
                GestureDetector(
                  onTap: () => setState(() => _previsaoEntrega = null),
                  child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar OS',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data de entrada', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        _datePicker('Data entrada', _dataEntrada, _pickDataEntrada),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Previsão entrega', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        _datePicker('Sem previsão', _previsaoEntrega, _pickPrevisao, canClear: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _formaPagamento,
                decoration: _dec('Forma de pagamento'),
                items: _formasPagamentoLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _formaPagamento = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _obsCtrl,
                decoration: _dec('Observações'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, {
                              'formaPagamento': _formaPagamento,
                              'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                              'previsaoEntrega': _previsaoEntrega?.toIso8601String(),
                              'dataEntrada': _dataEntrada.toIso8601String(),
                            }),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item form dialog ──────────────────────────────────────────────────────────

class _ItemFormDialog extends ConsumerStatefulWidget {
  const _ItemFormDialog({this.tipoInicial = 'Servico'});
  final String tipoInicial;

  @override
  ConsumerState<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends ConsumerState<_ItemFormDialog> {
  late String _tipo;
  final _descCtrl  = TextEditingController();
  final _qtdCtrl   = TextEditingController(text: '1');
  final _valorCtrl = TextEditingController();
  String? _origemPeca;
  ProdutoListagem? _produto;

  bool get _isEstoque => _origemPeca == 'Estoque';

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtdCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  void _onProdutoSelecionado(ProdutoListagem? p) {
    setState(() => _produto = p);
    if (p != null) {
      _descCtrl.text = p.nome;
      if (_valorCtrl.text.isEmpty) {
        _valorCtrl.text = p.precoVenda.toStringAsFixed(2);
      }
    }
  }

  void _salvar() {
    final descOk = _isEstoque ? _produto != null : _descCtrl.text.trim().isNotEmpty;
    if (!descOk) return;
    final qtd   = double.tryParse(_qtdCtrl.text) ?? 1;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    Navigator.pop(context, {
      'tipo': _tipo,
      'descricao': _descCtrl.text.trim(),
      'quantidade': qtd,
      'valorUnitario': valor,
      if (_tipo == 'Peca' && _origemPeca != null) 'origemPeca': _origemPeca,
      if (_isEstoque && _produto != null) 'produtoId': _produto!.id,
    });
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    final canSave = _isEstoque ? _produto != null : _descCtrl.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tipo == 'Peca' ? 'Nova peça' : 'Novo serviço',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              if (_isEstoque)
                GamaSearchableSelect<ProdutoListagem>(
                  label: 'Produto do estoque *',
                  selectedValue: _produto,
                  displayString: (p) => p.nome,
                  optionsBuilder: (query) =>
                      ref.read(estoqueDataSourceProvider).listarProdutos(busca: query),
                  onChanged: _onProdutoSelecionado,
                )
              else
                TextField(controller: _descCtrl, decoration: _dec('Descrição'), autofocus: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtdCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Quantidade'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Valor unit. (R\$)'),
                    ),
                  ),
                ],
              ),
              if (_tipo == 'Peca') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _origemPeca,
                  decoration: _dec('Origem da peça'),
                  items: _origensLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() { _origemPeca = v; _produto = null; _descCtrl.clear(); _valorCtrl.clear(); }),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canSave ? _salvar : null,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
