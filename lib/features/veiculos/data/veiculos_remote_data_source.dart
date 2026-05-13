import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/veiculo.dart';

class VeiculosRemoteDataSource {
  VeiculosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Veiculo>> listar({String? busca, int? clienteId}) async {
    final resp = await _dio.get('/veiculos', queryParameters: {
      if (busca != null && busca.isNotEmpty) 'busca': busca,
      'clienteId': ?clienteId,
    });
    return (resp.data as List).map((e) => Veiculo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Veiculo> obter(int id) async {
    final resp = await _dio.get('/veiculos/$id');
    return Veiculo.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<int> criar(Map<String, dynamic> data) async {
    final resp = await _dio.post('/veiculos', data: data);
    return (resp.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await _dio.put('/veiculos/$id', data: data);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/veiculos/$id');
  }
}

final veiculosRemoteDataSourceProvider = Provider((ref) {
  return VeiculosRemoteDataSource(ref.read(dioClientProvider));
});
