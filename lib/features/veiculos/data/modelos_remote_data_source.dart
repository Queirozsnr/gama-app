import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/modelo.dart';

class ModelosRemoteDataSource {
  ModelosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Modelo>> listar({int? marcaId, String? busca}) async {
    final resp = await _dio.get('/modelos', queryParameters: {
      'marcaId': ?marcaId,
      if (busca != null && busca.isNotEmpty) 'busca': busca,
    });
    return (resp.data as List).map((e) => Modelo.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final modelosRemoteDataSourceProvider = Provider((ref) {
  return ModelosRemoteDataSource(ref.read(dioClientProvider));
});
