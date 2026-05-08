import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/oficina_model.dart';

class OficinasRemoteDataSource {
  OficinasRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<OficinaModel>> listar() async {
    final res = await _dio.get('/oficinas');
    return (res.data as List).map((e) => OficinaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> criar({required String nome, required String endereco, required String telefone}) async {
    final res = await _dio.post('/oficinas', data: {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
    });
    return (res.data['id'] as num).toInt();
  }

  Future<void> atualizar(int id, {required String nome, required String endereco, required String telefone, required bool ativo}) async {
    await _dio.put('/oficinas/$id', data: {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'ativo': ativo,
    });
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/oficinas/$id');
  }
}

final oficinasRemoteDataSourceProvider = Provider<OficinasRemoteDataSource>(
  (ref) => OficinasRemoteDataSource(ref.watch(dioClientProvider)),
);
