import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/oficina_model.dart';
import 'oficinas_remote_data_source.dart';

class OficinasRepository {
  OficinasRepository(this._dataSource);
  final OficinasRemoteDataSource _dataSource;

  Future<List<OficinaModel>> listar() => _dataSource.listar();

  Future<int> criar({required String nome, required String endereco, required String telefone}) =>
      _dataSource.criar(nome: nome, endereco: endereco, telefone: telefone);

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
      _dataSource.atualizar(
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
      );

  Future<String> uploadLogo(int id, Uint8List bytes, String fileName) =>
      _dataSource.uploadLogo(id, bytes, fileName);

  Future<void> excluir(int id) => _dataSource.excluir(id);
}

final oficinasRepositoryProvider = Provider<OficinasRepository>(
  (ref) => OficinasRepository(ref.watch(oficinasRemoteDataSourceProvider)),
);
