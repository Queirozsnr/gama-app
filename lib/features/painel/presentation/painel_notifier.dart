import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/painel_remote_data_source.dart';
import '../domain/painel_operacional.dart';

final painelOperacionalProvider = FutureProvider.autoDispose
    .family<PainelOperacional, (DateTime, DateTime)>((ref, params) async {
  final (dataInicio, dataFim) = params;
  return ref
      .read(painelRemoteDataSourceProvider)
      .obterOperacional(dataInicio, dataFim);
});
