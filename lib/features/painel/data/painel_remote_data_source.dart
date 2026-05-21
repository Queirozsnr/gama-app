import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/painel_operacional.dart';

class PainelRemoteDataSource {
  PainelRemoteDataSource(this._dio);
  final Dio _dio;

  Future<PainelOperacional> obterOperacional(
      DateTime dataInicio, DateTime dataFim) async {
    final response = await _dio.get('/painel/operacional', queryParameters: {
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
    });
    return PainelOperacional.fromJson(response.data as Map<String, dynamic>);
  }
}

final painelRemoteDataSourceProvider = Provider<PainelRemoteDataSource>(
  (ref) => PainelRemoteDataSource(ref.watch(dioClientProvider)),
);
