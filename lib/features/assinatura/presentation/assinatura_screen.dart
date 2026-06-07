import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/assinatura_remote_data_source.dart';
import '../domain/assinatura_models.dart';
import 'assinatura_notifier.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmtBrl(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

String _fmtGb(double v) {
  if (v >= 1) return '${v.toStringAsFixed(1).replaceAll('.', ',')} GB';
  return '${(v * 1024).toStringAsFixed(0)} MB';
}

// ── planos estáticos ──────────────────────────────────────────────────────────

class _PlanoOpcao {
  const _PlanoOpcao({
    required this.plano,
    required this.label,
    required this.descricao,
    required this.precoMensal,
    required this.precoAnual,
  });

  final NomePlano plano;
  final String label;
  final String descricao;
  final double precoMensal;
  final double precoAnual;
}

const _planosDisponiveis = [
  _PlanoOpcao(
    plano: NomePlano.solo,
    label: 'Solo',
    descricao: 'Para uma oficina só',
    precoMensal: 99.0,
    precoAnual: 79.0,
  ),
  _PlanoOpcao(
    plano: NomePlano.oficina,
    label: 'Oficina',
    descricao: 'Operação completa do dia a dia',
    precoMensal: 249.0,
    precoAnual: 199.0,
  ),
  _PlanoOpcao(
    plano: NomePlano.rede,
    label: 'Rede',
    descricao: 'Para rede com mais de uma unidade',
    precoMensal: 399.0,
    precoAnual: 319.0,
  ),
];

// ── screen ────────────────────────────────────────────────────────────────────

class AssinaturaScreen extends ConsumerStatefulWidget {
  const AssinaturaScreen({super.key});

  @override
  ConsumerState<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends ConsumerState<AssinaturaScreen>
    with TopBarSlotMixin<AssinaturaScreen> {
  CicloCobranca _ciclo = CicloCobranca.mensal;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTopBarSlot(const TopBarSlot(pageTitle: 'Assinatura'));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(assinaturaProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.danger)),
        ),
      ),
      data: (detalhes) =>
          isDesktop ? _buildDesktop(detalhes) : _buildMobile(detalhes),
    );
  }

  // ── desktop ──────────────────────────────────────────────────────────────

  Widget _buildDesktop(AssinaturaDetalhes detalhes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanoAtualCard(
            detalhes: detalhes,
            onCancelar: _confirmarCancelamento,
          ),
          const SizedBox(height: 20),
          _UsoPlanoGrid(uso: detalhes.uso),
          const SizedBox(height: 20),
          _MudarDePlanoSection(
            planoAtual: detalhes.plano,
            cancelamentoAgendado: detalhes.status == StatusAssinatura.cancelamentoAgendado,
            ciclo: _ciclo,
            submitting: _submitting,
            onCicloChanged: (v) => setState(() => _ciclo = v),
            onMudar: _confirmarMudancaPlano,
          ),
          const SizedBox(height: 20),
          _HistoricoFaturasSection(faturas: detalhes.faturas),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── mobile ───────────────────────────────────────────────────────────────

  Widget _buildMobile(AssinaturaDetalhes detalhes) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileUsoHeader(
            detalhes: detalhes,
            onCancelar: _confirmarCancelamento,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MudarDePlanoSection(
                  planoAtual: detalhes.plano,
                  cancelamentoAgendado: detalhes.status == StatusAssinatura.cancelamentoAgendado,
                  ciclo: _ciclo,
                  submitting: _submitting,
                  onCicloChanged: (v) => setState(() => _ciclo = v),
                  onMudar: _confirmarMudancaPlano,
                ),
                const SizedBox(height: 16),
                _HistoricoFaturasSection(faturas: detalhes.faturas),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _confirmarCancelamento() async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Cancelar assinatura',
      message:
          'Tem certeza? O acesso será mantido até o fim do período pago e não haverá reembolso proporcional.',
      confirmLabel: 'Cancelar assinatura',
      confirmColor: AppColors.danger,
    );
    if (!ok || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(assinaturaRemoteDataSourceProvider).cancelarPlano();
      if (mounted) {
        ref.invalidate(assinaturaProvider);
        GamaSnackBar.success(context, 'Assinatura cancelada.');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmarMudancaPlano(NomePlano novoPlano) async {
    final opcao =
        _planosDisponiveis.firstWhere((p) => p.plano == novoPlano);
    final preco =
        _ciclo == CicloCobranca.mensal ? opcao.precoMensal : opcao.precoAnual;
    final cicloLabel =
        _ciclo == CicloCobranca.mensal ? 'mensalmente' : 'anualmente';

    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Mudar para ${opcao.label}',
      message:
          'Você será cobrado ${_fmtBrl(preco)}/mês $cicloLabel a partir do próximo ciclo. Deseja confirmar?',
      confirmLabel: 'Confirmar mudança',
    );
    if (!ok || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(assinaturaRemoteDataSourceProvider)
          .mudarPlano(novoPlano, _ciclo);
      if (mounted) {
        ref.invalidate(assinaturaProvider);
        GamaSnackBar.success(context, 'Plano atualizado para ${opcao.label}.');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── _PlanoAtualCard ───────────────────────────────────────────────────────────

class _PlanoAtualCard extends StatelessWidget {
  const _PlanoAtualCard({
    required this.detalhes,
    required this.onCancelar,
  });

  final AssinaturaDetalhes detalhes;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final cancelando = detalhes.status == StatusAssinatura.cancelamentoAgendado;
    final cicloLabel = detalhes.ciclo == CicloCobranca.mensal
        ? 'Cobrança mensal'
        : 'Cobrança anual';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.sidebarLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left — plan info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEU PLANO',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sidebarText.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      detalhes.plano.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(status: detalhes.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.sidebarText),
                    const SizedBox(width: 5),
                    Text(
                      cancelando
                          ? 'Ativo até: ${_fmtDate(detalhes.proximaCobranca)}'
                          : 'Renova em: ${_fmtDate(detalhes.proximaCobranca)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: cancelando ? AppColors.danger : AppColors.sidebarText,
                      ),
                    ),
                    if (!cancelando) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.refresh_outlined,
                          size: 13, color: AppColors.sidebarText),
                      const SizedBox(width: 5),
                      Text(
                        cicloLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.sidebarText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // right — price + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _fmtBrl(detalhes.precoMensal),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: '/mês',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF8C8070),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (detalhes.status == StatusAssinatura.cancelamentoAgendado)
                Text(
                  'Cancela em ${_fmtDate(detalhes.proximaCobranca)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                )
              else
                OutlinedButton(
                  onPressed: onCancelar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar plano',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StatusAssinatura status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      StatusAssinatura.ativa                => (AppColors.ok, AppColors.okSoft),
      StatusAssinatura.trialing             => (AppColors.info, AppColors.infoSoft),
      StatusAssinatura.suspensa             => (AppColors.warn, AppColors.warnSoft),
      StatusAssinatura.cancelada            => (AppColors.danger, AppColors.dangerSoft),
      StatusAssinatura.cancelamentoAgendado => (AppColors.danger, AppColors.dangerSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bg.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: bg,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── _UsoPlanoGrid ─────────────────────────────────────────────────────────────

class _UsoPlanoGrid extends StatelessWidget {
  const _UsoPlanoGrid({required this.uso});

  final UsoPlano uso;

  @override
  Widget build(BuildContext context) {
    final items = [
      _UsoItem(
        label: 'OS / MÊS',
        usado: uso.osMes,
        max: uso.osMesMax,
        display: uso.osMesMax == null
            ? '${uso.osMes} / ilimitado'
            : '${uso.osMes} / ${uso.osMesMax}',
      ),
      _UsoItem(
        label: 'USUÁRIOS',
        usado: uso.usuarios,
        max: uso.usuariosMax,
        display: uso.usuariosMax == null
            ? '${uso.usuarios} / ilimitado'
            : '${uso.usuarios} / ${uso.usuariosMax}',
      ),
      _UsoItem(
        label: 'UNIDADES',
        usado: uso.unidades,
        max: uso.unidadesMax,
        display: uso.unidadesMax == null
            ? '${uso.unidades} / ilimitado'
            : '${uso.unidades} / ${uso.unidadesMax}',
      ),
      _UsoItem(
        label: 'FOTOS & VÍDEOS',
        usadoDouble: uso.fotosGb,
        maxDouble: uso.fotosGbMax,
        display: uso.fotosGbMax == null
            ? '${_fmtGb(uso.fotosGb)} / ilimitado'
            : '${_fmtGb(uso.fotosGb)} / ${_fmtGb(uso.fotosGbMax!)}',
      ),
    ];

    return SectionCard(
      title: 'Uso do plano',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth >= 600 ? 4 : 2;
        return Wrap(
          children: [
            for (final item in items)
              SizedBox(
                width: constraints.maxWidth / cols,
                child: _UsoItemTile(item: item),
              ),
          ],
        );
      }),
    );
  }
}

class _UsoItem {
  const _UsoItem({
    required this.label,
    required this.display,
    this.usado,
    this.max,
    this.usadoDouble,
    this.maxDouble,
  });

  final String label;
  final String display;
  final int? usado;
  final int? max;
  final double? usadoDouble;
  final double? maxDouble;

  double get ratio {
    if (usadoDouble != null && maxDouble != null) {
      return (usadoDouble! / maxDouble!).clamp(0.0, 1.0);
    }
    if (usado != null && max != null) {
      return (usado! / max!).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  bool get ilimitado => max == null && maxDouble == null;

  Color get barColor {
    if (ilimitado) return AppColors.ok;
    if (ratio >= 1.0) return AppColors.danger;
    if (ratio >= 0.8) return AppColors.warn;
    return AppColors.accent;
  }
}

class _UsoItemTile extends StatelessWidget {
  const _UsoItemTile({required this.item});

  final _UsoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.display,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (!item.ilimitado)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item.ratio,
                minHeight: 5,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation<Color>(item.barColor),
              ),
            )
          else
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.okSoft,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

// ── _MudarDePlanoSection ──────────────────────────────────────────────────────

class _MudarDePlanoSection extends StatelessWidget {
  const _MudarDePlanoSection({
    required this.planoAtual,
    required this.cancelamentoAgendado,
    required this.ciclo,
    required this.submitting,
    required this.onCicloChanged,
    required this.onMudar,
  });

  final NomePlano planoAtual;
  final bool cancelamentoAgendado;
  final CicloCobranca ciclo;
  final bool submitting;
  final ValueChanged<CicloCobranca> onCicloChanged;
  final void Function(NomePlano) onMudar;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Mudar de plano',
      action: _CicloToggle(ciclo: ciclo, onChanged: onCicloChanged),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              for (final opcao in _planosDisponiveis)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanoCard(
                    opcao: opcao,
                    isAtual: opcao.plano == planoAtual,
                    cancelamentoAgendado: cancelamentoAgendado,
                    ciclo: ciclo,
                    submitting: submitting,
                    onMudar: () => onMudar(opcao.plano),
                  ),
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _planosDisponiveis.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _PlanoCard(
                  opcao: _planosDisponiveis[i],
                  isAtual: _planosDisponiveis[i].plano == planoAtual,
                  cancelamentoAgendado: cancelamentoAgendado,
                  ciclo: ciclo,
                  submitting: submitting,
                  onMudar: () => onMudar(_planosDisponiveis[i].plano),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _CicloToggle extends StatelessWidget {
  const _CicloToggle({required this.ciclo, required this.onChanged});

  final CicloCobranca ciclo;
  final ValueChanged<CicloCobranca> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'Mensal',
            active: ciclo == CicloCobranca.mensal,
            onTap: () => onChanged(CicloCobranca.mensal),
          ),
          _ToggleBtn(
            label: 'Anual  −20%',
            active: ciclo == CicloCobranca.anual,
            onTap: () => onChanged(CicloCobranca.anual),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _PlanoCard extends StatelessWidget {
  const _PlanoCard({
    required this.opcao,
    required this.isAtual,
    required this.cancelamentoAgendado,
    required this.ciclo,
    required this.submitting,
    required this.onMudar,
  });

  final _PlanoOpcao opcao;
  final bool isAtual;
  final bool cancelamentoAgendado;
  final CicloCobranca ciclo;
  final bool submitting;
  final VoidCallback onMudar;

  @override
  Widget build(BuildContext context) {
    final preco =
        ciclo == CicloCobranca.mensal ? opcao.precoMensal : opcao.precoAnual;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAtual ? AppColors.accentSoft : AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAtual ? AppColors.accent : AppColors.line,
          width: isAtual ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                opcao.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (isAtual) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PLANO ATUAL',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            opcao.descricao,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _fmtBrl(preco),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const TextSpan(
                  text: '/mês',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          if (ciclo == CicloCobranca.anual) ...[
            const SizedBox(height: 2),
            Text(
              'cobrado anualmente',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.ink3,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isAtual && cancelamentoAgendado
                ? FilledButton(
                    onPressed: submitting ? null : onMudar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reativar plano',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  )
                : isAtual
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Plano atual',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.ink2)),
                  )
                : FilledButton(
                    onPressed: submitting ? null : onMudar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      opcao.plano.index < NomePlano.values
                              .indexOf(opcao.plano)
                          ? 'Fazer downgrade'
                          : _btnLabel(opcao.plano),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _btnLabel(NomePlano p) {
    return switch (p) {
      NomePlano.solo    => 'Mudar para Solo',
      NomePlano.oficina => 'Mudar para Oficina',
      NomePlano.rede    => 'Fazer upgrade →',
    };
  }
}

// ── _HistoricoFaturasSection ──────────────────────────────────────────────────

class _HistoricoFaturasSection extends StatelessWidget {
  const _HistoricoFaturasSection({required this.faturas});

  final List<Fatura> faturas;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Histórico de faturas',
      child: faturas.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Nenhuma fatura encontrada.',
                  style: TextStyle(fontSize: 13, color: AppColors.ink3),
                ),
              ),
            )
          : Column(
              children: [
                _FaturaHeader(),
                for (int i = 0; i < faturas.length; i++) ...[
                  Container(height: 1, color: AppColors.line),
                  _FaturaRow(fatura: faturas[i]),
                ],
              ],
            ),
    );
  }
}

class _FaturaHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.ink3,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('COMPETÊNCIA', style: style)),
          Expanded(flex: 2, child: Text('EMISSÃO', style: style)),
          Expanded(flex: 2, child: Text('PLANO', style: style)),
          Expanded(flex: 2, child: Text('VALOR', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _FaturaRow extends StatelessWidget {
  const _FaturaRow({required this.fatura});

  final Fatura fatura;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: AppColors.ink,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(fatura.competencia, style: bodyStyle)),
          Expanded(
              flex: 2,
              child: Text(_fmtDate(fatura.emissao),
                  style: bodyStyle.copyWith(color: AppColors.ink2))),
          Expanded(
              flex: 2,
              child: Text(fatura.plano, style: bodyStyle)),
          Expanded(
              flex: 2,
              child: Text(_fmtBrl(fatura.valor),
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
            flex: 2,
            child: _PagoChip(pago: fatura.pago),
          ),
          SizedBox(
            width: 32,
            child: fatura.notaUrl != null
                ? IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download_outlined,
                        size: 16, color: AppColors.ink2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Baixar nota',
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _PagoChip extends StatelessWidget {
  const _PagoChip({required this.pago});

  final bool pago;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          pago ? Icons.check_circle_outline : Icons.error_outline,
          size: 14,
          color: pago ? AppColors.ok : AppColors.danger,
        ),
        const SizedBox(width: 4),
        Text(
          pago ? 'PAGO' : 'PENDENTE',
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: pago ? AppColors.ok : AppColors.danger,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ── _MobileUsoHeader ──────────────────────────────────────────────────────────

class _MobileUsoHeader extends StatelessWidget {
  const _MobileUsoHeader({
    required this.detalhes,
    required this.onCancelar,
  });

  final AssinaturaDetalhes detalhes;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final uso = detalhes.uso;
    final cancelando = detalhes.status == StatusAssinatura.cancelamentoAgendado;

    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU PLANO',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.sidebarText.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                detalhes.plano.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: detalhes.status),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _fmtBrl(detalhes.precoMensal),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: '/mês',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF8C8070),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date + ciclo row
          Row(
            children: [
              Icon(
                cancelando
                    ? Icons.calendar_today_outlined
                    : Icons.autorenew_outlined,
                size: 13,
                color: cancelando
                    ? AppColors.danger
                    : AppColors.sidebarText.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                cancelando
                    ? 'Ativo até: ${_fmtDate(detalhes.proximaCobranca)}'
                    : 'Renova em: ${_fmtDate(detalhes.proximaCobranca)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: cancelando
                      ? AppColors.danger
                      : AppColors.sidebarText.withValues(alpha: 0.7),
                ),
              ),
              if (!cancelando) ...[
                const SizedBox(width: 12),
                Icon(Icons.refresh_outlined,
                    size: 13,
                    color: AppColors.sidebarText.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  detalhes.ciclo == CicloCobranca.mensal ? 'Mensal' : 'Anual',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.sidebarText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // 2x2 usage grid
          Row(
            children: [
              Expanded(
                child: _MobileUsoTile(
                  label: 'OS RESTANTES',
                  usado: uso.osMes,
                  max: uso.osMesMax,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileUsoTile(
                  label: 'USUÁRIOS',
                  usado: uso.usuarios,
                  max: uso.usuariosMax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MobileUsoTile(
                  label: 'UNIDADES',
                  usado: uso.unidades,
                  max: uso.unidadesMax,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileUsoTileGb(
                  label: 'FOTOS C. VÍDEOS',
                  usado: uso.fotosGb,
                  max: uso.fotosGbMax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cancel / Reactivate button
          if (cancelando)
            Text(
              'Cancela em ${_fmtDate(detalhes.proximaCobranca)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.danger,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar assinatura',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileUsoTile extends StatelessWidget {
  const _MobileUsoTile({
    required this.label,
    required this.usado,
    required this.max,
  });

  final String label;
  final int usado;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final ratio = max != null ? (usado / max!).clamp(0.0, 1.0) : 0.0;
    final barColor = max == null
        ? AppColors.ok
        : ratio >= 1.0
            ? AppColors.danger
            : ratio >= 0.8
                ? AppColors.warn
                : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF26221D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppColors.sidebarText.withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            max == null ? '$usado / ∞' : '$usado de $max',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: max == null ? 1.0 : ratio,
              minHeight: 3,
              backgroundColor: AppColors.sidebarLine,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileUsoTileGb extends StatelessWidget {
  const _MobileUsoTileGb({
    required this.label,
    required this.usado,
    required this.max,
  });

  final String label;
  final double usado;
  final double? max;

  @override
  Widget build(BuildContext context) {
    final ratio = max != null ? (usado / max!).clamp(0.0, 1.0) : 0.0;
    final barColor = max == null
        ? AppColors.ok
        : ratio >= 1.0
            ? AppColors.danger
            : ratio >= 0.8
                ? AppColors.warn
                : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF26221D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppColors.sidebarText.withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            max == null
                ? '${_fmtGb(usado)} / ∞'
                : '${_fmtGb(usado)} de ${_fmtGb(max!)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: max == null ? 1.0 : ratio,
              minHeight: 3,
              backgroundColor: AppColors.sidebarLine,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
