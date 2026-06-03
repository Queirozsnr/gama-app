import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Última mensagem de erro de limite de plano recebida do backend (HTTP 402).
/// A UI observa esse provider para exibir o banner/dialog de upgrade.
/// Limpe com [ref.read(planLimitNotifierProvider.notifier).clear()] após mostrar.
class PlanLimitNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String mensagem) => state = mensagem;
  void clear() => state = null;
}

final planLimitNotifierProvider =
    NotifierProvider<PlanLimitNotifier, String?>(PlanLimitNotifier.new);
