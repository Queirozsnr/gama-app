import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clientes/presentation/clientes_notifier.dart';
import '../../features/estoque/presentation/estoque_notifier.dart';
import '../../features/estoque/presentation/fornecedores_notifier.dart';
import '../../features/funcionarios/presentation/funcionarios_notifier.dart';
import '../../features/gerencial/presentation/gerencial_notifier.dart';
import '../../features/ordens_servico/presentation/ordens_servico_notifier.dart';
import '../../features/pagamentos/presentation/pagamentos_notifier.dart';
import '../../features/painel/presentation/painel_notifier.dart';
import '../../features/receitas/presentation/receitas_notifier.dart';
import '../../features/veiculos/presentation/veiculos_notifier.dart';

/// Invalida todos os providers de dados após troca de oficina.
/// Chamado sempre que [AuthNotifier.selectOficina] tem sucesso.
void invalidateAllData(WidgetRef ref) {
  ref.invalidate(ordensServicoNotifierProvider);
  ref.invalidate(clientesNotifierProvider);
  ref.invalidate(veiculosNotifierProvider);
  ref.invalidate(produtosNotifierProvider);
  ref.invalidate(resumoEstoqueProvider);
  ref.invalidate(fornecedoresNotifierProvider);
  ref.invalidate(funcionariosNotifierProvider);
  ref.invalidate(pagamentosNotifierProvider);
  ref.invalidate(painelOperacionalProvider);
  ref.invalidate(receitasDashboardProvider);
  ref.invalidate(gerencialDashboardProvider);
}
