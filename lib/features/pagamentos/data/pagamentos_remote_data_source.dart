import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/pagamento.dart';

class PagamentosRemoteDataSource {
  PagamentosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<FuncionarioAcumulado>> listarFuncionarios() async {
    final response = await _dio.get('/pagamentos/funcionarios');
    return (response.data as List)
        .map((e) => FuncionarioAcumulado.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OsAberta>> listarOsAbertas(int funcionarioId) async {
    final response = await _dio.get('/pagamentos/funcionarios/$funcionarioId/os-abertas');
    return (response.data as List)
        .map((e) => OsAberta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PagamentoDetalhe> obter(int id) async {
    final response = await _dio.get('/pagamentos/$id');
    return PagamentoDetalhe.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> criar(int funcionarioId, List<int> ordemServicoIds) async {
    final response = await _dio.post('/pagamentos', data: {
      'funcionarioId': funcionarioId,
      'ordemServicoIds': ordemServicoIds,
    });
    return (response.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizar(int id, List<int> ordemServicoIds) async {
    await _dio.put('/pagamentos/$id', data: {'ordemServicoIds': ordemServicoIds});
  }

  Future<void> pagar(int id) async {
    await _dio.patch('/pagamentos/$id/pagar');
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/pagamentos/$id');
  }

  Future<List<PagamentoResumo>> listarHistorico(int funcionarioId) async {
    final response = await _dio.get('/pagamentos/funcionarios/$funcionarioId/historico');
    return (response.data as List)
        .map((e) => PagamentoResumo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final pagamentosRemoteDataSourceProvider = Provider<PagamentosRemoteDataSource>(
  (ref) => PagamentosRemoteDataSource(ref.watch(dioClientProvider)),
);
