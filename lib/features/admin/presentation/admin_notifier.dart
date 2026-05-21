import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_remote_data_source.dart';
import '../domain/admin_models.dart';

final gruposAdminProvider = FutureProvider.autoDispose<List<GrupoAdminItem>>((ref) async {
  return ref.watch(adminRemoteDataSourceProvider).listarGrupos();
});
