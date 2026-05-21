import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/receitas_remote_data_source.dart';
import '../domain/receitas_dashboard.dart';

final receitasDashboardProvider = FutureProvider.autoDispose
    .family<ReceitasDashboard, (DateTime, DateTime)>((ref, params) async {
  final (dataInicio, dataFim) = params;
  return ref
      .read(receitasRemoteDataSourceProvider)
      .obterDashboard(dataInicio, dataFim);
});
