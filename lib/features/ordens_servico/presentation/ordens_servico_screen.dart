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
  ('Todas',            null),
  ('Aberta',           'Aberta'),
  ('Em andamento',     'EmAndamento'),
  ('Aguardando peças', 'AguardandoPecas'),
  ('Concluída',        'Concluida'),
];

class OrdensServicoScreen extends ConsumerStatefulWidget {
  const OrdensServicoScreen({super.key});

  @override
  ConsumerState<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends ConsumerState<OrdensServicoScreen> {
  String? _filtroStatus;
  final _buscaCtrl = TextEditingController();
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _buscaCtrl.addListener(() => setState(() => _busca = _buscaCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _setFiltro(String? status) {
    setState(() => _filtroStatus = status);
    ref.read(ordensServicoNotifierProvider.notifier).filtrar(status);
  }

  void _abrirNova() => context.push('/ordens-servico/nova');
  void _abrirHistorico() => _setFiltro('Entregue');

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

  List<OrdemServico> _filtrar(List<OrdemServico> lista) {
    if (_busca.isEmpty) return lista;
    return lista.where((os) {
      return os.clienteNome.toLowerCase().contains(_busca) ||
          os.veiculoDescricao.toLowerCase().contains(_busca) ||
          (os.veiculoPlaca?.toLowerCase().contains(_busca) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(ordensServicoNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isHistorico = _filtroStatus == 'Entregue';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: isHistorico ? () => _setFiltro(null) : _abrirHistorico,
                  icon: Icon(isHistorico ? Icons.arrow_back : Icons.history, size: 16),
                  label: Text(isHistorico ? 'Voltar' : 'Histórico'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                if (isDesktop && !isHistorico)
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
          // Filter chips — ocultos no histórico
          if (!isHistorico)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filtros.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, value) = _filtros[i];
                  final isSelected = value == _filtroStatus;
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _setFiltro(value),
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
          // Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _buscaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, veículo ou placa…',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                suffixIcon: _busca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: AppColors.textSecondary,
                        onPressed: () => _buscaCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
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
                final exibir = _filtrar(lista);

                if (exibir.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: AppColors.border),
                        const SizedBox(height: 16),
                        Text(
                          _busca.isNotEmpty ? 'Nenhum resultado para "$_busca"' : 'Nenhuma OS encontrada',
                          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        if (_busca.isEmpty && isHistorico) ...[
                          const SizedBox(height: 8),
                          const Text('Nenhuma OS entregue ainda',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  );
                }

                final minhas = exibir.where((os) => os.euSouMecanico).toList();
                final outras = exibir.where((os) => !os.euSouMecanico).toList();
                final temSeparacao = minhas.isNotEmpty && outras.isNotEmpty;

                VoidCallback? longPress(OrdemServico os) =>
                    os.status == 'Aberta' ? () => _excluir(os) : null;

                return RefreshIndicator(
                  onRefresh: () => ref.read(ordensServicoNotifierProvider.notifier).recarregar(),
                  child: CustomScrollView(
                    slivers: [
                      if (temSeparacao)
                        _SliverSectionHeader(
                          label: 'Minhas OS',
                          color: AppColors.primary,
                          icon: Icons.engineering_outlined,
                        ),
                      _SliverOsGrid(
                        lista: temSeparacao ? minhas : exibir,
                        onTap: (os) => context.push('/ordens-servico/${os.id}'),
                        longPress: longPress,
                      ),
                      if (temSeparacao) ...[
                        _SliverSectionHeader(
                          label: 'Outras OS',
                          color: AppColors.textSecondary,
                          icon: Icons.assignment_outlined,
                        ),
                        _SliverOsGrid(
                          lista: outras,
                          onTap: (os) => context.push('/ordens-servico/${os.id}'),
                          longPress: longPress,
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isDesktop || isHistorico
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

// ── Sliver section header ─────────────────────────────────────────────────────

class _SliverSectionHeader extends StatelessWidget {
  const _SliverSectionHeader({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: color.withValues(alpha: 0.25), height: 1)),
            ],
          ),
        ),
      );
}

// ── Sliver OS grid ────────────────────────────────────────────────────────────

class _SliverOsGrid extends StatelessWidget {
  const _SliverOsGrid({required this.lista, required this.onTap, required this.longPress});
  final List<OrdemServico> lista;
  final void Function(OrdemServico) onTap;
  final VoidCallback? Function(OrdemServico) longPress;

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final os = lista[i];
              return OsCard(
                os: os,
                onTap: () => onTap(os),
                onLongPress: longPress(os),
              );
            },
            childCount: lista.length,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 440,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 178,
          ),
        ),
      );
}
