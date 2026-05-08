import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_response.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post('/auth/entrar', data: request.toJson());
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SelectGroupResponse> selectGroup(SelectGroupRequest request) async {
    final response = await _dio.post(
      '/auth/selecionar-grupo',
      data: request.toJson(),
    );
    return SelectGroupResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioClientProvider)),
);
