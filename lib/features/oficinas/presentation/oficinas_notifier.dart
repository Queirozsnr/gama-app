import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/oficinas_repository.dart';
import '../domain/oficina_model.dart';

class OficinasNotifier extends AutoDisposeAsyncNotifier<List<OficinaModel>> {
  @override
  Future<List<OficinaModel>> build() => ref.read(oficinasRepositoryProvider).listar();

  Future<void> criar({required String nome, required String endereco, required String telefone}) =>
      _run(() => ref.read(oficinasRepositoryProvider).criar(nome: nome, endereco: endereco, telefone: telefone));

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
  }) =>
      _run(() => ref.read(oficinasRepositoryProvider).atualizar(
            id,
            nome: nome,
            endereco: endereco,
            telefone: telefone,
            ativo: ativo,
            telefone2: telefone2,
            email: email,
            whatsapp: whatsapp,
            instagram: instagram,
            cnpj: cnpj,
            corPadrao: corPadrao,
          ));

  Future<String> uploadLogo(int id, Uint8List bytes, String fileName) async {
    try {
      final url = await ref.read(oficinasRepositoryProvider).uploadLogo(id, bytes, fileName);
      ref.invalidateSelf();
      await future;
      return url;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw (data is Map && data['error'] != null) ? data['error'] as String : 'Erro ao enviar imagem.';
    } catch (_) {
      throw 'Erro inesperado ao enviar imagem.';
    }
  }

  Future<void> excluir(int id) =>
      _run(() => ref.read(oficinasRepositoryProvider).excluir(id));

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      ref.invalidateSelf();
      await future;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw (data is Map && data['error'] != null) ? data['error'] as String : 'Erro na operação.';
    } catch (_) {
      throw 'Erro inesperado.';
    }
  }
}

final oficinasNotifierProvider =
    AsyncNotifierProvider.autoDispose<OficinasNotifier, List<OficinaModel>>(OficinasNotifier.new);
