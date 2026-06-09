import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/assinatura_remote_data_source.dart';
import '../domain/assinatura_models.dart';

final assinaturaProvider = FutureProvider.autoDispose<AssinaturaDetalhes>((ref) async {
  return ref.read(assinaturaRemoteDataSourceProvider).obterDetalhes();
});
