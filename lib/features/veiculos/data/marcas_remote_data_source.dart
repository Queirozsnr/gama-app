import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/marca.dart';

class MarcasRemoteDataSource {
  MarcasRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Marca>> listar({String? busca}) async {
    final resp = await _dio.get('/marcas', queryParameters: {
      if (busca != null && busca.isNotEmpty) 'busca': busca,
    });
    return (resp.data as List).map((e) => Marca.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final marcasRemoteDataSourceProvider = Provider((ref) {
  return MarcasRemoteDataSource(ref.read(dioClientProvider));
});
