import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_fab.dart';
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
  bool _searchOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final nome = oficinas.cast<OficinaItem?>().firstWhere(
      (o) => o!.id == auth?.oficinaId,
      orElse: () => null,
    )?.nome;
    setTopBarSlot(TopBarSlot(
      pageTitle: 'Veículos',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      searchController: isDesktop ? _searchController : null,
      searchHint: isDesktop ? 'Buscar por placa, modelo, marca…' : null,
      onSearchChanged: isDesktop
          ? (v) => ref.read(veiculosNotifierProvider.notifier).buscar(v)
          : null,
      action: FilledButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.directions_car_outlined, size: 17),
        label: const Text('Novo veículo'),
      ),
      mobileAction: IconButton(
        onPressed: _toggleSearch,
        icon: Icon(
          _searchOpen ? Icons.close : Icons.search,
          color: _searchOpen ? AppColors.accent : Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ));
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchController.clear();
      ref.read(veiculosNotifierProvider.notifier).buscar(null);
    }
    _syncSlot();
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    final content = veiculosAsync.when(
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, isMobile ? 88 : 24),
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
                onTap: () => context.go('/veiculos/${v.id}'),
                onLongPress: () => _excluir(v),
              );
            },
          ),
        );
      },
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (_searchOpen)
                    _MobileSearchRow(
                      controller: _searchController,
                      hint: 'Buscar por placa, modelo, marca…',
                      onChanged: (v) =>
                          ref.read(veiculosNotifierProvider.notifier).buscar(v),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: GamaFab(
                label: 'Novo veículo',
                icon: Icons.directions_car_outlined,
                onTap: () => _openForm(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: content,
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

class _MobileSearchRow extends StatelessWidget {
  const _MobileSearchRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.sidebarLine,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.sidebarText),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sidebarText),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
