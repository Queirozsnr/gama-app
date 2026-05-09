import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_search_bar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/funcionario.dart';
import 'funcionarios_notifier.dart';
import 'widgets/funcionario_card.dart';
import 'widgets/funcionario_form_dialog.dart';

class FuncionariosScreen extends ConsumerStatefulWidget {
  const FuncionariosScreen({super.key});

  @override
  ConsumerState<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends ConsumerState<FuncionariosScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Funcionario? funcionario}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => FuncionarioFormDialog(funcionario: funcionario),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        funcionario == null ? 'Funcionário criado com sucesso!' : 'Funcionário atualizado!',
      );
    }
  }

  Future<void> _excluir(Funcionario f) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir funcionário',
      message: 'Deseja excluir "${f.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (confirmar && mounted) {
      try {
        await ref.read(funcionariosNotifierProvider.notifier).excluir(f.id);
        if (mounted) GamaSnackBar.success(context, 'Funcionário removido.');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir funcionário.');
      }
    }
  }

  Future<void> _resetarSenha(Funcionario f) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => GamaConfirmDialog(
        title: 'Resetar senha',
        message: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Resetar a senha de '),
              TextSpan(text: f.nome, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const TextSpan(text: ' para '),
              const TextSpan(text: 'gama123', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        confirmLabel: 'Resetar',
      ),
    ) == true;
    if (confirmar && mounted) {
      try {
        await ref.read(funcionariosNotifierProvider.notifier).resetarSenha(f.id);
        if (mounted) GamaSnackBar.success(context, 'Senha resetada para "gama123".');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao resetar senha.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final funcionariosAsync = ref.watch(funcionariosNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: GamaSearchBar(
                          hint: 'Buscar por nome ou e-mail...',
                          controller: _searchController,
                          onChanged: (v) => ref.read(funcionariosNotifierProvider.notifier).buscar(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Novo funcionário'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  )
                : GamaSearchBar(
                    hint: 'Buscar por nome ou e-mail...',
                    controller: _searchController,
                    onChanged: (v) => ref.read(funcionariosNotifierProvider.notifier).buscar(v),
                  ),
          ),
          Expanded(
            child: funcionariosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Erro ao carregar funcionários', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(funcionariosNotifierProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (funcionarios) {
                if (funcionarios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text('Nenhum funcionário encontrado', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Text('Toque no + para adicionar o primeiro', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(funcionariosNotifierProvider.notifier).buscar(
                    _searchController.text.isEmpty ? null : _searchController.text,
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 180,
                    ),
                    itemCount: funcionarios.length,
                    itemBuilder: (_, i) {
                      final f = funcionarios[i];
                      return FuncionarioCard(
                        funcionario: f,
                        onTap: () => _openForm(funcionario: f),
                        onLongPress: () => _excluir(f),
                        onResetarSenha: () => _resetarSenha(f),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Novo funcionário'),
            ),
    );
  }
}
