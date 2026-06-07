import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Limite de feature atingido (HTTP 402 com type "plan_limit").
/// A UI exibe um SnackBar e limpa imediatamente.
class PlanLimitNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String mensagem) => state = mensagem;
  void clear() => state = null;
}

final planLimitNotifierProvider =
    NotifierProvider<PlanLimitNotifier, String?>(PlanLimitNotifier.new);

/// Assinatura expirada (HTTP 402 com type "plan_expired").
/// A UI exibe um dialog bloqueante até o usuário renovar.
class PlanoExpiradoNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String mensagem) => state = mensagem;
  void clear() => state = null;
}

final planoExpiradoNotifierProvider =
    NotifierProvider<PlanoExpiradoNotifier, String?>(PlanoExpiradoNotifier.new);
