import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/clientes_remote_data_source.dart';
import '../domain/cliente_detalhe.dart';

final clienteDetalheProvider =
    FutureProvider.family<ClienteDetalhe, int>((ref, id) async {
  return ref.read(clientesRemoteDataSourceProvider).obterDetalhe(id);
});
