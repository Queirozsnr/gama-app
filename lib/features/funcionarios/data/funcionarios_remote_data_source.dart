import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/funcionario.dart';

class FuncionariosRemoteDataSource {
  FuncionariosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Funcionario>> listar({String? busca}) async {
    final response = await _dio.get('/funcionarios', queryParameters: busca != null ? {'busca': busca} : null);
    return (response.data as List).map((e) => Funcionario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Funcionario> obter(int id) async {
    final response = await _dio.get('/funcionarios/$id');
    return Funcionario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> criar(Map<String, dynamic> data) async {
    final response = await _dio.post('/funcionarios', data: data);
    return (response.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await _dio.put('/funcionarios/$id', data: data);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/funcionarios/$id');
  }

  Future<void> resetarSenha(int id) async {
    await _dio.post('/funcionarios/$id/resetar-senha');
  }
}

final funcionariosRemoteDataSourceProvider = Provider<FuncionariosRemoteDataSource>(
  (ref) => FuncionariosRemoteDataSource(ref.watch(dioClientProvider)),
);
