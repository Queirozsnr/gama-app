import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';

// Resumo dos cards
final resumoEstoqueProvider = FutureProvider.autoDispose<ResumoEstoque>(
  (ref) => ref.read(estoqueDataSourceProvider).obterResumo(),
);

// Fornecedores (para dropdown)
final fornecedoresEstoqueProvider = FutureProvider.autoDispose<List<FornecedorEstoque>>(
  (ref) => ref.read(estoqueDataSourceProvider).listarFornecedores(),
);

// Movimentações de um produto
final movimentacoesProvider = FutureProvider.autoDispose.family<List<MovimentacaoEstoque>, int>(
  (ref, produtoId) => ref.read(estoqueDataSourceProvider).listarMovimentacoes(produtoId),
);

// Lista de produtos com filtros
class ProdutoFiltro {
  const ProdutoFiltro({this.busca, this.categoria, this.fornecedorId, this.status});
  final String? busca;
  final String? categoria;
  final int? fornecedorId;
  final String? status;

  ProdutoFiltro copyWith({
    Object? busca = _sentinel,
    Object? categoria = _sentinel,
    Object? fornecedorId = _sentinel,
    Object? status = _sentinel,
  }) =>
      ProdutoFiltro(
        busca: busca == _sentinel ? this.busca : busca as String?,
        categoria: categoria == _sentinel ? this.categoria : categoria as String?,
        fornecedorId: fornecedorId == _sentinel ? this.fornecedorId : fornecedorId as int?,
        status: status == _sentinel ? this.status : status as String?,
      );
}

const _sentinel = Object();

class ProdutosNotifier extends AutoDisposeAsyncNotifier<List<ProdutoListagem>> {
  var _filtro = const ProdutoFiltro();

  ProdutoFiltro get filtro => _filtro;

  @override
  Future<List<ProdutoListagem>> build() => _fetch();

  Future<List<ProdutoListagem>> _fetch() =>
      ref.read(estoqueDataSourceProvider).listarProdutos(
            busca: _filtro.busca,
            categoria: _filtro.categoria,
            fornecedorId: _filtro.fornecedorId,
            status: _filtro.status,
          );

  Future<void> aplicarFiltro(ProdutoFiltro filtro) async {
    _filtro = filtro;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final produtosNotifierProvider =
    AsyncNotifierProvider.autoDispose<ProdutosNotifier, List<ProdutoListagem>>(
  ProdutosNotifier.new,
);
