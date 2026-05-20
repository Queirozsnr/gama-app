import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'acompanhamento_socio_screen.dart';
import 'pagamentos_notifier.dart';

class ReceitasSocioPage extends ConsumerWidget {
  const ReceitasSocioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFuncionarios = ref.watch(pagamentosNotifierProvider);

    return asyncFuncionarios.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar dados',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(pagamentosNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (funcionarios) {
        final socio = funcionarios
            .where((f) => f.tipoRemuneracao == 'Socio')
            .firstOrNull;

        if (socio == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum sócio cadastrado',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Cadastre um funcionário com perfil Gerente\npara visualizar as receitas.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return AcompanhamentoSocioScreen(
          funcionarioId: socio.funcionarioId,
          funcionarioNome: socio.nome,
        );
      },
    );
  }
}
