import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../data/pagamentos_remote_data_source.dart';
import '../domain/pagamento.dart';
import '../../funcionarios/domain/remuneracao.dart';
import 'novo_pagamento_screen.dart';
import 'pagamentos_notifier.dart';

String _fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

class PagamentoDetalheScreen extends ConsumerWidget {
  const PagamentoDetalheScreen({super.key, required this.pagamentoId});
  final int pagamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pagamentoDetalheProvider(pagamentoId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Detalhe do pagamento'),
        backgroundColor: AppColors.sidebarBg,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.ink2)),
        ),
        data: (p) => _PagamentoDetalheBody(pagamento: p),
      ),
    );
  }
}

class _PagamentoDetalheBody extends ConsumerStatefulWidget {
  const _PagamentoDetalheBody({required this.pagamento});
  final PagamentoDetalhe pagamento;

  @override
  ConsumerState<_PagamentoDetalheBody> createState() =>
      _PagamentoDetalheBodyState();
}

class _PagamentoDetalheBodyState
    extends ConsumerState<_PagamentoDetalheBody> {
  bool _loading = false;

  PagamentoDetalhe get p => widget.pagamento;
  bool get _isPendente => p.status == 'Pendente';

  Future<void> _pagar() async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Marcar como pago',
      message: 'Confirmar pagamento de ${_fmt(p.valor)} para ${p.funcionarioNome}?',
      confirmLabel: 'Confirmar',
    );
    if (!confirmar || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(pagamentosRemoteDataSourceProvider).pagar(p.id);
      ref.invalidate(pagamentosNotifierProvider);
      ref.invalidate(pagamentoDetalheProvider(p.id));
      if (mounted) GamaSnackBar.success(context, 'Pagamento registrado!');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao registrar pagamento.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editar() async {
    final acumulado = FuncionarioAcumulado(
      funcionarioId: p.funcionarioId,
      nome: p.funcionarioNome,
      cargo: p.cargo,
      tipoRemuneracao: p.tipoRemuneracao,
      porcentagem: p.porcentagem,
      osAbertasCount: p.itens.length,
      valorAcumulado: p.valor,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => NovoPagamentoScreen(funcionario: acumulado)),
    );
  }

  Future<void> _excluir() async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir pagamento',
      message:
          'Excluir este pagamento? As OS voltarão a aparecer nos próximos cálculos.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.danger,
    );
    if (!confirmar || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(pagamentosRemoteDataSourceProvider).excluir(p.id);
      ref.invalidate(pagamentosNotifierProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao excluir pagamento.');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(pagamento: p),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              const Text(
                'OS INCLUÍDAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              ...p.itens.map((item) => _OsItemTile(item: item)),
            ],
          ),
        ),
        if (_isPendente) _Rodape(loading: _loading, onEditar: _editar, onPagar: _pagar, onExcluir: _excluir),
      ],
    );
  }
}

// ── header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.pagamento});
  final PagamentoDetalhe pagamento;

  @override
  Widget build(BuildContext context) {
    final isPago = pagamento.status == 'Pago';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pagamento.funcionarioNome,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cargoLabel(pagamento.cargo)} · '
                      '${tipoRemuneracaoLabel(pagamento.tipoRemuneracao, porcentagem: pagamento.porcentagem)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.sidebarText),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: pagamento.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _fmt(pagamento.valor),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPago ? Icons.check_circle_outline : Icons.schedule_outlined,
                size: 13,
                color: isPago ? AppColors.ok : AppColors.sidebarText,
              ),
              const SizedBox(width: 5),
              Text(
                isPago
                    ? 'Pago em ${_fmtData(pagamento.pagoEm!)}'
                    : 'Gerado em ${_fmtData(pagamento.criadoEm)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isPago ? AppColors.ok : AppColors.sidebarText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPago = status == 'Pago';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPago ? AppColors.okSoft : AppColors.warnSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPago ? AppColors.ok : AppColors.warn,
        ),
      ),
    );
  }
}

// ── OS item tile ──────────────────────────────────────────────────────────────

class _OsItemTile extends StatelessWidget {
  const _OsItemTile({required this.item});
  final PagamentoItemDetalhe item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(
            '#${item.ordemServicoId}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clienteNome,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.veiculoInfo} · ${_fmtData(item.dataEntrada)}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_fmt(item.valorContribuicao)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ok),
              ),
              Text(
                'de ${_fmt(item.totalOS)}',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── rodapé de ações ───────────────────────────────────────────────────────────

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.loading,
    required this.onEditar,
    required this.onPagar,
    required this.onExcluir,
  });

  final bool loading;
  final VoidCallback onEditar;
  final VoidCallback onPagar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: loading ? null : onExcluir,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.danger,
            tooltip: 'Excluir',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: loading ? null : onEditar,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Editar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: loading ? null : onPagar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ok,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Marcar como pago',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
