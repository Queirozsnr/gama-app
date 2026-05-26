import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../veiculos/data/veiculos_remote_data_source.dart';
import '../../veiculos/presentation/veiculos_notifier.dart';
import '../../veiculos/presentation/widgets/veiculo_form_dialog.dart';
import '../data/clientes_remote_data_source.dart';
import '../domain/cliente_detalhe.dart';
import '../domain/cliente.dart';
import 'cliente_detalhe_notifier.dart';
import 'clientes_notifier.dart';
import 'widgets/cliente_form_dialog.dart';

class ClienteDetalheScreen extends ConsumerStatefulWidget {
  const ClienteDetalheScreen({super.key, required this.clienteId});
  final int clienteId;

  @override
  ConsumerState<ClienteDetalheScreen> createState() =>
      _ClienteDetalheScreenState();
}

class _ClienteDetalheScreenState extends ConsumerState<ClienteDetalheScreen>
    with TopBarSlotMixin<ClienteDetalheScreen> {
  bool _menuOpen = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot([ClienteDetalhe? d]) {
    setTopBarSlot(TopBarSlot(
      pageTitle: d?.nome ?? 'Ficha do cliente',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: d == null
          ? 'CLIENTE'
          : (d.vip ? 'CLIENTE · VIP' : 'CLIENTE'),
      mobileAction: d == null
          ? null
          : IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () => _showMobileMenu(d),
            ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/clientes');
          }
        },
        tooltip: 'Voltar',
      ),
      action: d == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _abrirWhatsApp(d.telefone),
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _novaOs(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nova OS'),
                ),
              ],
            ),
    ));
  }

  void _novaOs() => context.push(
        AppRoutes.ordensServicoNova,
        extra: widget.clienteId,
      );

  Future<void> _ligarPara(String? telefone) async {
    if (telefone == null || telefone.isEmpty) {
      GamaSnackBar.error(context, 'Número não cadastrado.');
      return;
    }
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await launchUrl(uri)) {
      if (mounted) GamaSnackBar.error(context, 'Não foi possível realizar a ligação.');
    }
  }

  Future<void> _editarNotas(ClienteDetalhe d) async {
    final ctrl = TextEditingController(text: d.notasInternas ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Notas internas'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Observações internas sobre o cliente…',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved == null || !mounted) return;
    try {
      await ref.read(clientesRemoteDataSourceProvider).atualizar(
        widget.clienteId,
        {
          'nome': d.nome,
          if (d.email != null) 'email': d.email,
          if (d.telefone != null) 'telefone': d.telefone,
          if (d.cpf != null) 'cpf': d.cpf,
          if (d.cidade != null) 'cidade': d.cidade,
          'notasInternas': saved.isEmpty ? null : saved,
        },
      );
      if (!mounted) return;
      ref.invalidate(clienteDetalheProvider(widget.clienteId));
      GamaSnackBar.success(context, 'Notas salvas!');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao salvar notas.');
    }
  }

  Future<void> _adicionarVeiculo() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(clienteIdFixo: widget.clienteId),
    );
    if (result == true && mounted) {
      ref.invalidate(clienteDetalheProvider(widget.clienteId));
      GamaSnackBar.success(context, 'Veículo adicionado!');
    }
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    if (telefone == null || telefone.isEmpty) {
      GamaSnackBar.error(context, 'Número não cadastrado.');
      return;
    }
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    final number = digits.startsWith('55') ? digits : '55$digits';
    final uri = Uri.parse('https://wa.me/$number');
    if (!await launchUrl(uri)) {
      if (mounted) GamaSnackBar.error(context, 'Não foi possível abrir o WhatsApp.');
    }
  }

  void _showMobileMenu(ClienteDetalhe d) {
    if (_menuOpen) return;
    _menuOpen = true;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar cliente'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _editarCliente(d);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Adicionar veículo'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _adicionarVeiculo();
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => _menuOpen = false);
  }

  Future<void> _editarVeiculo(int veiculoId) async {
    try {
      final veiculo = await ref
          .read(veiculosRemoteDataSourceProvider)
          .obter(veiculoId);
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => VeiculoFormDialog(veiculo: veiculo),
      );
      if (result == true && mounted) {
        ref.invalidate(clienteDetalheProvider(widget.clienteId));
        GamaSnackBar.success(context, 'Veículo atualizado!');
      }
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao carregar veículo.');
    }
  }

  Future<void> _excluirVeiculo(int veiculoId, String nome) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir veículo',
      message: 'Deseja excluir $nome? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref.read(veiculosNotifierProvider.notifier).excluir(veiculoId);
      if (mounted) {
        ref.invalidate(clienteDetalheProvider(widget.clienteId));
        GamaSnackBar.success(context, 'Veículo excluído.');
      }
    } catch (e) {
      if (mounted) {
        final dio = e is DioException ? e : null;
        final serverMsg = dio?.response?.data is Map ? dio?.response?.data['error'] as String? : null;
        GamaSnackBar.error(context, serverMsg ?? 'Erro ao excluir veículo.');
      }
    }
  }

  Future<void> _editarCliente(ClienteDetalhe d) async {
    final cliente = Cliente(
      id: d.id,
      nome: d.nome,
      email: d.email,
      telefone: d.telefone,
      cpf: d.cpf,
      cidade: d.cidade,
      ativo: d.ativo,
      criadoEm: d.criadoEm,
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ClienteFormDialog(cliente: cliente),
    );
    if (result == true && mounted) {
      ref.invalidate(clienteDetalheProvider(widget.clienteId));
      ref.invalidate(clientesNotifierProvider);
      GamaSnackBar.success(context, 'Cliente atualizado!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalheAsync = ref.watch(clienteDetalheProvider(widget.clienteId));

    return detalheAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        onRetry: () => ref.invalidate(clienteDetalheProvider(widget.clienteId)),
      ),
      data: (d) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncSlot(d);
        });
        final isDesktop = MediaQuery.of(context).size.width >= 800;
        if (isDesktop) {
          return _DesktopLayout(
            detalhe: d,
            onEditarCliente: () => _editarCliente(d),
            onAddVeiculo: _adicionarVeiculo,
            onEditarVeiculo: _editarVeiculo,
            onNovaOs: _novaOs,
            onVerTodasOs: () => context.go('/ordens-servico'),
            onAbrirOs: (id) => context.push('/ordens-servico/$id'),
            onAgendar: (_) {},
            onEditarNotas: () => _editarNotas(d),
          );
        }
        return _MobileLayout(
          detalhe: d,
          onEditarCliente: () => _editarCliente(d),
          onAddVeiculo: _adicionarVeiculo,
          onExcluirVeiculo: _excluirVeiculo,
          onWhatsApp: () => _abrirWhatsApp(d.telefone),
          onLigar: () => _ligarPara(d.telefone),
          onNovaOs: _novaOs,
          onEditarVeiculo: _editarVeiculo,
          onVerTodasOs: () => context.go('/ordens-servico'),
          onAbrirOs: (id) => context.push('/ordens-servico/$id'),
          onEditarNotas: () => _editarNotas(d),
        );
      },
    );
  }
}

// ── Desktop layout ─────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.detalhe,
    required this.onEditarCliente,
    required this.onAddVeiculo,
    required this.onEditarVeiculo,
    required this.onNovaOs,
    required this.onVerTodasOs,
    required this.onAbrirOs,
    required this.onAgendar,
    required this.onEditarNotas,
  });

  final ClienteDetalhe detalhe;
  final VoidCallback onEditarCliente;
  final VoidCallback onAddVeiculo;
  final ValueChanged<int> onEditarVeiculo;
  final VoidCallback onNovaOs;
  final VoidCallback onVerTodasOs;
  final ValueChanged<int> onAbrirOs;
  final ValueChanged<ProximaAcao> onAgendar;
  final VoidCallback onEditarNotas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiBar(detalhe: detalhe),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _VeiculosSection(
                        veiculos: detalhe.veiculos,
                        onAddVeiculo: onAddVeiculo,
                        onEditarVeiculo: onEditarVeiculo,
                      ),
                      const SizedBox(height: 14),
                      _OsHistoricoSection(
                        ultimasOs: detalhe.ultimasOs,
                        osConcluidas: detalhe.osConcluidas,
                        osEmAndamento: detalhe.osEmAndamento,
                        onVerTodas: onVerTodasOs,
                        onAbrirOs: onAbrirOs,
                      ),
                      if (detalhe.proximasAcoes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _ProximasAcoesSection(
                          acoes: detalhe.proximasAcoes,
                          onAgendar: onAgendar,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 288,
                  child: _Sidebar(
                    detalhe: detalhe,
                    onEditar: onEditarCliente,
                    onEditarNotas: onEditarNotas,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── KPI bar ────────────────────────────────────────────────────────────────────

class _KpiBar extends StatelessWidget {
  const _KpiBar({required this.detalhe});
  final ClienteDetalhe detalhe;

  @override
  Widget build(BuildContext context) {
    final uv = detalhe.ultimaVisita;
    final uvLabel = uv == null ? '—' : _relativeDate(uv.data);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _KpiCard(
            label: 'TOTAL GASTO',
            value: _fmtBrl(detalhe.totalGasto),
            sub: 'em todas as OS',
          ),
          _KpiDivider(),
          _KpiCard(
            label: 'OS CONCLUÍDAS',
            value: '${detalhe.osConcluidas}',
            sub: detalhe.osEmAndamento > 0
                ? '+ ${detalhe.osEmAndamento} em andamento'
                : 'nenhuma em andamento',
          ),
          _KpiDivider(),
          _KpiCard(
            label: 'TICKET MÉDIO',
            value: _fmtBrl(detalhe.ticketMedio),
            sub: 'por OS',
          ),
          _KpiDivider(),
          _KpiCard(
            label: 'ÚLTIMA VISITA',
            value: uvLabel,
            sub: uv != null ? '#${uv.osId} · ${uv.descricao}' : null,
            valueColor: uv != null && _isToday(uv.data) ? AppColors.ok : null,
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: AppColors.line,
        margin: const EdgeInsets.symmetric(horizontal: 20),
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.ink,
              height: 1.1,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3),
            ),
        ],
      ),
    );
  }
}

// ── Veículos ───────────────────────────────────────────────────────────────────

class _VeiculosSection extends StatelessWidget {
  const _VeiculosSection({
    required this.veiculos,
    required this.onAddVeiculo,
    required this.onEditarVeiculo,
  });
  final List<VeiculoDetalhe> veiculos;
  final VoidCallback onAddVeiculo;
  final ValueChanged<int> onEditarVeiculo;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.directions_car_outlined,
      title: 'Veículos · ${veiculos.length}',
      action: TextButton.icon(
        onPressed: onAddVeiculo,
        icon: const Icon(Icons.add, size: 15),
        label: const Text('Adicionar veículo'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      child: veiculos.isEmpty
          ? const _EmptyState(message: 'Nenhum veículo cadastrado')
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: veiculos
                    .map((v) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: v == veiculos.last ? 0 : 12,
                            ),
                            child: _VeiculoCard(
                              veiculo: v,
                              onTap: () => onEditarVeiculo(v.id),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
    );
  }
}

class _VeiculoCard extends StatelessWidget {
  const _VeiculoCard({required this.veiculo, this.onTap});
  final VeiculoDetalhe veiculo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final km = veiculo.odometro;
    final proxKm = veiculo.proxRevisaoKm;
    final diffKm = (km != null && proxKm != null) ? proxKm - km : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car_outlined,
                    size: 20, color: AppColors.ink2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      veiculo.modeloNome,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (veiculo.placa != null)
                          _SmallPlate(veiculo.placa!),
                        if (veiculo.placa != null && (veiculo.ano != null || veiculo.cor != null))
                          const SizedBox(width: 6),
                        if (veiculo.ano != null || veiculo.cor != null)
                          Text(
                            [
                              if (veiculo.ano != null) '${veiculo.ano}',
                              if (veiculo.cor != null) veiculo.cor!,
                            ].join(' · '),
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 11,
                              color: AppColors.ink2,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: veiculo.status),
            ],
          ),
          if (km != null || proxKm != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 10),
            Row(
              children: [
                if (km != null)
                  Expanded(
                    child: _MetaRow(
                      label: 'ODÔMETRO',
                      value: '${_fmtKm(km)} km',
                    ),
                  ),
                if (proxKm != null)
                  Expanded(
                    child: _MetaRow(
                      label: 'PRÓX. REVISÃO',
                      value: '${_fmtKm(proxKm)} km',
                      sub: diffKm != null
                          ? '${diffKm >= 0 ? '+' : ''}${_fmtKm(diffKm)} km'
                          : null,
                      subColor: diffKm != null && diffKm < 0
                          ? AppColors.danger
                          : AppColors.ink3,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  static String _fmtKm(int km) =>
      km.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final VeiculoStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.ink3,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              color: subColor ?? AppColors.ink3,
            ),
          ),
      ],
    );
  }
}

class _SmallPlate extends StatelessWidget {
  const _SmallPlate(this.plate);
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        plate,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

// ── Histórico de OS ────────────────────────────────────────────────────────────

class _OsHistoricoSection extends StatelessWidget {
  const _OsHistoricoSection({
    required this.ultimasOs,
    required this.osConcluidas,
    required this.osEmAndamento,
    required this.onVerTodas,
    required this.onAbrirOs,
  });
  final List<OsResumoCliente> ultimasOs;
  final int osConcluidas;
  final int osEmAndamento;
  final VoidCallback onVerTodas;
  final ValueChanged<int> onAbrirOs;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.receipt_long_outlined,
      title: 'Histórico de OS',
      subtitle: '$osConcluidas concluídas · $osEmAndamento em andamento',
      action: TextButton(
        onPressed: onVerTodas,
        child: const Text('Ver todas  ›'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink3,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      child: ultimasOs.isEmpty
          ? const _EmptyState(message: 'Nenhuma OS encontrada')
          : LayoutBuilder(
              builder: (_, constraints) {
                final narrow = constraints.maxWidth < 480;
                return Column(
                  children: [
                    _OsTableHeader(narrow: narrow),
                    const Divider(height: 1, color: AppColors.line),
                    ...ultimasOs.map((os) => _OsHistoricoRow(
                          os: os,
                          narrow: narrow,
                          onTap: () => onAbrirOs(os.id),
                        )),
                  ],
                );
              },
            ),
    );
  }
}

class _OsTableHeader extends StatelessWidget {
  const _OsTableHeader({this.narrow = false});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 32, child: _HeaderCell('OS')),
          const SizedBox(width: 96, child: _HeaderCell('STATUS')),
          const Expanded(child: _HeaderCell('SERVIÇO · VEÍCULO')),
          if (!narrow) const SizedBox(width: 80, child: _HeaderCell('MECÂNICO')),
          const SizedBox(width: 72, child: _HeaderCell('VALOR')),
          const SizedBox(width: 40, child: _HeaderCell('DATA')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.ink2,
          letterSpacing: 0.4,
        ),
      );
}

class _OsHistoricoRow extends StatelessWidget {
  const _OsHistoricoRow({required this.os, this.narrow = false, this.onTap});
  final OsResumoCliente os;
  final bool narrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _OsStatusInfo.fromString(os.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${os.id}',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: _OsStatusChip(status: status),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (os.descricao != null)
                  Text(
                    os.descricao!,
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (os.veiculoPlaca != null || os.veiculoDescricao != null)
                  Row(
                    children: [
                      if (os.veiculoPlaca != null) ...[
                        _SmallPlate(os.veiculoPlaca!),
                        const SizedBox(width: 5),
                      ],
                      if (os.veiculoDescricao != null)
                        Text(
                          os.veiculoDescricao!,
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 11, color: AppColors.ink2),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (!narrow)
            SizedBox(
              width: 80,
              child: Text(
                os.mecanicoNome ?? '—',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(
            width: 72,
            child: Text(
              _fmtBrl(os.total),
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${os.data.day.toString().padLeft(2, '0')}/${os.data.month.toString().padLeft(2, '0')}',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
            ),
          ),
        ],
      ),
      ),
    );
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _OsStatusInfo {
  const _OsStatusInfo({required this.label, required this.color, required this.bgColor});
  final String label;
  final Color color;
  final Color bgColor;

  static _OsStatusInfo fromString(String s) {
    return switch (s.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      'emandamento' || 'aberta'   => const _OsStatusInfo(label: 'EM ANDAMENTO', color: AppColors.info,    bgColor: AppColors.infoSoft),
      'pronto'                    => const _OsStatusInfo(label: 'PRONTO',       color: AppColors.ok,      bgColor: AppColors.okSoft),
      'concluida' || 'concluída'  => const _OsStatusInfo(label: 'CONCLUÍDA',    color: AppColors.ok,      bgColor: AppColors.okSoft),
      'entregue'                  => const _OsStatusInfo(label: 'ENTREGUE',     color: AppColors.ink3,    bgColor: AppColors.bg),
      'aguardando' || 'pendente'  => const _OsStatusInfo(label: 'AGUARDANDO',   color: AppColors.warn,    bgColor: AppColors.warnSoft),
      _                           => const _OsStatusInfo(label: 'ABERTA',       color: AppColors.ink3,    bgColor: AppColors.bg),
    };
  }
}

class _OsStatusChip extends StatelessWidget {
  const _OsStatusChip({required this.status});
  final _OsStatusInfo status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Próximas ações ─────────────────────────────────────────────────────────────

class _ProximasAcoesSection extends StatelessWidget {
  const _ProximasAcoesSection({required this.acoes, required this.onAgendar});
  final List<ProximaAcao> acoes;
  final ValueChanged<ProximaAcao> onAgendar;

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.calendar_today_outlined,
      title: 'Próximas ações',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: acoes
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AcaoCard(acao: a, onAgendar: () => onAgendar(a)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _AcaoCard extends StatelessWidget {
  const _AcaoCard({required this.acao, required this.onAgendar});
  final ProximaAcao acao;
  final VoidCallback onAgendar;

  static IconData _icon(ProximaAcaoTipo t) => switch (t) {
        ProximaAcaoTipo.revisao   => Icons.build_outlined,
        ProximaAcaoTipo.orcamento => Icons.description_outlined,
        ProximaAcaoTipo.retorno   => Icons.phone_callback_outlined,
        ProximaAcaoTipo.outro     => Icons.schedule_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(_icon(acao.tipo), size: 18, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acao.descricao,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (acao.detalhe != null)
                  Text(
                    acao.detalhe!,
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 11,
                      color: AppColors.ink3,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAgendar,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Agendar',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.detalhe, required this.onEditar, required this.onEditarNotas});
  final ClienteDetalhe detalhe;
  final VoidCallback onEditar;
  final VoidCallback onEditarNotas;

  String get _initials {
    final parts = detalhe.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return detalhe.nome.substring(0, detalhe.nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GamaAvatar(initials: _initials, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  detalhe.nome,
                                  style: TextStyle(fontFamily: 'Inter', 
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (detalhe.vip) ...[
                                const SizedBox(width: 6),
                                _VipBadge(),
                              ],
                            ],
                          ),
                          Text(
                            'Cliente desde ${_fmtDate(detalhe.criadoEm)}',
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: onEditar,
                      color: AppColors.ink3,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    if (detalhe.telefone != null)
                      _ContactRow(icon: Icons.phone_outlined, text: detalhe.telefone!),
                    if (detalhe.email != null)
                      _ContactRow(icon: Icons.email_outlined, text: detalhe.email!),
                    if (detalhe.cidade != null)
                      _ContactRow(icon: Icons.location_on_outlined, text: detalhe.cidade!),
                    if (detalhe.cpf != null)
                      _ContactRow(icon: Icons.badge_outlined, text: detalhe.cpf!),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined,
                        size: 16, color: AppColors.ink3),
                    const SizedBox(width: 6),
                    Text(
                      'Notas internas',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      onPressed: onEditarNotas,
                      color: AppColors.ink3,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                detalhe.notasInternas != null && detalhe.notasInternas!.isNotEmpty
                    ? Text(
                        detalhe.notasInternas!,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.5,
                        ),
                      )
                    : Text(
                        'Nenhuma nota adicionada.',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          color: AppColors.ink3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ],
            ),
          ),
        ),
        if (detalhe.preferencias != null) ...[
          const SizedBox(height: 12),
          _SidebarCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_outlined,
                          size: 16, color: AppColors.ink3),
                      const SizedBox(width: 6),
                      Text(
                        'Preferências',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PrefRow(
                    label: 'Forma de pagamento',
                    value: detalhe.preferencias!.formaPagamento ?? '—',
                  ),
                  _PrefRow(
                    label: 'Canal preferido',
                    value: detalhe.preferencias!.canalPreferido ?? '—',
                  ),
                  _PrefRow(
                    label: 'Recebe lembretes',
                    value: detalhe.preferencias!.recebeLembretes ? 'Sim' : 'Não',
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.ink3),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink3),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.okSoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ok.withValues(alpha: 0.3)),
      ),
      child: Text(
        'VIP',
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.ok,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Section container ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3),
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar ficha do cliente',
            style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ──────────────────────────────────────────────────────────────

class _MobileLayout extends StatefulWidget {
  const _MobileLayout({
    required this.detalhe,
    required this.onEditarCliente,
    required this.onAddVeiculo,
    required this.onExcluirVeiculo,
    required this.onWhatsApp,
    required this.onLigar,
    required this.onNovaOs,
    required this.onEditarVeiculo,
    required this.onVerTodasOs,
    required this.onAbrirOs,
    required this.onEditarNotas,
  });

  final ClienteDetalhe detalhe;
  final VoidCallback onEditarCliente;
  final VoidCallback onAddVeiculo;
  final void Function(int id, String nome) onExcluirVeiculo;
  final VoidCallback onWhatsApp;
  final VoidCallback onLigar;
  final VoidCallback onNovaOs;
  final ValueChanged<int> onEditarVeiculo;
  final VoidCallback onVerTodasOs;
  final ValueChanged<int> onAbrirOs;
  final VoidCallback onEditarNotas;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.detalhe;
    return Column(
      children: [
        _MobileHeader(
          detalhe: d,
          onEditarCliente: widget.onEditarCliente,
          onNovaOs: widget.onNovaOs,
          onWhatsApp: widget.onWhatsApp,
          onLigar: widget.onLigar,
        ),
        _MobileKpiStrip(detalhe: d),
        _MobileTabBar(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: switch (_tab) {
              0 => _MobileResumoContent(
                  detalhe: d,
                  onAddVeiculo: widget.onAddVeiculo,
                  onExcluirVeiculo: widget.onExcluirVeiculo,
                  onEditarVeiculo: widget.onEditarVeiculo,
                  onVerTodasOs: widget.onVerTodasOs,
                  onAbrirOs: widget.onAbrirOs,
                  onEditarNotas: widget.onEditarNotas,
                ),
              1 => _MobileVeiculosContent(
                  veiculos: d.veiculos,
                  onEditarVeiculo: widget.onEditarVeiculo,
                  onExcluirVeiculo: widget.onExcluirVeiculo,
                  onAddVeiculo: widget.onAddVeiculo,
                ),
              2 => _MobileOsContent(
                  ultimasOs: d.ultimasOs,
                  onAbrirOs: widget.onAbrirOs,
                ),
              _ => const SizedBox(),
            },
          ),
        ),
      ],
    );
  }
}

// ── Mobile header (dark area below top bar) ────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.detalhe,
    required this.onEditarCliente,
    required this.onNovaOs,
    required this.onWhatsApp,
    required this.onLigar,
  });

  final ClienteDetalhe detalhe;
  final VoidCallback onEditarCliente;
  final VoidCallback onNovaOs;
  final VoidCallback onWhatsApp;
  final VoidCallback onLigar;

  String get _initials {
    final parts = detalhe.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return detalhe.nome.substring(0, detalhe.nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GamaAvatar(initials: _initials, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detalhe.telefone != null)
                      _MobileDarkRow(
                        icon: Icons.phone_outlined,
                        text: detalhe.telefone!,
                      ),
                    if (detalhe.cidade != null)
                      _MobileDarkRow(
                        icon: Icons.location_on_outlined,
                        text:
                            '${detalhe.cidade} · desde ${_fmtDate(detalhe.criadoEm)}',
                      )
                    else
                      _MobileDarkRow(
                        icon: Icons.calendar_today_outlined,
                        text: 'desde ${_fmtDate(detalhe.criadoEm)}',
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNovaOs,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nova OS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onLigar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 40),
                ),
                child: const Icon(Icons.phone_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MobileDarkRow extends StatelessWidget {
  const _MobileDarkRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.sidebarText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                color: AppColors.sidebarText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile KPI strip ───────────────────────────────────────────────────────────

class _MobileKpiStrip extends StatelessWidget {
  const _MobileKpiStrip({required this.detalhe});
  final ClienteDetalhe detalhe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _MobileKpiCell(
            label: 'TOTAL GASTO',
            value: _fmtCompact(detalhe.totalGasto),
          ),
          _MobileKpiDivider(),
          _MobileKpiCell(
            label: 'OS',
            value: '${detalhe.osConcluidas}',
          ),
          _MobileKpiDivider(),
          _MobileKpiCell(
            label: 'TICKET',
            value: _fmtCompact(detalhe.ticketMedio),
          ),
        ],
      ),
    );
  }

  static String _fmtCompact(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return 'R\$ ${k.toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _MobileKpiCell extends StatelessWidget {
  const _MobileKpiCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileKpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.line,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );
}

// ── Mobile tab bar ─────────────────────────────────────────────────────────────

class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  static const _labels = ['Resumo', 'Veículos', 'OS'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.accent : AppColors.ink3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Mobile tab contents ────────────────────────────────────────────────────────

class _MobileResumoContent extends StatelessWidget {
  const _MobileResumoContent({
    required this.detalhe,
    required this.onAddVeiculo,
    required this.onExcluirVeiculo,
    required this.onEditarVeiculo,
    required this.onVerTodasOs,
    required this.onAbrirOs,
    required this.onEditarNotas,
  });

  final ClienteDetalhe detalhe;
  final VoidCallback onAddVeiculo;
  final void Function(int id, String nome) onExcluirVeiculo;
  final ValueChanged<int> onEditarVeiculo;
  final VoidCallback onVerTodasOs;
  final ValueChanged<int> onAbrirOs;
  final VoidCallback onEditarNotas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vehicles
          _MobileSectionHeader(
            label: 'VEÍCULOS · ${detalhe.veiculos.length}',
            action: TextButton.icon(
              onPressed: onAddVeiculo,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Novo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (detalhe.veiculos.isEmpty)
            _MobileEmptyCard(message: 'Nenhum veículo cadastrado')
          else
            ...detalhe.veiculos.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MobileVeiculoCard(
                    veiculo: v,
                    onTap: () => onEditarVeiculo(v.id),
                    onLongPress: () => onExcluirVeiculo(v.id, v.modeloNome),
                    onExcluir: () => onExcluirVeiculo(v.id, v.modeloNome),
                  ),
                )),
          const SizedBox(height: 20),

          // Recent OS
          _MobileSectionHeader(
            label: 'OS RECENTES',
            action: TextButton(
              onPressed: onVerTodasOs,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink3,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ver todas  ›'),
            ),
          ),
          const SizedBox(height: 8),
          if (detalhe.ultimasOs.isEmpty)
            _MobileEmptyCard(message: 'Nenhuma OS encontrada')
          else
            ...detalhe.ultimasOs.take(5).map((os) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MobileOsCard(
                    os: os,
                    onTap: () => onAbrirOs(os.id),
                  ),
                )),
          const SizedBox(height: 20),

          // Notas internas
          _MobileNotasCard(notas: detalhe.notasInternas, onEditar: onEditarNotas),
        ],
      ),
    );
  }
}

class _MobileVeiculosContent extends StatelessWidget {
  const _MobileVeiculosContent({
    required this.veiculos,
    required this.onEditarVeiculo,
    required this.onExcluirVeiculo,
    required this.onAddVeiculo,
  });

  final List<VeiculoDetalhe> veiculos;
  final ValueChanged<int> onEditarVeiculo;
  final void Function(int id, String nome) onExcluirVeiculo;
  final VoidCallback onAddVeiculo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          if (veiculos.isEmpty)
            _MobileEmptyCard(message: 'Nenhum veículo cadastrado')
          else
            ...veiculos.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MobileVeiculoCard(
                    veiculo: v,
                    onTap: () => onEditarVeiculo(v.id),
                    onLongPress: () => onExcluirVeiculo(v.id, v.modeloNome),
                    onExcluir: () => onExcluirVeiculo(v.id, v.modeloNome),
                  ),
                )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAddVeiculo,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Adicionar veículo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileOsContent extends StatelessWidget {
  const _MobileOsContent({required this.ultimasOs, required this.onAbrirOs});

  final List<OsResumoCliente> ultimasOs;
  final ValueChanged<int> onAbrirOs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: ultimasOs.isEmpty
            ? [_MobileEmptyCard(message: 'Nenhuma OS encontrada')]
            : ultimasOs
                .map((os) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MobileOsCard(
                        os: os,
                        onTap: () => onAbrirOs(os.id),
                      ),
                    ))
                .toList(),
      ),
    );
  }
}

// ── Mobile cards ───────────────────────────────────────────────────────────────

class _MobileVeiculoCard extends StatelessWidget {
  const _MobileVeiculoCard({required this.veiculo, this.onTap, this.onLongPress, this.onExcluir});
  final VeiculoDetalhe veiculo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onExcluir;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_outlined,
                  size: 18, color: AppColors.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    veiculo.modeloNome,
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (veiculo.placa != null) ...[
                        _SmallPlate(veiculo.placa!),
                        const SizedBox(width: 6),
                      ],
                      if (veiculo.odometro != null)
                        Text(
                          '${_fmtKm(veiculo.odometro!)} km',
                          style: TextStyle(fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: veiculo.status),
            if (onExcluir != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.ink3),
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
                onSelected: (val) { if (val == 'excluir') onExcluir!(); },
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtKm(int km) =>
      km.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
}

class _MobileOsCard extends StatelessWidget {
  const _MobileOsCard({required this.os, this.onTap});
  final OsResumoCliente os;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _OsStatusInfo.fromString(os.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${os.id}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(width: 8),
                _OsStatusChip(status: status),
                const Spacer(),
                Text(
                  '${os.data.day.toString().padLeft(2, '0')}/${os.data.month.toString().padLeft(2, '0')}',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3),
                ),
              ],
            ),
            if (os.descricao != null) ...[
              const SizedBox(height: 6),
              Text(
                os.descricao!,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                if (os.veiculoPlaca != null) ...[
                  _SmallPlate(os.veiculoPlaca!),
                  const SizedBox(width: 6),
                ],
                if (os.veiculoDescricao != null)
                  Expanded(
                    child: Text(
                      os.veiculoDescricao!,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  _fmtBrl(os.total),
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

// ── Mobile helpers ─────────────────────────────────────────────────────────────

class _MobileSectionHeader extends StatelessWidget {
  const _MobileSectionHeader({required this.label, this.action});
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.ink3,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        if (action case final a?) a,
      ],
    );
  }
}

class _MobileNotasCard extends StatelessWidget {
  const _MobileNotasCard({required this.notas, required this.onEditar});
  final String? notas;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined,
                  size: 14, color: AppColors.ink3),
              const SizedBox(width: 6),
              Text(
                'NOTAS INTERNAS',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink3,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 14),
                onPressed: onEditar,
                color: AppColors.ink3,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          notas != null && notas!.isNotEmpty
              ? Text(
                  notas!,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    color: AppColors.ink2,
                    height: 1.5,
                  ),
                )
              : Text(
                  'Nenhuma nota adicionada.',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    color: AppColors.ink3,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ],
      ),
    );
  }
}

class _MobileEmptyCard extends StatelessWidget {
  const _MobileEmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3),
        ),
      ),
    );
  }
}
