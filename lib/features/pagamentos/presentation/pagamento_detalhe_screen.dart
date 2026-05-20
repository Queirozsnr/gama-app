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

class PagamentoDetalheScreen extends ConsumerWidget {
  const PagamentoDetalheScreen({super.key, required this.pagamentoId});
  final int pagamentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pagamentoDetalheProvider(pagamentoId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Detalhe do pagamento'),
        backgroundColor: AppColors.sidebarBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: AppColors.textSecondary)),
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
  ConsumerState<_PagamentoDetalheBody> createState() => _PagamentoDetalheBodyState();
}

class _PagamentoDetalheBodyState extends ConsumerState<_PagamentoDetalheBody> {
  bool _loading = false;

  PagamentoDetalhe get p => widget.pagamento;
  bool get _isPendente => p.status == 'Pendente';

  Future<void> _pagar() async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Marcar como pago',
      message: 'Confirmar pagamento de R\$ ${p.valor.toStringAsFixed(2).replaceAll('.', ',')} para ${p.funcionarioNome}?',
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
      MaterialPageRoute(builder: (_) => NovoPagamentoScreen(funcionario: acumulado)),
    );
  }

  Future<void> _excluir() async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir pagamento',
      message: 'Excluir este pagamento? As OS voltarão a aparecer nos próximos cálculos.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
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
        // Header do pagamento
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
                          p.funcionarioNome,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.cargo} · ${_tipoLabel(p.tipoRemuneracao, p.porcentagem)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: p.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'R\$ ${p.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              if (p.pagoEm != null)
                Text(
                  'Pago em ${_formatarData(p.pagoEm!)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success),
                )
              else
                Text(
                  'Gerado em ${_formatarData(p.criadoEm)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),

        // Lista de OS incluídas
        Expanded(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'OS incluídas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
              ),
              ...p.itens.map((item) => _OsItemTile(item: item)),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // Ações (só se Pendente)
        if (_isPendente)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _loading ? null : _excluir,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Excluir',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _editar,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _loading ? null : _pagar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Marcar como pago', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _tipoLabel(String tipo, int? pct) =>
      tipoRemuneracaoLabel(tipo, porcentagem: pct);

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isPago = status == 'Pago';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPago ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPago ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

class _OsItemTile extends StatelessWidget {
  const _OsItemTile({required this.item});
  final PagamentoItemDetalhe item;

  String get _dataFormatada {
    final d = item.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clienteNome,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(item.veiculoInfo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(_dataFormatada, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${item.valorContribuicao.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success),
              ),
              Text(
                'de R\$ ${item.totalOS.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
