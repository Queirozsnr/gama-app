import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/plan/plan_limit_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/suporte_modal.dart';
import '../../auth/presentation/auth_notifier.dart';

/// Tela cheia (fora do shell) para grupo bloqueado pelo backend: plano expirado
/// para quem não é gestor, ou conta desativada para todos. Também mostra o
/// "acesso liberado" quando o bloqueio cai, antes de voltar ao app.
class PlanoExpiradoScreen extends ConsumerStatefulWidget {
  const PlanoExpiradoScreen({super.key});

  @override
  ConsumerState<PlanoExpiradoScreen> createState() => _PlanoExpiradoScreenState();
}

class _PlanoExpiradoScreenState extends ConsumerState<PlanoExpiradoScreen> {
  bool _verificando = false;

  Future<void> _verificar() async {
    setState(() => _verificando = true);
    final liberado = await ref.read(bloqueioAssinaturaProvider.notifier).verificar();
    if (!mounted) return;
    setState(() => _verificando = false);
    if (!liberado) GamaSnackBar.error(context, 'O acesso ainda não foi liberado.');
  }

  @override
  Widget build(BuildContext context) {
    final motivo = ref.watch(bloqueioAssinaturaProvider)?.motivo ?? MotivoBloqueio.liberado;

    final (icone, cor, corFundo, titulo, texto) = switch (motivo) {
      MotivoBloqueio.planoExpirado => (
          Icons.lock_clock_outlined,
          AppColors.danger,
          AppColors.dangerSoft,
          'Plano da oficina expirado',
          'A assinatura do GAMA desta oficina venceu. Peça ao responsável para renovar — '
              'o acesso volta sozinho assim que a renovação for confirmada.',
        ),
      MotivoBloqueio.contaDesativada => (
          Icons.block,
          AppColors.danger,
          AppColors.dangerSoft,
          'Conta desativada',
          'O acesso desta oficina ao GAMA foi suspenso. Fale com o suporte para entender '
              'o motivo e reativar a conta.',
        ),
      MotivoBloqueio.liberado => (
          Icons.check_circle_outline,
          AppColors.ok,
          AppColors.okSoft,
          'Acesso liberado',
          'A assinatura foi regularizada. Pode continuar usando o GAMA normalmente.',
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: corFundo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icone, color: cor, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 28),
                  ..._acoes(motivo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _acoes(MotivoBloqueio motivo) {
    if (motivo == MotivoBloqueio.liberado) {
      return [
        GamaButton(
          label: 'Continuar',
          onPressed: () => ref.read(bloqueioAssinaturaProvider.notifier).concluirLiberacao(),
        ),
      ];
    }

    final verificar = GamaButton(
      label: 'Verificar novamente',
      icon: Icons.refresh,
      isLoading: _verificando,
      onPressed: _verificando ? null : _verificar,
      variant: motivo == MotivoBloqueio.contaDesativada
          ? GamaButtonVariant.secondary
          : GamaButtonVariant.primary,
    );

    return [
      if (motivo == MotivoBloqueio.contaDesativada) ...[
        GamaButton(
          label: 'Falar com o suporte',
          icon: Icons.support_agent,
          onPressed: () => showSuporteModal(context),
        ),
        const SizedBox(height: 10),
      ],
      verificar,
      const SizedBox(height: 6),
      TextButton(
        onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
        style: TextButton.styleFrom(foregroundColor: AppColors.ink2),
        child: const Text('Sair'),
      ),
    ];
  }
}
