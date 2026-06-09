import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/admin_models.dart';

class AdminRemoteDataSource {
  AdminRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<GrupoAdminItem>> listarGrupos() async {
    final response = await _dio.get('/admin/grupos');
    return (response.data as List)
        .map((e) => GrupoAdminItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> atualizarCliente({
    required int grupoId,
    required int userId,
    required String nomeUsuario,
    required String email,
    String? novaSenha,
    bool? bloqueado,
  }) async {
    await _dio.put('/admin/grupos/$grupoId', data: {
      'userId': userId,
      'nomeUsuario': nomeUsuario,
      'email': email,
      'novaSenha': novaSenha,
      if (bloqueado case final b?) 'bloqueado': b,
    });
  }

  Future<void> atualizarPlano({
    required int grupoId,
    required String plano,
    required String ciclo,
    required DateTime expiraEm,
    bool gerarFatura = false,
  }) async {
    await _dio.put('/admin/grupos/$grupoId/plano', data: {
      'plano': plano,
      'ciclo': ciclo,
      'expiraEm': expiraEm.toIso8601String(),
      'gerarFatura': gerarFatura,
    });
  }

  Future<void> marcarFaturaPaga(int grupoId, int faturaId) async {
    await _dio.patch('/admin/grupos/$grupoId/faturas/$faturaId/pagar');
  }

  Future<List<FaturaAdminItem>> listarFaturas(int grupoId) async {
    final response = await _dio.get('/admin/grupos/$grupoId/faturas');
    return (response.data as List)
        .map((e) => FaturaAdminItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registrar({
    required String nomeGrupo,
    required String nomeUsuario,
    required String email,
    required String senha,
  }) async {
    await _dio.post('/admin/registrar', data: {
      'nomeGrupoOficina': nomeGrupo,
      'nomeUsuario': nomeUsuario,
      'email': email,
      'senha': senha,
    });
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(ref.watch(dioClientProvider)),
);
