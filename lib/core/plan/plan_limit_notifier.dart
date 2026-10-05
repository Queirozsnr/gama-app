import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../network/dio_client.dart';

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

/// Por que o backend está recusando as requests do grupo.
enum MotivoBloqueio {
  /// HTTP 402 "plan_expired".
  planoExpirado,

  /// HTTP 402 "account_disabled".
  contaDesativada,

  /// O bloqueio caiu; o usuário passa pela tela de bloqueio para o shell
  /// ser recriado e as telas recarregarem sem os erros de antes.
  liberado,
}

class BloqueioAssinatura {
  const BloqueioAssinatura(this.motivo, [this.mensagem = '']);

  final MotivoBloqueio motivo;
  final String mensagem;
}

/// Grupo bloqueado pelo backend. Diferente do [PlanLimitNotifier], o estado
/// persiste: o router mantém o usuário em /assinatura (gestor com plano
/// expirado) ou em /plano-expirado até o backend voltar a aceitar requests.
/// Zera ao trocar de usuário ou de grupo.
class BloqueioAssinaturaNotifier extends Notifier<BloqueioAssinatura?> {
  static const _intervaloVerificacao = Duration(seconds: 60);

  Timer? _timer;
  bool _verificando = false;

  @override
  BloqueioAssinatura? build() {
    ref.watch(authNotifierProvider.select(
      (a) => (a.valueOrNull?.isAuthenticated, a.valueOrNull?.grupoOficinaId),
    ));
    ref.onDispose(_pararVerificacao);
    return null;
  }

  void bloquear(MotivoBloqueio motivo, String mensagem) {
    if (state?.motivo == motivo) return;
    state = BloqueioAssinatura(motivo, mensagem);
    _timer ??= Timer.periodic(_intervaloVerificacao, (_) => verificar());
  }

  /// Faz uma request comum para ver se o backend já liberou o grupo
  /// (o middleware guarda o status do plano em cache por até 2 min).
  /// Um novo 402 mantém o bloqueio pelo próprio interceptor.
  Future<bool> verificar() async {
    if (state == null || state!.motivo == MotivoBloqueio.liberado) return true;
    if (_verificando) return false;
    _verificando = true;
    try {
      await ref.read(dioClientProvider).get<dynamic>('/notificacoes');
      _pararVerificacao();
      state = const BloqueioAssinatura(MotivoBloqueio.liberado);
      return true;
    } catch (_) {
      return false;
    } finally {
      _verificando = false;
    }
  }

  /// Chamado pela tela de bloqueio depois de mostrar o "acesso liberado".
  void concluirLiberacao() {
    _pararVerificacao();
    state = null;
  }

  void _pararVerificacao() {
    _timer?.cancel();
    _timer = null;
  }
}

final bloqueioAssinaturaProvider =
    NotifierProvider<BloqueioAssinaturaNotifier, BloqueioAssinatura?>(
        BloqueioAssinaturaNotifier.new);
