import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/suporte_modal.dart';
import '../../auth/presentation/auth_notifier.dart';

/// Página pública (/excluir-conta), sem login: o "link fora do app" que a
/// Play Store exige para pedir a exclusão da conta.
class ExcluirContaInfoScreen extends ConsumerWidget {
  const ExcluirContaInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logado = ref.watch(authNotifierProvider).valueOrNull?.isAuthenticated ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Excluir sua conta do GAMA',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 16),
                  const _Passo(1, 'Entre no GAMA (pelo app ou pelo navegador).'),
                  const _Passo(2, 'Abra Configurações e, na seção Conta, toque em "Excluir minha conta".'),
                  const _Passo(3, 'Confirme com a sua senha.'),
                  const SizedBox(height: 12),
                  const Text(
                    'Seu nome, e-mail e senha são apagados na hora. Se você for o único gestor da oficina, '
                    'ela é desativada e todos os dados dela (clientes, veículos, ordens de serviço, fotos, '
                    'estoque e funcionários) são apagados em 30 dias. As faturas da assinatura são '
                    'guardadas sem dados pessoais, por obrigação fiscal.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não consegue entrar? Peça a exclusão pelo e-mail $kEmailSuporte, '
                    'a partir do e-mail cadastrado na conta.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 24),
                  GamaButton(
                    label: logado ? 'Ir para Configurações' : 'Entrar no GAMA',
                    onPressed: () => context.go(logado ? AppRoutes.configuracoesOficina : AppRoutes.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo(this.numero, this.texto);
  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
            child: Text('$numero',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentDark)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14, color: AppColors.ink))),
        ],
      ),
    );
  }
}
