import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/recarregavel.dart';
import '../../features/admin/presentation/admin_notifier.dart';
import '../../features/assinatura/presentation/assinatura_notifier.dart';
import '../../features/clientes/presentation/cliente_detalhe_notifier.dart';
import '../../features/clientes/presentation/clientes_notifier.dart';
import '../../features/estoque/presentation/estoque_notifier.dart';
import '../../features/estoque/presentation/fornecedores_notifier.dart';
import '../../features/funcionarios/presentation/funcionario_detalhe_notifier.dart';
import '../../features/funcionarios/presentation/funcionarios_notifier.dart';
import '../../features/gerencial/presentation/gerencial_notifier.dart';
import '../../features/oficinas/presentation/oficinas_notifier.dart';
import '../../features/ordens_servico/presentation/ordens_servico_notifier.dart';
import '../../features/pagamentos/presentation/pagamentos_notifier.dart';
import '../../features/painel/presentation/painel_notifier.dart';
import '../../features/receitas/presentation/receitas_notifier.dart';
import '../../features/veiculos/presentation/veiculos_notifier.dart';

/// As abas do shell (StatefulShellRoute) ficam vivas para guardar scroll e
/// estado, então os dados delas nunca são descartados e ficam velhos. Ao voltar
/// para uma aba, ou para o app, isto busca de novo os dados daquela aba:
/// - listas com filtro/busca: recarregam mantendo filtros e o que já foi carregado;
/// - o resto é invalidado (o Riverpod mantém o valor antigo na tela enquanto busca).
/// Só o que está em uso é recarregado; o resto já busca do zero ao abrir.
void recarregarAba(WidgetRef ref, int aba) {
  switch (aba) {
    case 0: // Painel
      ref.invalidate(painelOperacionalProvider);
      ref.invalidate(gerencialDashboardProvider);
    case 1: // OS
      _lista(ref, ordensServicoNotifierProvider);
      ref.invalidate(osResumoProvider);
      ref.invalidate(osDetalheProvider);
    case 2: // Clientes
      _lista(ref, clientesNotifierProvider);
      ref.invalidate(clienteDetalheProvider);
    case 3: // Estoque e fornecedores
      _lista(ref, produtosNotifierProvider);
      _lista(ref, fornecedoresNotifierProvider);
      ref.invalidate(resumoEstoqueProvider);
      ref.invalidate(fornecedoresEstoqueProvider);
      ref.invalidate(movimentacoesProvider);
    case 4: // Mais
      _lista(ref, veiculosNotifierProvider);
      _lista(ref, funcionariosNotifierProvider);
      _lista(ref, pagamentosNotifierProvider);
      ref.invalidate(funcionarioDetalheProvider);
      ref.invalidate(pagamentoDetalheProvider);
      ref.invalidate(osAbertasProvider);
      ref.invalidate(historicoPagamentosProvider);
      ref.invalidate(dashboardSocioProvider);
      ref.invalidate(receitasDashboardProvider);
      ref.invalidate(gerencialDashboardProvider);
      ref.invalidate(oficinasNotifierProvider);
      ref.invalidate(gruposAdminProvider);
      ref.invalidate(assinaturaProvider);
  }
}

void _lista<N extends RecarregavelEmSegundoPlano<T>, T>(
  WidgetRef ref,
  AutoDisposeAsyncNotifierProvider<N, T> provider,
) {
  if (ref.exists(provider)) ref.read(provider.notifier).recarregarEmSegundoPlano();
}
