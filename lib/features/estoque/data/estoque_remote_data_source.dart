import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/estoque.dart';

class EstoqueRemoteDataSource {
  EstoqueRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ResumoEstoque> obterResumo() async {
    final r = await _dio.get('/estoque/resumo');
    return ResumoEstoque.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ProdutoListagem>> listarProdutos({
    String? busca,
    String? categoria,
    int? fornecedorId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'busca': busca?.isNotEmpty == true ? busca : null,
      'categoria': categoria,
      'fornecedorId': fornecedorId,
      'status': status,
    }..removeWhere((_, v) => v == null);
    final r = await _dio.get('/estoque/produtos', queryParameters: params);
    return (r.data as List)
        .map((e) => ProdutoListagem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FornecedorEstoque>> listarFornecedores() async {
    final r = await _dio.get('/estoque/fornecedores');
    return (r.data as List)
        .map((e) => FornecedorEstoque.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MovimentacaoEstoque>> listarMovimentacoes(int produtoId) async {
    final r = await _dio.get('/estoque/produtos/$produtoId/movimentacoes');
    return (r.data as List)
        .map((e) => MovimentacaoEstoque.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> criarProduto({
    required String nome,
    required String codigo,
    required String categoria,
    required String unidade,
    required double quantidadeInicial,
    required double quantidadeMinima,
    required double precoCusto,
    required double precoVenda,
    int? fornecedorId,
  }) async {
    final r = await _dio.post('/estoque/produtos', data: <String, dynamic>{
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
      'unidade': unidade,
      'quantidadeInicial': quantidadeInicial,
      'quantidadeMinima': quantidadeMinima,
      'precoCusto': precoCusto,
      'precoVenda': precoVenda,
      'fornecedorId': fornecedorId,
    }..removeWhere((_, v) => v == null));
    return (r.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizarProduto({
    required int id,
    required String nome,
    required String codigo,
    required String categoria,
    required String unidade,
    required double quantidadeMinima,
    required double precoCusto,
    required double precoVenda,
  }) async {
    await _dio.put('/estoque/produtos/$id', data: {
      'nome': nome,
      'codigo': codigo,
      'categoria': categoria,
      'unidade': unidade,
      'quantidadeMinima': quantidadeMinima,
      'precoCusto': precoCusto,
      'precoVenda': precoVenda,
    });
  }

  Future<void> excluirProduto(int id) async {
    await _dio.delete('/estoque/produtos/$id');
  }

  Future<void> registrarMovimentacao({
    required int produtoId,
    int? fornecedorId,
    required String tipo,
    required double quantidade,
    double? precoUnitario,
    String? observacao,
  }) async {
    await _dio.post('/estoque/movimentacoes', data: <String, dynamic>{
      'produtoId': produtoId,
      'fornecedorId': fornecedorId,
      'tipo': tipo,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
      'observacao': observacao,
    }..removeWhere((_, v) => v == null));
  }

  Future<int> criarFornecedor({
    required String nome,
    String? telefone,
    String? email,
  }) async {
    final r = await _dio.post('/estoque/fornecedores', data: <String, dynamic>{
      'nome': nome,
      'telefone': telefone,
      'email': email,
    }..removeWhere((_, v) => v == null));
    return (r.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizarFornecedor({
    required int id,
    required String nome,
    String? telefone,
    String? email,
  }) async {
    await _dio.put('/estoque/fornecedores/$id', data: <String, dynamic>{
      'nome': nome,
      'telefone': telefone,
      'email': email,
    }..removeWhere((_, v) => v == null));
  }

  Future<void> excluirFornecedor(int id) async {
    await _dio.delete('/estoque/fornecedores/$id');
  }
}

final estoqueDataSourceProvider = Provider<EstoqueRemoteDataSource>(
  (ref) => EstoqueRemoteDataSource(ref.watch(dioClientProvider)),
);
