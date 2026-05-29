import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/clientes_remote_data_source.dart';
import '../domain/cliente.dart';

class ClientesNotifier extends AutoDisposeAsyncNotifier<List<Cliente>> {
  @override
  Future<List<Cliente>> build() => _fetch();

  Future<List<Cliente>> _fetch({String? busca}) {
    return ref.read(clientesRemoteDataSourceProvider).listar(busca: busca);
  }

  Future<void> buscar(String? termo) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(busca: termo?.isEmpty == true ? null : termo));
  }

  Future<int> criar({
    required String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cidade,
  }) async {
    final id = await ref.read(clientesRemoteDataSourceProvider).criar({
      'nome': nome,
      if (email != null && email.isNotEmpty) 'email': email,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
      if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
    });
    ref.invalidateSelf();
    return id;
  }

  Future<void> atualizar({
    required int id,
    required String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cidade,
  }) async {
    await ref.read(clientesRemoteDataSourceProvider).atualizar(id, {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'cidade': cidade,
    });
    ref.invalidateSelf();
  }

  Future<void> excluir(int id) async {
    await ref.read(clientesRemoteDataSourceProvider).excluir(id);
    ref.invalidateSelf();
  }
}

final clientesNotifierProvider =
    AsyncNotifierProvider.autoDispose<ClientesNotifier, List<Cliente>>(ClientesNotifier.new);
