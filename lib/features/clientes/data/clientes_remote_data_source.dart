import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cliente.dart';

class ClientesRemoteDataSource {
  ClientesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Cliente>> listar({String? busca}) async {
    final response = await _dio.get('/clientes', queryParameters: busca != null ? {'busca': busca} : null);
    return (response.data as List).map((e) => Cliente.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Cliente> obter(int id) async {
    final response = await _dio.get('/clientes/$id');
    return Cliente.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> criar(Map<String, dynamic> data) async {
    final response = await _dio.post('/clientes', data: data);
    return (response.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await _dio.put('/clientes/$id', data: data);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/clientes/$id');
  }
}

final clientesRemoteDataSourceProvider = Provider<ClientesRemoteDataSource>(
  (ref) => ClientesRemoteDataSource(ref.watch(dioClientProvider)),
);
