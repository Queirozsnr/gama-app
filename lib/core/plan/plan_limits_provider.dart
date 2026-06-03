import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import 'plan_limits_model.dart';
import 'plano_remote_data_source.dart';

/// Limites do plano do grupo logado.
/// Rebusca automaticamente quando o usuário faz login/logout ou troca de grupo.
/// Use [ref.watch(planLimitsProvider)] na UI para reagir a mudanças.
final planLimitsProvider = FutureProvider<PlanLimits>((ref) async {
  final auth = ref.watch(authNotifierProvider);

  final isAuthenticated = auth.valueOrNull?.isAuthenticated ?? false;
  if (!isAuthenticated) throw StateError('Não autenticado');

  return ref.read(planoRemoteDataSourceProvider).obterLimites();
});
