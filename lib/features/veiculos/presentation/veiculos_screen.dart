import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/veiculo.dart';
import 'veiculos_notifier.dart';
import 'widgets/veiculo_card.dart';
import 'widgets/veiculo_form_dialog.dart';

class VeiculosScreen extends ConsumerStatefulWidget {
  const VeiculosScreen({super.key});

  @override
  ConsumerState<VeiculosScreen> createState() => _VeiculosScreenState();
}

class _VeiculosScreenState extends ConsumerState<VeiculosScreen>
    with TopBarSlotMixin<VeiculosScreen> {
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTopBarSlot(TopBarSlot(
      searchController: _searchController,
      searchHint: 'Buscar por placa, modelo, marca…',
      onSearchChanged: (v) => ref.read(veiculosNotifierProvider.notifier).buscar(v),
      action: FilledButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.directions_car_outlined, size: 17),
        label: const Text('Novo veículo'),
      ),
      mobileAction: IconButton(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.directions_car_outlined),
        color: AppColors.accent,
        tooltip: 'Novo veículo',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchController.dispose());
  }

  Future<void> _openForm({Veiculo? veiculo}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(veiculo: veiculo),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        veiculo == null ? 'Veículo cadastrado com sucesso!' : 'Veículo atualizado!',
      );
    }
  }

  Future<void> _excluir(Veiculo v) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir veículo',
      message: 'Deseja excluir o veículo ${v.placa ?? v.modeloNome}? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (confirmar && mounted) {
      try {
        await ref.read(veiculosNotifierProvider.notifier).excluir(v.id);
        if (mounted) GamaSnackBar.success(context, 'Veículo removido.');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir veículo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculosAsync = ref.watch(veiculosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: veiculosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar veículos',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(veiculosNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (veiculos) {
          if (veiculos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  const Text('Nenhum veículo encontrado',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Toque no + para cadastrar o primeiro veículo',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(veiculosNotifierProvider.notifier).buscar(
              _searchController.text.isEmpty ? null : _searchController.text,
            ),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 260,
              ),
              itemCount: veiculos.length,
              itemBuilder: (_, i) {
                final v = veiculos[i];
                return VeiculoCard(
                  placa: v.placa ?? '—',
                  nome: '${v.marcaNome} ${v.modeloNome}',
                  ano: v.ano?.toString() ?? '—',
                  cor: v.cor ?? '—',
                  corHex: corParaColor(v.cor),
                  km: _formatKm(v.quilometragem),
                  visitas: 0,
                  proprietario: v.clienteNome,
                  onTap: () => _openForm(veiculo: v),
                  onLongPress: () => _excluir(v),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatKm(int? km) {
    if (km == null) return '—';
    return km.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
