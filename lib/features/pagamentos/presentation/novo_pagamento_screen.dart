import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../data/pagamentos_remote_data_source.dart';
import '../../funcionarios/domain/remuneracao.dart';
import '../domain/pagamento.dart';
import 'pagamento_detalhe_screen.dart';
import 'pagamentos_notifier.dart';

String _fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

class NovoPagamentoScreen extends ConsumerStatefulWidget {
  const NovoPagamentoScreen({super.key, required this.funcionario});
  final FuncionarioAcumulado funcionario;

  @override
  ConsumerState<NovoPagamentoScreen> createState() =>
      _NovoPagamentoScreenState();
}

class _NovoPagamentoScreenState extends ConsumerState<NovoPagamentoScreen> {
  final Set<int> _selecionadas = {};
  bool _gerando = false;

  FuncionarioAcumulado get f => widget.funcionario;
  bool get _ehFixo => f.tipoRemuneracao == 'Fixo';

  double _calcularTotal(List<OsAberta> os) {
    if (_ehFixo) return f.valorAcumulado;
    return os
        .where((o) => _selecionadas.contains(o.ordemServicoId))
        .fold(0.0, (sum, o) => sum + o.valorContribuicao);
  }

  Future<void> _gerar(List<OsAberta> osAbertas) async {
    if (_selecionadas.isEmpty && !_ehFixo) {
      GamaSnackBar.error(context, 'Selecione ao menos uma OS.');
      return;
    }
    setState(() => _gerando = true);
    try {
      final ids = _ehFixo
          ? osAbertas.map((o) => o.ordemServicoId).toList()
          : _selecionadas.toList();

      final id = await ref
          .read(pagamentosRemoteDataSourceProvider)
          .criar(f.funcionarioId, ids);

      ref.invalidate(pagamentosNotifierProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PagamentoDetalheScreen(pagamentoId: id)),
      );
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao gerar pagamento.');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(osAbertasProvider(f.funcionarioId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(f.nome),
        backgroundColor: AppColors.sidebarBg,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: osAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro ao carregar OS: $e',
              style: const TextStyle(color: AppColors.ink2)),
        ),
        data: (osAbertas) {
          if (osAbertas.isEmpty && !_ehFixo) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.ok),
                  SizedBox(height: 16),
                  Text('Nenhuma OS em aberto',
                      style: TextStyle(fontSize: 16, color: AppColors.ink2)),
                ],
              ),
            );
          }

          if (_selecionadas.isEmpty && osAbertas.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selecionadas
                  .addAll(osAbertas.map((o) => o.ordemServicoId)));
            });
          }

          final total = _calcularTotal(osAbertas);

          return Column(
            children: [
              _InfoStrip(funcionario: f),
              Expanded(
                child: _ehFixo
                    ? _ListaOsFixo(osAbertas: osAbertas)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: osAbertas.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 66, endIndent: 16),
                        itemBuilder: (_, i) {
                          final os = osAbertas[i];
                          final sel = _selecionadas.contains(os.ordemServicoId);
                          return _OsCheckTile(
                            os: os,
                            selecionada: sel,
                            onToggle: (v) => setState(() {
                              if (v) {
                                _selecionadas.add(os.ordemServicoId);
                              } else {
                                _selecionadas.remove(os.ordemServicoId);
                              }
                            }),
                          );
                        },
                      ),
              ),
              _Rodape(
                total: total,
                selecionadasCount:
                    _ehFixo ? osAbertas.length : _selecionadas.length,
                loading: _gerando,
                onGerar: () => _gerar(osAbertas),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── info strip ────────────────────────────────────────────────────────────────

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.funcionario});
  final FuncionarioAcumulado funcionario;

  @override
  Widget build(BuildContext context) {
    final desc = tipoRemuneracaoPagamentoDesc(
      funcionario.tipoRemuneracao,
      porcentagem: funcionario.porcentagem?.toInt(),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.accentDark),
          const SizedBox(width: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.accentDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── OS list (salário fixo) ────────────────────────────────────────────────────

class _ListaOsFixo extends StatelessWidget {
  const _ListaOsFixo({required this.osAbertas});
  final List<OsAberta> osAbertas;

  @override
  Widget build(BuildContext context) {
    if (osAbertas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nenhuma OS no período.',
            style: TextStyle(color: AppColors.ink2)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: osAbertas.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, i) => _OsInfoTile(os: osAbertas[i]),
    );
  }
}

// ── OS check tile (comissão) ──────────────────────────────────────────────────

class _OsCheckTile extends StatelessWidget {
  const _OsCheckTile({
    required this.os,
    required this.selecionada,
    required this.onToggle,
  });

  final OsAberta os;
  final bool selecionada;
  final ValueChanged<bool> onToggle;

  String get _data {
    final d = os.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!selecionada),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selecionada ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selecionada ? AppColors.accent : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: selecionada
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '#${os.ordemServicoId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink3,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    os.clienteNome,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${os.veiculoInfo} · $_data',
                    style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${_fmt(os.valorContribuicao)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selecionada ? AppColors.ok : AppColors.ink3,
                  ),
                ),
                Text(
                  'de ${_fmt(os.totalOS)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── OS info tile (salário fixo) ───────────────────────────────────────────────

class _OsInfoTile extends StatelessWidget {
  const _OsInfoTile({required this.os});
  final OsAberta os;

  String get _data {
    final d = os.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '#${os.ordemServicoId}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  os.clienteNome,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${os.veiculoInfo} · $_data',
                  style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _fmt(os.totalOS),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

// ── footer ────────────────────────────────────────────────────────────────────

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.total,
    required this.selecionadasCount,
    required this.loading,
    required this.onGerar,
  });

  final double total;
  final int selecionadasCount;
  final bool loading;
  final VoidCallback onGerar;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selecionadasCount OS selecionada'
                  '${selecionadasCount != 1 ? 's' : ''}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.ink2),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: loading ? null : onGerar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Gerar pagamento',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
