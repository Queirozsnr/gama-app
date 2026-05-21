import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gerencial_remote_data_source.dart';
import '../domain/gerencial_dashboard.dart';

final gerencialDashboardProvider = FutureProvider.autoDispose
    .family<GerencialDashboard, (DateTime, DateTime)>((ref, params) async {
  final (dataInicio, dataFim) = params;
  return ref
      .read(gerencialRemoteDataSourceProvider)
      .obterDashboard(dataInicio, dataFim);
});
