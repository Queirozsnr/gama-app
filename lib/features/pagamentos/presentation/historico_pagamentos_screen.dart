import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/pagamento.dart';
import 'pagamento_detalhe_screen.dart';
import 'pagamentos_notifier.dart';

class HistoricoPagamentosScreen extends ConsumerWidget {
  const HistoricoPagamentosScreen({
    super.key,
    required this.funcionarioId,
    required this.funcionarioNome,
  });

  final int funcionarioId;
  final String funcionarioNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(historicoPagamentosProvider(funcionarioId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico de Pagamentos', style: TextStyle(fontSize: 16)),
            Text(
              funcionarioNome,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar histórico',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(historicoPagamentosProvider(funcionarioId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (pagamentos) {
          if (pagamentos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text('Nenhum pagamento registrado',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(historicoPagamentosProvider(funcionarioId)),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: pagamentos.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) => _PagamentoResumoTile(pagamento: pagamentos[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PagamentoResumoTile extends StatelessWidget {
  const _PagamentoResumoTile({required this.pagamento});
  final PagamentoResumo pagamento;

  Color get _statusColor =>
      pagamento.status == 'Pago' ? AppColors.success : AppColors.warning;

  Color get _statusBgColor =>
      pagamento.status == 'Pago' ? AppColors.successLight : AppColors.warningLight;

  String get _dataLabel {
    final d = pagamento.status == 'Pago' && pagamento.pagoEm != null
        ? pagamento.pagoEm!
        : pagamento.criadoEm;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get _dataSubtitle => pagamento.status == 'Pago' ? 'Pago em $_dataLabel' : 'Criado em $_dataLabel';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pagamento.status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
          const Spacer(),
          Text(
            'R\$ ${pagamento.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_dataSubtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PagamentoDetalheScreen(pagamentoId: pagamento.id),
        ),
      ),
    );
  }
}
