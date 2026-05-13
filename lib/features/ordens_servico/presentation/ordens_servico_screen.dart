import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../domain/ordem_servico.dart';
import 'ordens_servico_notifier.dart';
import 'widgets/os_card.dart';

const _filtros = [
  ('Todas',             null),
  ('Aberta',            'Aberta'),
  ('Em andamento',      'EmAndamento'),
  ('Aguardando peças',  'AguardandoPecas'),
  ('Concluída',         'Concluida'),
  ('Histórico',         'Entregue'),
];

class OrdensServicoScreen extends ConsumerStatefulWidget {
  const OrdensServicoScreen({super.key});

  @override
  ConsumerState<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends ConsumerState<OrdensServicoScreen> {
  String? _filtroStatus; // null = Todas (exceto Entregue)
  bool _historico = false;

  void _setFiltro(String? status, bool historico) {
    setState(() {
      _filtroStatus = status;
      _historico = historico;
    });
    ref.read(ordensServicoNotifierProvider.notifier).filtrar(status);
  }

  void _abrirNova() => context.push('/ordens-servico/nova');

  Future<void> _excluir(OrdemServico os) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir OS #${os.id}',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(ordensServicoNotifierProvider.notifier).excluir(os.id);
      if (mounted) GamaSnackBar.success(context, 'OS removida.');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao excluir OS.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(ordensServicoNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Spacer(),
                if (isDesktop)
                  FilledButton.icon(
                    onPressed: _abrirNova,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova OS'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
              ],
            ),
          ),
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filtros.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, value) = _filtros[i];
                final isSelected = (value == null && !_historico) ||
                    (value == 'Entregue' && _historico) ||
                    (value != null && value != 'Entregue' && value == _filtroStatus);
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => _setFiltro(
                    value == 'Entregue' ? 'Entregue' : value,
                    value == 'Entregue',
                  ),
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
          // List
          Expanded(
            child: osAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('Erro ao carregar ordens de serviço',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => ref.read(ordensServicoNotifierProvider.notifier).recarregar(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (lista) {
                // Client-side: quando "Todas", ocultar Entregue
                final exibir = _historico
                    ? lista
                    : (_filtroStatus == null
                        ? lista.where((os) => os.status != 'Entregue').toList()
                        : lista);

                if (exibir.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text('Nenhuma OS encontrada',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          _historico
                              ? 'Nenhuma OS entregue ainda'
                              : 'Toque em + para criar a primeira OS',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(ordensServicoNotifierProvider.notifier).recarregar(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 440,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 178,
                    ),
                    itemCount: exibir.length,
                    itemBuilder: (_, i) {
                      final os = exibir[i];
                      return OsCard(
                        os: os,
                        onTap: () => context.push('/ordens-servico/${os.id}'),
                        onLongPress: os.status == 'Aberta' ? () => _excluir(os) : null,
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
              onPressed: _abrirNova,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova OS'),
            ),
    );
  }
}
