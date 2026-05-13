import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_search_bar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../veiculos/data/veiculos_remote_data_source.dart';
import '../../veiculos/domain/veiculo.dart';
import '../../veiculos/presentation/widgets/veiculo_form_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/cliente.dart';
import '../domain/veiculo_resumo.dart';
import 'clientes_notifier.dart';
import 'widgets/cliente_card.dart';
import 'widgets/cliente_form_dialog.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(clientesNotifierProvider.notifier).buscar(value);
  }

  Future<void> _openVeiculoForm(int clienteId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(clienteIdFixo: clienteId),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(context, 'Veículo cadastrado!');
    }
  }

  Future<void> _openEditVeiculo(VeiculoResumo resumo) async {
    Veiculo veiculo;
    try {
      veiculo = await ref.read(veiculosRemoteDataSourceProvider).obter(resumo.id);
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao carregar veículo.');
      return;
    }
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(veiculo: veiculo),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(context, 'Veículo atualizado!');
      ref.invalidate(clientesNotifierProvider);
    }
  }

  Future<void> _openForm({Cliente? cliente}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ClienteFormDialog(cliente: cliente),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        cliente == null ? 'Cliente criado com sucesso!' : 'Cliente atualizado!',
      );
    }
  }

  Future<void> _excluir(Cliente cliente) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir cliente',
      message: 'Deseja excluir "${cliente.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );

    if (confirmar && mounted) {
      try {
        await ref.read(clientesNotifierProvider.notifier).excluir(cliente.id);
        if (mounted) GamaSnackBar.success(context, 'Cliente removido.');
      } catch (e) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir cliente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesNotifierProvider);
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
                          hint: 'Buscar por nome, e-mail, telefone...',
                          controller: _searchController,
                          onChanged: _onSearch,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Novo cliente'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  )
                : GamaSearchBar(
                    hint: 'Buscar por nome, e-mail, telefone...',
                    controller: _searchController,
                    onChanged: _onSearch,
                  ),
          ),
          Expanded(
            child: clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar clientes', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(clientesNotifierProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (clientes) {
                if (clientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum cliente encontrado',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toque no + para adicionar o primeiro cliente',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(clientesNotifierProvider.notifier).buscar(
                    _searchController.text.isEmpty ? null : _searchController.text,
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 240,
                    ),
                    itemCount: clientes.length,
                    itemBuilder: (_, i) {
                      final c = clientes[i];
                      return ClienteCard(
                        nome: c.nome,
                        email: c.email ?? '',
                        telefone: c.telefone ?? '',
                        cidade: c.cidade ?? '',
                        veiculos: c.veiculos,
                        desde: _formatarData(c.criadoEm),
                        onTap: () => _openForm(cliente: c),
                        onLongPress: () => _excluir(c),
                        onAddVeiculo: () => _openVeiculoForm(c.id),
                        onEditVeiculo: _openEditVeiculo,
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
              label: const Text('Novo cliente'),
            ),
    );
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
