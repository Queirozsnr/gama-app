import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/state/top_bar_scope.dart';
import '../../../../shared/utils/file_picker_helper.dart';
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
import '../domain/os_midia.dart';
import 'ordens_servico_notifier.dart';
import 'os_orcamento_pdf.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../estoque/data/estoque_remote_data_source.dart';
import '../../estoque/domain/estoque.dart';
import '../../oficinas/presentation/oficinas_notifier.dart';

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

const _statusColors = {
  'Aberta':           Color(0xFF757575),
  'EmAndamento':      Color(0xFF1565C0),
  'AguardandoPecas':  Color(0xFFE65100),
  'Concluida':        Color(0xFF2E7D32),
  'Entregue':         Color(0xFF546E7A),
};

String _fmt(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

class OsDetalheScreen extends ConsumerStatefulWidget {
  const OsDetalheScreen({super.key, required this.osId});
  final int osId;

  @override
  ConsumerState<OsDetalheScreen> createState() => _OsDetalheScreenState();
}

class _OsDetalheScreenState extends ConsumerState<OsDetalheScreen>
    with TopBarSlotMixin<OsDetalheScreen> {
  bool _actionLoading = false;
  bool _menuAberto = false;

  String? _primaryActionLabel(String status) {
    switch (status) {
      case 'EmAndamento':
      case 'AguardandoPecas':
        return 'Marcar pronta';
      case 'Concluida':
        return 'Marcar entregue';
      default:
        return null;
    }
  }

  String? _primaryActionTarget(String status) {
    switch (status) {
      case 'EmAndamento':
      case 'AguardandoPecas':
        return 'Concluida';
      case 'Concluida':
        return 'Entregue';
      default:
        return null;
    }
  }

  Future<void> _alterarStatusDireto(OrdemServicoDetalhe os, String novoStatus) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).alterarStatus(os.id, novoStatus);
      ref.invalidate(osDetalheProvider(widget.osId));
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) GamaSnackBar.success(context, 'Status atualizado para ${_statusLabels[novoStatus]}.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao atualizar status.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _dioError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'] as String;
    }
    return fallback;
  }

  void _showOsMenu(OrdemServicoDetalhe os) {
    if (_menuAberto) return;
    setState(() => _menuAberto = true);
    final podeExcluir = os.status == 'Aberta';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined, color: AppColors.ink2),
              title: Text('Imprimir',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink)),
              onTap: () {
                Navigator.pop(ctx);
                _imprimirOs(os);
              },
            ),
            if (os.status == 'Concluida' || os.status == 'Entregue')
              ListTile(
                leading: Icon(Icons.receipt_long_outlined, color: Colors.green.shade700),
                title: Text('Gerar Recibo',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.green.shade700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _gerarRecibo(os);
                },
              ),
            if (os.status != 'Entregue')
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.ink2),
                title: Text('Editar OS',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarConclusao(os);
                },
              ),
            if (podeExcluir)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text('Excluir OS',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _excluir(os);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _menuAberto = false);
    });
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
      confirmColor: AppColors.danger,
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
      confirmColor: AppColors.danger,
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
      confirmColor: AppColors.danger,
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

  Future<void> _imprimirOs(OrdemServicoDetalhe os) async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = await ref.read(oficinasNotifierProvider.future);
    final oficina = oficinas.where((o) => o.id == authState?.oficinaId).firstOrNull;
    await imprimirOs(os, oficina);
  }

  Future<void> _gerarRecibo(OrdemServicoDetalhe os) async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = await ref.read(oficinasNotifierProvider.future);
    final oficina = oficinas.where((o) => o.id == authState?.oficinaId).firstOrNull;
    await gerarRecibo(os, oficina);
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

  Future<void> _adicionarMidia(int osId, Uint8List bytes, String filename) async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).adicionarMidia(osId, bytes, filename);
      ref.invalidate(osDetalheProvider(widget.osId));
      if (mounted) GamaSnackBar.success(context, 'Mídia adicionada.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao adicionar mídia.'));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removerMidia(int osId, OsMidia midia) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Remover mídia',
      message: 'Remover esta ${midia.isVideo ? 'vídeo' : 'foto'}?',
      confirmLabel: 'Remover',
      confirmColor: AppColors.danger,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).removerMidia(osId, midia.id);
      ref.invalidate(osDetalheProvider(widget.osId));
      if (mounted) GamaSnackBar.success(context, 'Mídia removida.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao remover mídia.'));
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
      confirmColor: AppColors.danger,
    );
    if (!ok || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(ordensServicoRemoteDataSourceProvider).excluir(os.id);
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) {
        GamaSnackBar.success(context, 'OS excluída.');
        context.go('/ordens-servico');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, _dioError(e, 'Erro ao excluir OS.'));
      setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalheAsync = ref.watch(osDetalheProvider(widget.osId));
    final os = detalheAsync.valueOrNull;
    final primeiroServico = os?.itens.where((i) => !i.isPeca).firstOrNull?.descricao;

    setTopBarSlot(TopBarSlot(
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: 'OS #${widget.osId}',
      pageTitle: primeiroServico ?? 'Ordem de Serviço',
      leading: BackButton(onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          context.go(from ?? '/ordens-servico');
        }
      }),
      mobileAction: _actionLoading
          ? const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            )
          : os != null
              ? IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () => _showOsMenu(os),
                )
              : null,
      action: os != null
          ? _DesktopActions(
              os: os,
              loading: _actionLoading,
              primaryLabel: _primaryActionLabel(os.status),
              onImprimir: () => _imprimirOs(os),
              onRecibo: (os.status == 'Concluida' || os.status == 'Entregue')
                  ? () => _gerarRecibo(os)
                  : null,
              onAlterarStatus: () => _alterarStatus(os),
              onPrimaryAction: () {
                final target = _primaryActionTarget(os.status);
                if (target != null) _alterarStatusDireto(os, target);
              },
              onExcluir: () => _excluir(os),
              onEditarConclusao: () => _editarConclusao(os),
            )
          : null,
    ));

    return detalheAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink2),
            const SizedBox(height: 12),
            const Text('Erro ao carregar OS', style: TextStyle(color: AppColors.ink2)),
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
        onAdicionarMidia: (bytes, name) => _adicionarMidia(os.id, bytes, name),
        onRemoverMidia: (m) => _removerMidia(os.id, m),
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
    required this.onAdicionarMidia,
    required this.onRemoverMidia,
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
  final Future<void> Function(Uint8List bytes, String filename) onAdicionarMidia;
  final Future<void> Function(OsMidia) onRemoverMidia;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return isDesktop ? _buildDesktop(context) : _buildMobile(context);
  }

  // ── Desktop layout (two-column) ──────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    final servicos = os.itens.where((i) => !i.isPeca).toList();
    final pecas    = os.itens.where((i) =>  i.isPeca).toList();
    final podeExcluir = os.status == 'Aberta';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coluna principal ─────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veículo
                _DesktopVeiculoCard(os: os),
                const SizedBox(height: 12),

                // Cliente
                _DesktopClienteCard(
                  os: os,
                  podeEditar: podeEditar,
                  onEditar: onEditarConclusao,
                ),
                const SizedBox(height: 12),

                // Serviços
                _Section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build_outlined, size: 15, color: AppColors.ink2),
                          const SizedBox(width: 6),
                          Text('Serviços',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const Spacer(),
                          if (podeEditar)
                            _HeaderBtn(Icons.add, 'Adicionar serviço', onAdicionarServico),
                        ],
                      ),
                      if (servicos.isEmpty) ...[
                        const SizedBox(height: 8),
                        _EmptyHint('Nenhum serviço cadastrado.'),
                      ] else ...[
                        const SizedBox(height: 4),
                        for (int i = 0; i < servicos.length; i++) ...[
                          const Divider(height: 1),
                          _ItemTile(
                            item: servicos[i],
                            onRemove: podeEditar ? () => onRemoverItem(servicos[i]) : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Peças
                _Section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_outlined, size: 15, color: AppColors.ink2),
                          const SizedBox(width: 6),
                          Text('Peças aplicadas',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const Spacer(),
                          if (podeEditar)
                            _HeaderBtn(Icons.add, 'Buscar peça', onAdicionarPeca),
                        ],
                      ),
                      if (pecas.isEmpty) ...[
                        const SizedBox(height: 8),
                        _EmptyHint('Nenhuma peça cadastrada.'),
                      ] else ...[
                        const SizedBox(height: 4),
                        for (int i = 0; i < pecas.length; i++) ...[
                          const Divider(height: 1),
                          _ItemTile(
                            item: pecas[i],
                            onRemove: podeEditar ? () => onRemoverItem(pecas[i]) : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fotos e vídeos
                _FotosVideosCard(
                  midias: os.midias,
                  podeEditar: podeEditar,
                  isDesktop: true,
                  onAdd: onAdicionarMidia,
                  onRemover: onRemoverMidia,
                ),
                const SizedBox(height: 12),

                // Observações
                _Section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes_outlined, size: 15, color: AppColors.ink2),
                          const SizedBox(width: 6),
                          Text('Observações',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(width: 4),
                          Text('Notas internas — não aparecem pro cliente',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        os.observacoes != null && os.observacoes!.isNotEmpty
                            ? os.observacoes!
                            : 'Nenhuma observação registrada.',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 13,
                          color: os.observacoes != null && os.observacoes!.isNotEmpty
                              ? AppColors.ink2
                              : AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),

                if (podeExcluir) ...[
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: onExcluir,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Excluir OS'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── Sidebar ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Resumo financeiro
                _ResumoFinanceiroCard(
                  os: os,
                  podeEditar: podeEditar,
                  onAdicionarDesconto: onAdicionarDesconto,
                  onRemoverDesconto: onRemoverDesconto,
                ),
                const SizedBox(height: 12),

                // Histórico (placeholder)
                _HistoricoCard(),
                const SizedBox(height: 12),

                // Responsável (mecânicos)
                _ResponsavelCard(
                  os: os,
                  podeEditar: podeEditar,
                  onIngressar: onIngressar,
                  onAdicionarMecanico: onAdicionarMecanico,
                  onRemoverMecanico: onRemoverMecanico,
                ),
                const SizedBox(height: 32),
                Text('Criado por ${os.criadoPorNome}',
                    style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  // ── Mobile layout (tabbed) ────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final status = OsStatus.fromString(os.status);
    final proximos = _statusTransicoes[os.status] ?? [];
    final servicos = os.itens.where((i) => !i.isPeca).toList();
    final pecas    = os.itens.where((i) =>  i.isPeca).toList();
    final totalFinal = os.total - os.totalDescontos;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // ── Status bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                StatusChip(status: status),
                const Spacer(),
                if (os.previsaoEntrega != null)
                  _InfoTag(
                    Icons.schedule_outlined,
                    _fmt(os.previsaoEntrega!),
                    color: DateTime.now().isAfter(os.previsaoEntrega!) &&
                            os.status != 'Concluida' &&
                            os.status != 'Entregue'
                        ? AppColors.danger
                        : AppColors.ink2,
                  ),
              ],
            ),
          ),

          // ── Tab bar ───────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.ink2,
              indicatorColor: AppColors.accent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Resumo'),
                Tab(text: 'Peças'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),

          // ── Tab views ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              children: [
                // Resumo
                _ResumoTab(
                  os: os,
                  servicos: servicos,
                  podeEditar: podeEditar,
                  onEditarConclusao: onEditarConclusao,
                  onIngressar: onIngressar,
                  onAdicionarMecanico: onAdicionarMecanico,
                  onRemoverMecanico: onRemoverMecanico,
                  onAdicionarServico: onAdicionarServico,
                  onRemoverItem: onRemoverItem,
                  onAdicionarMidia: onAdicionarMidia,
                  onRemoverMidia: onRemoverMidia,
                ),
                // Peças
                _PecasTab(
                  os: os,
                  pecas: pecas,
                  podeEditar: podeEditar,
                  onAdicionarPeca: onAdicionarPeca,
                  onRemoverItem: onRemoverItem,
                  onAdicionarDesconto: onAdicionarDesconto,
                  onRemoverDesconto: onRemoverDesconto,
                ),
                // Histórico
                const _HistoricoTab(),
              ],
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2)),
                      Text(
                        'R\$ ${totalFinal.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (proximos.isNotEmpty)
                    FilledButton(
                      onPressed: actionLoading ? null : onAlterarStatus,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.sidebarBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      ),
                      child: Text(
                        'Alterar status',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile tab: Resumo ────────────────────────────────────────────────────────

class _ResumoTab extends StatelessWidget {
  const _ResumoTab({
    required this.os,
    required this.servicos,
    required this.podeEditar,
    required this.onEditarConclusao,
    required this.onIngressar,
    required this.onAdicionarMecanico,
    required this.onRemoverMecanico,
    required this.onAdicionarServico,
    required this.onRemoverItem,
    required this.onAdicionarMidia,
    required this.onRemoverMidia,
  });

  final OrdemServicoDetalhe os;
  final List<ItemOs> servicos;
  final bool podeEditar;
  final VoidCallback onEditarConclusao;
  final VoidCallback onIngressar;
  final VoidCallback onAdicionarMecanico;
  final void Function(OsMecanico) onRemoverMecanico;
  final VoidCallback onAdicionarServico;
  final void Function(ItemOs) onRemoverItem;
  final Future<void> Function(Uint8List bytes, String filename) onAdicionarMidia;
  final Future<void> Function(OsMidia) onRemoverMidia;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        // Vehicle card
        _VehicleCard(os: os),
        const SizedBox(height: 8),
        // Client card
        _ClientCard(os: os, podeEditar: podeEditar, onEditar: onEditarConclusao),
        const SizedBox(height: 14),

        const SizedBox(height: 14),

        // Mecânicos
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
        const SizedBox(height: 14),

        // Serviços
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
                  _ItemTile(
                    item: servicos[i],
                    onRemove: podeEditar ? () => onRemoverItem(servicos[i]) : null,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 14),
        _FotosVideosCard(
          midias: os.midias,
          podeEditar: podeEditar,
          isDesktop: false,
          onAdd: onAdicionarMidia,
          onRemover: onRemoverMidia,
        ),

        const SizedBox(height: 14),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes_outlined, size: 15, color: AppColors.ink2),
                  const SizedBox(width: 6),
                  Text('Observação',
                      style: TextStyle(fontFamily: 'Inter',
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                os.observacoes != null && os.observacoes!.isNotEmpty
                    ? os.observacoes!
                    : 'Nenhuma observação registrada.',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 13,
                  color: os.observacoes != null && os.observacoes!.isNotEmpty
                      ? AppColors.ink2
                      : AppColors.ink3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: Text('Criado por ${os.criadoPorNome}',
              style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Mobile tab: Peças ─────────────────────────────────────────────────────────

class _PecasTab extends StatelessWidget {
  const _PecasTab({
    required this.os,
    required this.pecas,
    required this.podeEditar,
    required this.onAdicionarPeca,
    required this.onRemoverItem,
    required this.onAdicionarDesconto,
    required this.onRemoverDesconto,
  });

  final OrdemServicoDetalhe os;
  final List<ItemOs> pecas;
  final bool podeEditar;
  final VoidCallback onAdicionarPeca;
  final void Function(ItemOs) onRemoverItem;
  final VoidCallback onAdicionarDesconto;
  final void Function(DescontoOs) onRemoverDesconto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
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
        const SizedBox(height: 14),

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
                _TotalRow('Descontos', -os.totalDescontos, color: AppColors.danger),
                const SizedBox(height: 6),
              ],
              _TotalRow('Total', os.total - os.totalDescontos, bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile tab: Histórico ─────────────────────────────────────────────────────

class _HistoricoTab extends StatelessWidget {
  const _HistoricoTab();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 40, color: AppColors.ink3),
            const SizedBox(height: 10),
            Text('Histórico em breve',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.ink2)),
          ],
        ),
      );
}

// ── Vehicle card (mobile) ─────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.os});
  final OrdemServicoDetalhe os;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_outlined, size: 22, color: AppColors.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(os.veiculoDescricao,
                      style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  if (os.veiculoCor != null)
                    Text(os.veiculoCor!,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
                ],
              ),
            ),
            if (os.veiculoPlaca != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sidebarBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  os.veiculoPlaca!,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ── Client card (mobile) ──────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.os,
    required this.podeEditar,
    required this.onEditar,
  });
  final OrdemServicoDetalhe os;
  final bool podeEditar;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    os.clienteNome.isNotEmpty ? os.clienteNome[0].toUpperCase() : '?',
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(os.clienteNome,
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      if (os.clienteTelefone != null)
                        Text(os.clienteTelefone!,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
                    ],
                  ),
                ),
                if (podeEditar)
                  IconButton(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.ink2,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (os.formaPagamento != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payment_outlined, size: 14, color: AppColors.ink2),
                  const SizedBox(width: 6),
                  Text(
                    _formasPagamentoLabels[os.formaPagamento] ?? os.formaPagamento!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

// ── Desktop action buttons (topbar) ──────────────────────────────────────────

class _DesktopActions extends StatelessWidget {
  const _DesktopActions({
    required this.os,
    required this.loading,
    required this.primaryLabel,
    required this.onImprimir,
    required this.onAlterarStatus,
    required this.onPrimaryAction,
    required this.onExcluir,
    required this.onEditarConclusao,
    this.onRecibo,
  });

  final OrdemServicoDetalhe os;
  final bool loading;
  final String? primaryLabel;
  final VoidCallback onImprimir;
  final VoidCallback? onRecibo;
  final VoidCallback onAlterarStatus;
  final VoidCallback onPrimaryAction;
  final VoidCallback onExcluir;
  final VoidCallback onEditarConclusao;

  static final _btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  @override
  Widget build(BuildContext context) {
    final proximos = _statusTransicoes[os.status] ?? [];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Imprimir
        OutlinedButton.icon(
          onPressed: onImprimir,
          icon: const Icon(Icons.print_outlined, size: 15),
          label: const Text('Imprimir'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink2,
            side: const BorderSide(color: AppColors.line),
            shape: _btnShape,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        if (onRecibo != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onRecibo,
            icon: const Icon(Icons.receipt_long_outlined, size: 15),
            label: const Text('Recibo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade400),
              shape: _btnShape,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        if (proximos.isNotEmpty) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: loading ? null : onAlterarStatus,
            icon: const Icon(Icons.swap_horiz, size: 15),
            label: const Text('Mudar status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink2,
              side: const BorderSide(color: AppColors.line),
              shape: _btnShape,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        if (primaryLabel != null) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: loading ? null : onPrimaryAction,
            icon: const Icon(Icons.check_circle_outline, size: 15),
            label: Text(primaryLabel!),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.sidebarBg,
              shape: _btnShape,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: AppColors.ink2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (v) {
            if (v == 'editar') onEditarConclusao();
            if (v == 'excluir') onExcluir();
          },
          itemBuilder: (_) => [
            if (os.status != 'Entregue')
              PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink2),
                  const SizedBox(width: 8),
                  Text('Editar OS', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                ]),
              ),
            if (os.status == 'Aberta')
              PopupMenuItem(
                value: 'excluir',
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text('Excluir OS', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.danger)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Desktop: Veículo card ─────────────────────────────────────────────────────

class _DesktopVeiculoCard extends StatelessWidget {
  const _DesktopVeiculoCard({required this.os});
  final OrdemServicoDetalhe os;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 15, color: AppColors.ink2),
                const SizedBox(width: 6),
                Text('Veículo',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
                const Spacer(),
                // placeholder Histórico do veículo
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    textStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text('Histórico'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetaCell('MODELO', os.veiculoDescricao),
                if (os.veiculoCor != null) ...[
                  const SizedBox(width: 24),
                  _MetaCell('COR', os.veiculoCor!),
                ],
                if (os.veiculoPlaca != null) ...[
                  const SizedBox(width: 24),
                  _MetaCell('PLACA', os.veiculoPlaca!, mono: true),
                ],
              ],
            ),
          ],
        ),
      );
}

class _MetaCell extends StatelessWidget {
  const _MetaCell(this.label, this.value, {this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.ink3, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: mono
                  ? const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 1.2,
                    )
                  : TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      );
}

// ── Desktop: Cliente card ─────────────────────────────────────────────────────

class _DesktopClienteCard extends StatelessWidget {
  const _DesktopClienteCard({
    required this.os,
    required this.podeEditar,
    required this.onEditar,
  });
  final OrdemServicoDetalhe os;
  final bool podeEditar;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) => _Section(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                os.clienteNome.isNotEmpty ? os.clienteNome[0].toUpperCase() : '?',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(os.clienteNome,
                      style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  if (os.clienteTelefone != null)
                    Text(os.clienteTelefone!,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
                ],
              ),
            ),
            if (os.clienteTelefone != null)
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message_outlined, size: 14),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ok,
                  side: const BorderSide(color: AppColors.ok),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            if (podeEditar) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 17),
                color: AppColors.ink2,
                tooltip: 'Editar OS',
              ),
            ],
          ],
        ),
      );
}

// ── Sidebar: Resumo financeiro ────────────────────────────────────────────────

class _ResumoFinanceiroCard extends StatelessWidget {
  const _ResumoFinanceiroCard({
    required this.os,
    required this.podeEditar,
    required this.onAdicionarDesconto,
    required this.onRemoverDesconto,
  });
  final OrdemServicoDetalhe os;
  final bool podeEditar;
  final VoidCallback onAdicionarDesconto;
  final void Function(DescontoOs) onRemoverDesconto;

  @override
  Widget build(BuildContext context) {
    final total = os.total - os.totalDescontos;
    final pagamentoPendente = os.formaPagamento == null && os.status != 'Entregue';

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Resumo financeiro',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Spacer(),
              if (podeEditar)
                GestureDetector(
                  onTap: onAdicionarDesconto,
                  child: Text('+ Desconto',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _TotalRow('Serviços', os.totalServicos),
          const SizedBox(height: 4),
          _TotalRow('Peças', os.totalPecas),
          if (os.descontos.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final d in os.descontos)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _DescontoTile(
                  desconto: d,
                  onRemove: podeEditar ? () => onRemoverDesconto(d) : null,
                ),
              ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              Text('Total',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const Spacer(),
              Text(
                'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          if (pagamentoPendente) ...[
            const SizedBox(height: 6),
            Text('PAGAMENTO PENDENTE',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.ink3, letterSpacing: 0.5)),
          ] else if (os.formaPagamento != null) ...[
            const SizedBox(height: 6),
            Text(_formasPagamentoLabels[os.formaPagamento] ?? os.formaPagamento!,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2)),
          ],
        ],
      ),
    );
  }
}

// ── Sidebar: Histórico ────────────────────────────────────────────────────────

class _HistoricoCard extends StatelessWidget {
  const _HistoricoCard();

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_outlined, size: 15, color: AppColors.ink2),
                const SizedBox(width: 6),
                Text('Histórico',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text('Status da OS no tempo',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Em breve',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3)),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
}

// ── Sidebar: Responsável ──────────────────────────────────────────────────────

class _ResponsavelCard extends StatelessWidget {
  const _ResponsavelCard({
    required this.os,
    required this.podeEditar,
    required this.onIngressar,
    required this.onAdicionarMecanico,
    required this.onRemoverMecanico,
  });
  final OrdemServicoDetalhe os;
  final bool podeEditar;
  final VoidCallback onIngressar;
  final VoidCallback onAdicionarMecanico;
  final void Function(OsMecanico) onRemoverMecanico;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('Responsável',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (podeEditar)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onIngressar,
                        child: Text('Ingressar',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onAdicionarMecanico,
                        child: Text('+ Adicionar',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
              ],
            ),
            if (os.mecanicos.isEmpty) ...[
              const SizedBox(height: 10),
              Text('Nenhum mecânico atribuído.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3)),
            ] else ...[
              const SizedBox(height: 8),
              for (int i = 0; i < os.mecanicos.length; i++) ...[
                if (i > 0) const Divider(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.accentSoft,
                      child: Text(os.mecanicos[i].nome[0].toUpperCase(),
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(os.mecanicos[i].nome,
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Text(os.mecanicos[i].cargo,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2)),
                        ],
                      ),
                    ),
                    if (podeEditar)
                      TextButton(
                        onPressed: () => onRemoverMecanico(os.mecanicos[i]),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink2,
                          textStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Trocar'),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      );
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
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
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 6)),
      );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
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
          Icon(icon, size: 16, color: AppColors.ink2),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
          ),
        ],
      );
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.text, {this.color = AppColors.ink2});
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
    final effectiveColor = color ?? (bold ? AppColors.ink : AppColors.ink2);
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
          const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(desconto.descricao,
                style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          ),
          Text(
            '- R\$ ${desconto.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 14),
            color: AppColors.ink2,
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
              backgroundColor: AppColors.accentSoft,
              child: Text(mecanico.nome[0].toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mecanico.nome,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text(mecanico.cargo, style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.ink2,
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
                      style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                  Text(
                    '${item.quantidade % 1 == 0 ? item.quantidade.toInt() : item.quantidade} × R\$ ${item.valorUnitario.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                  ),
                  if (item.origemPeca != null)
                    Text(_origensLabels[item.origemPeca] ?? item.origemPeca!,
                        style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.ink2,
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Alterar status',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('Status atual: ${_statusLabels[statusAtual]}',
                style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
            const SizedBox(height: 20),
            for (final s in proximos) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context, s),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: (_statusColors[s] ?? AppColors.accent).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (_statusColors[s] ?? AppColors.accent).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _statusColors[s] ?? AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusLabels[s] ?? s,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _statusColors[s] ?? AppColors.accent,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: _statusColors[s] ?? AppColors.accent),
                    ],
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _selecionado == null ? null : () => Navigator.pop(context, _selecionado),
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
        labelStyle: const TextStyle(color: AppColors.ink2, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canSave
                        ? () => Navigator.pop(context, {
                              'descricao': _descCtrl.text.trim(),
                              'valor': double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0,
                            })
                        : null,
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
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.ink2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value != null ? _fmtDate(value) : label,
                  style: TextStyle(
                    fontSize: 13,
                    color: value != null ? AppColors.ink : AppColors.ink2,
                  ),
                ),
              ),
              if (canClear && value != null)
                GestureDetector(
                  onTap: () => setState(() => _previsaoEntrega = null),
                  child: const Icon(Icons.close, size: 14, color: AppColors.ink2),
                ),
            ],
          ),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.ink2, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data de entrada', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
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
                        const Text('Previsão entrega', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
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
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, {
                              'formaPagamento': _formaPagamento,
                              'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                              'previsaoEntrega': _previsaoEntrega?.toIso8601String(),
                              'dataEntrada': _dataEntrada.toIso8601String(),
                            }),
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

// ── Fotos e vídeos card ───────────────────────────────────────────────────────

class _FotosVideosCard extends StatefulWidget {
  const _FotosVideosCard({
    required this.midias,
    required this.podeEditar,
    required this.isDesktop,
    required this.onAdd,
    required this.onRemover,
  });

  final List<OsMidia> midias;
  final bool podeEditar;
  final bool isDesktop;
  final Future<void> Function(Uint8List bytes, String filename) onAdd;
  final Future<void> Function(OsMidia) onRemover;

  @override
  State<_FotosVideosCard> createState() => _FotosVideosCardState();
}

class _FotosVideosCardState extends State<_FotosVideosCard> {
  bool _picking = false;

  Future<void> _pick(Future<({Uint8List bytes, String name})?> Function() picker) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await picker();
      if (result == null || !mounted) return;
      await widget.onAdd(result.bytes, result.name);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Widget _thumb(OsMidia m) {
    final thumbSize = widget.isDesktop ? 90.0 : 80.0;
    return SizedBox(
      width: thumbSize,
      height: thumbSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: m.isVideo
                ? Container(
                    width: thumbSize,
                    height: thumbSize,
                    color: AppColors.surface2,
                    child: const Center(
                      child: Icon(Icons.videocam, size: 28, color: AppColors.ink2),
                    ),
                  )
                : Image.network(
                    '$kBaseUrl${m.url}',
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: thumbSize,
                      height: thumbSize,
                      color: AppColors.surface2,
                      child: const Icon(Icons.broken_image, color: AppColors.ink3),
                    ),
                  ),
          ),
          if (m.isVideo)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xAA000000),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('VÍD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    )),
              ),
            ),
          if (widget.podeEditar)
            Positioned(
              top: -5,
              right: -5,
              child: GestureDetector(
                onTap: () => widget.onRemover(m),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, size: 15, color: AppColors.ink2),
              const SizedBox(width: 6),
              Text('Fotos e vídeos',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              if (widget.midias.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${widget.midias.length}',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2)),
                ),
              ],
              const Spacer(),
              if (widget.podeEditar && widget.isDesktop) ...[
                _HeaderBtn(Icons.photo_library_outlined, 'Galeria foto',
                    _picking ? () {} : () => _pick(pickImageBytes)),
                _HeaderBtn(Icons.videocam_outlined, 'Vídeo',
                    _picking ? () {} : () => _pick(pickVideoBytes)),
              ],
            ],
          ),

          // Mobile action buttons
          if (widget.podeEditar && !widget.isDesktop) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MidiaActionBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Tirar foto',
                    onTap: _picking ? null : () => _pick(capturePhotoBytes),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MidiaActionBtn(
                    icon: Icons.videocam_outlined,
                    label: 'Gravar vídeo',
                    onTap: _picking ? null : () => _pick(captureVideoBytes),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MidiaActionBtn(
              icon: Icons.photo_library_outlined,
              label: 'Galeria',
              onTap: _picking ? null : () => _pick(pickImageBytes),
            ),
          ],

          if (_picking) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.accent,
              backgroundColor: AppColors.surface2,
            ),
          ],

          if (widget.midias.isEmpty) ...[
            const SizedBox(height: 10),
            Text('Nenhuma foto ou vídeo registrado.',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3)),
          ] else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.midias.map(_thumb).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MidiaActionBtn extends StatelessWidget {
  const _MidiaActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: onTap != null ? AppColors.accent : AppColors.ink3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? AppColors.accent : AppColors.ink3,
                  )),
            ],
          ),
        ),
      );
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
        labelStyle: const TextStyle(color: AppColors.ink2, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
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
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
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
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canSave ? _salvar : null,
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
