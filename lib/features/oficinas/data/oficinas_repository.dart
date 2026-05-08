import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/oficina_model.dart';
import 'oficinas_remote_data_source.dart';

class OficinasRepository {
  OficinasRepository(this._dataSource);
  final OficinasRemoteDataSource _dataSource;

  Future<List<OficinaModel>> listar() => _dataSource.listar();

  Future<int> criar({required String nome, required String endereco, required String telefone}) =>
      _dataSource.criar(nome: nome, endereco: endereco, telefone: telefone);

  Future<void> atualizar(int id, {required String nome, required String endereco, required String telefone, required bool ativo}) =>
      _dataSource.atualizar(id, nome: nome, endereco: endereco, telefone: telefone, ativo: ativo);

  Future<void> excluir(int id) => _dataSource.excluir(id);
}

final oficinasRepositoryProvider = Provider<OficinasRepository>(
  (ref) => OficinasRepository(ref.watch(oficinasRemoteDataSourceProvider)),
);
