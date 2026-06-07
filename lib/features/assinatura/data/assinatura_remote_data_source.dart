import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/assinatura_models.dart';

class AssinaturaRemoteDataSource {
  AssinaturaRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AssinaturaDetalhes> obterDetalhes() async {
    final response = await _dio.get('/assinatura/detalhes');
    return AssinaturaDetalhes.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> mudarPlano(NomePlano plano, CicloCobranca ciclo) async {
    await _dio.post('/assinatura/mudar-plano', data: {
      'plano': plano.name,
      'ciclo': ciclo.name,
    });
  }

  Future<void> cancelarPlano() async {
    await _dio.post('/assinatura/cancelar');
  }
}

final assinaturaRemoteDataSourceProvider = Provider<AssinaturaRemoteDataSource>(
  (ref) => AssinaturaRemoteDataSource(ref.watch(dioClientProvider)),
);
