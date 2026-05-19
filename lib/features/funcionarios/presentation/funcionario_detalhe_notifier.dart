import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/funcionarios_remote_data_source.dart';
import '../domain/funcionario.dart';

final funcionarioDetalheProvider = FutureProvider.autoDispose.family<Funcionario, int>(
  (ref, id) => ref.read(funcionariosRemoteDataSourceProvider).obter(id),
);
