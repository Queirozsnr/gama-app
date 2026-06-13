import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/midia_global.dart';

class MidiasRemoteDataSource {
  MidiasRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<MidiaGlobal> items, int total, bool hasMore})> listar({
    String? tipo,
    String? dataInicio,
    String? dataFim,
    int page = 1,
    int pageSize = 40,
  }) async {
    final resp = await _dio.get('/midias', queryParameters: {
      'tipo': ?tipo,
      'dataInicio': ?dataInicio,
      'dataFim': ?dataFim,
      'page': page,
      'pageSize': pageSize,
    });
    final body = resp.data as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => MidiaGlobal.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      total: (body['total'] as num).toInt(),
      hasMore: body['hasNextPage'] as bool,
    );
  }

  Future<Uint8List> baixarZip(List<int> ids) async {
    final resp = await _dio.post<List<int>>(
      '/midias/zip',
      data: {'ids': ids},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data!);
  }

  Future<void> bulkDelete(List<int> ids) async {
    await _dio.delete('/midias/bulk', data: {'ids': ids});
  }
}

final midiasRemoteDataSourceProvider = Provider(
    (ref) => MidiasRemoteDataSource(ref.read(dioClientProvider)));
