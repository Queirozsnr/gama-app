import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';

class FornecedoresNotifier
    extends AutoDisposeAsyncNotifier<List<FornecedorEstoque>> {
  @override
  Future<List<FornecedorEstoque>> build() =>
      ref.read(estoqueDataSourceProvider).listarFornecedores();

  Future<void> buscar(String? q) => update((_) async {
        final lista =
            await ref.read(estoqueDataSourceProvider).listarFornecedores();
        if (q == null || q.isEmpty) return lista;
        final lower = q.toLowerCase();
        return lista
            .where((f) =>
                f.nome.toLowerCase().contains(lower) ||
                (f.email?.toLowerCase().contains(lower) ?? false) ||
                (f.telefone?.contains(lower) ?? false))
            .toList();
      });

  Future<void> criar({
    required String nome,
    String? telefone,
    String? email,
  }) async {
    await ref.read(estoqueDataSourceProvider).criarFornecedor(
          nome: nome,
          telefone: telefone,
          email: email,
        );
    ref.invalidateSelf();
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    String? telefone,
    String? email,
  }) async {
    await ref.read(estoqueDataSourceProvider).atualizarFornecedor(
          id: id,
          nome: nome,
          telefone: telefone,
          email: email,
        );
    ref.invalidateSelf();
  }

  Future<void> excluir(int id) async {
    await ref.read(estoqueDataSourceProvider).excluirFornecedor(id);
    ref.invalidateSelf();
  }
}

final fornecedoresNotifierProvider =
    AsyncNotifierProvider.autoDispose<FornecedoresNotifier, List<FornecedorEstoque>>(
  FornecedoresNotifier.new,
);
