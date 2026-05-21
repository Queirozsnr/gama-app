import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/receitas_dashboard.dart';

class ReceitasRemoteDataSource {
  ReceitasRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ReceitasDashboard> obterDashboard(
      DateTime dataInicio, DateTime dataFim) async {
    final response = await _dio.get(
      '/receitas/dashboard',
      queryParameters: {
        'dataInicio': dataInicio.toIso8601String(),
        'dataFim': dataFim.toIso8601String(),
      },
    );
    return ReceitasDashboard.fromJson(response.data as Map<String, dynamic>);
  }
}

final receitasRemoteDataSourceProvider = Provider<ReceitasRemoteDataSource>(
  (ref) => ReceitasRemoteDataSource(ref.watch(dioClientProvider)),
);
