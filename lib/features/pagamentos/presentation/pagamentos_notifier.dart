import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pagamentos_remote_data_source.dart';
import '../domain/pagamento.dart';

class PagamentosNotifier extends AutoDisposeAsyncNotifier<List<FuncionarioAcumulado>> {
  @override
  Future<List<FuncionarioAcumulado>> build() =>
      ref.read(pagamentosRemoteDataSourceProvider).listarFuncionarios();

  Future<void> refresh() => update((_) => ref.read(pagamentosRemoteDataSourceProvider).listarFuncionarios());
}

final pagamentosNotifierProvider =
    AsyncNotifierProvider.autoDispose<PagamentosNotifier, List<FuncionarioAcumulado>>(
  PagamentosNotifier.new,
);

// Provider para OS abertas de um funcionário específico
final osAbertasProvider = FutureProvider.autoDispose.family<List<OsAberta>, int>(
  (ref, funcionarioId) =>
      ref.read(pagamentosRemoteDataSourceProvider).listarOsAbertas(funcionarioId),
);

// Provider para detalhe de um pagamento
final pagamentoDetalheProvider = FutureProvider.autoDispose.family<PagamentoDetalhe, int>(
  (ref, id) => ref.read(pagamentosRemoteDataSourceProvider).obter(id),
);

// Provider para histórico de pagamentos de um funcionário
final historicoPagamentosProvider = FutureProvider.autoDispose.family<List<PagamentoResumo>, int>(
  (ref, funcionarioId) =>
      ref.read(pagamentosRemoteDataSourceProvider).listarHistorico(funcionarioId),
);
