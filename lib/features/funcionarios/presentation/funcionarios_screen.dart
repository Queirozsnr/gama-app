import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_search_bar.dart';
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir funcionário'),
        content: Text('Deseja excluir "${f.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
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
      builder: (ctx) => AlertDialog(
        title: const Text('Resetar senha'),
        content: Text('Resetar a senha de "${f.nome}" para "gama123"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resetar')),
        ],
      ),
    );
    if (confirmar == true && mounted) {
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GamaSearchBar(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Novo funcionário'),
      ),
    );
  }
}
