import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../domain/pagamento.dart';
import 'historico_pagamentos_screen.dart';
import 'novo_pagamento_screen.dart';
import 'pagamento_detalhe_screen.dart';
import 'pagamentos_notifier.dart';

class PagamentosScreen extends ConsumerWidget {
  const PagamentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pagamentosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar pagamentos', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(pagamentosNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (funcionarios) {
          if (funcionarios.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text('Nenhum funcionário cadastrado', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pagamentosNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: funcionarios.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _FuncionarioTile(funcionario: funcionarios[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FuncionarioTile extends StatelessWidget {
  const _FuncionarioTile({required this.funcionario});
  final FuncionarioAcumulado funcionario;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  String get _tipoLabel => switch (funcionario.tipoRemuneracao) {
        'Porcentagem' => '${funcionario.porcentagem ?? 0}% comissão',
        'Fixo' => 'Fixo mensal',
        'Socio' => 'Sócio',
        _ => funcionario.tipoRemuneracao,
      };

  String get _ultimoPagamento {
    if (funcionario.ultimoPagamentoEm == null) return 'Nunca pago';
    final d = funcionario.ultimoPagamentoEm!;
    return 'Último: ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final temAcumulado = funcionario.osAbertasCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: GamaAvatar(initials: _initials, size: 44),
      title: Text(
        funcionario.nome,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(_tipoLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(_ultimoPagamento, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (funcionario.pagamentoPendenteId != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pendente',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.warning),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    'R\$ ${funcionario.valorAcumulado.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: temAcumulado ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${funcionario.osAbertasCount} OS em aberto',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 10),
            icon: const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
            tooltip: 'Histórico',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoricoPagamentosScreen(
                  funcionarioId: funcionario.funcionarioId,
                  funcionarioNome: funcionario.nome,
                ),
              ),
            ),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => funcionario.pagamentoPendenteId != null
              ? PagamentoDetalheScreen(pagamentoId: funcionario.pagamentoPendenteId!)
              : NovoPagamentoScreen(funcionario: funcionario),
        ),
      ),
    );
  }
}
