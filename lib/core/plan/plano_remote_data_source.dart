import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'plan_limits_model.dart';

class PlanoRemoteDataSource {
  PlanoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PlanLimits> obterLimites() async {
    final response = await _dio.get('/plano/limites');
    return PlanLimits.fromJson(response.data as Map<String, dynamic>);
  }
}

final planoRemoteDataSourceProvider = Provider<PlanoRemoteDataSource>(
  (ref) => PlanoRemoteDataSource(ref.watch(dioClientProvider)),
);
