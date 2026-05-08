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

  Future<LoginResponse> selectGroup(SelectGroupRequest request) async {
    final response = await _dio.post('/auth/selecionar-grupo', data: request.toJson());
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResponse> selecionarOficina(SelectOficinaRequest request) async {
    final response = await _dio.post('/auth/selecionar-oficina', data: request.toJson());
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final response = await _dio.get('/auth/grupos');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchOficinas() async {
    final response = await _dio.get('/auth/oficinas');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioClientProvider)),
);
