import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/gerencial_dashboard.dart';

class GerencialRemoteDataSource {
  GerencialRemoteDataSource(this._dio);
  final Dio _dio;

  Future<GerencialDashboard> obterDashboard(
      DateTime dataInicio, DateTime dataFim) async {
    final response = await _dio.get(
      '/gerencial/dashboard',
      queryParameters: {
        'dataInicio': dataInicio.toIso8601String(),
        'dataFim': dataFim.toIso8601String(),
      },
    );
    return GerencialDashboard.fromJson(response.data as Map<String, dynamic>);
  }
}

final gerencialRemoteDataSourceProvider = Provider<GerencialRemoteDataSource>(
  (ref) => GerencialRemoteDataSource(ref.watch(dioClientProvider)),
);
