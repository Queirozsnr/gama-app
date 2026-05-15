import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/oficina_model.dart';

class OficinasRemoteDataSource {
  OficinasRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<OficinaModel>> listar() async {
    final res = await _dio.get('/oficinas');
    return (res.data as List).map((e) => OficinaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> criar({required String nome, required String endereco, required String telefone}) async {
    final res = await _dio.post('/oficinas', data: {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
    });
    return (res.data['id'] as num).toInt();
  }

  Future<void> atualizar(
    int id, {
    required String nome,
    required String endereco,
    required String telefone,
    required bool ativo,
    String? telefone2,
    String? email,
    String? whatsapp,
    String? instagram,
    String? cnpj,
    String? corPadrao,
  }) async {
    await _dio.put('/oficinas/$id', data: {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'ativo': ativo,
      'telefone2': telefone2,
      'email': email,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'cnpj': cnpj,
      'corPadrao': corPadrao,
    });
  }

  Future<String> uploadLogo(int id, Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'logo': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post(
      '/oficinas/$id/logo',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data['url'] as String;
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/oficinas/$id');
  }
}

final oficinasRemoteDataSourceProvider = Provider<OficinasRemoteDataSource>(
  (ref) => OficinasRemoteDataSource(ref.watch(dioClientProvider)),
);
