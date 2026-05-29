import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/state/top_bar_scope.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../../../shared/widgets/gama_searchable_select.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../clientes/data/clientes_remote_data_source.dart';
import '../../clientes/domain/cliente.dart';
import '../../clientes/presentation/widgets/cliente_form_dialog.dart';
import '../../veiculos/data/veiculos_remote_data_source.dart';
import '../../veiculos/domain/veiculo.dart';
import '../../veiculos/presentation/widgets/veiculo_form_dialog.dart';
import '../data/ordens_servico_remote_data_source.dart';
import 'ordens_servico_notifier.dart';
import '../../estoque/data/estoque_remote_data_source.dart';
import '../../estoque/domain/estoque.dart';
import '../../funcionarios/data/funcionarios_remote_data_source.dart';
import '../../funcionarios/domain/funcionario.dart';

// ── Constants ──────────────────────────────────────────────────────────────────
const _formasPagamento = ['Dinheiro', 'Pix', 'CartaoDebito', 'CartaoCredito', 'Transferencia', 'Outro'];
const _formasPagamentoLabels = {
  'Dinheiro': 'Dinheiro', 'Pix': 'Pix', 'CartaoDebito': 'Cartão de débito',
  'CartaoCredito': 'Cartão de crédito', 'Transferencia': 'Transferência', 'Outro': 'Outro',
};

const _stepLabels = ['Cliente', 'Serviços', 'Peças', 'Resumo'];

String _fmtMoney(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

// ── Model ──────────────────────────────────────────────────────────────────────
class _ItemInput {
  _ItemInput({
    required this.tipo, required this.descricao,
    required this.quantidade, required this.valorUnitario,
    this.origemPeca, this.produtoId, this.produtoCodigo, this.produtoEstoque,
  });
  String tipo, descricao;
  double quantidade, valorUnitario;
  String? origemPeca;
  int? produtoId;
  String? produtoCodigo;
  double? produtoEstoque;
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class OsNovaScreen extends ConsumerStatefulWidget {
  const OsNovaScreen({super.key, this.clienteIdInicial});
  final int? clienteIdInicial;

  @override
  ConsumerState<OsNovaScreen> createState() => _OsNovaScreenState();
}

class _OsNovaScreenState extends ConsumerState<OsNovaScreen>
    with TopBarSlotMixin<OsNovaScreen> {
  int _activeStep = 0;
  int _pecaSearchKey = 0;
  final _scrollCtrl = ScrollController();
  final _sectionKeys = List<GlobalKey>.generate(4, (_) => GlobalKey());
  Cliente? _cliente;
  Veiculo? _veiculo;
  Funcionario? _mecanico;
  DateTime? _previsaoEntrega;
  String? _formaPagamento;
  final _obsCtrl = TextEditingController();
  final List<_ItemInput> _servicos = [];
  final List<_ItemInput> _pecas = [];
  bool _loading = false;

  static const _sectionTitles = [
    'Cliente e veículo', 'Serviços', 'Peças aplicadas', 'Resumo · Atribuição · Prazo',
  ];
  static const _sectionSubtitles = [
    'Selecione o cliente e o veículo',
    'Adicione os serviços a serem realizados',
    'Busque do estoque ou marque como compra externa',
    'Conferir prazo e atribuir mecânico (opcional)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.clienteIdInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final c = await ref
              .read(clientesRemoteDataSourceProvider)
              .obter(widget.clienteIdInicial!);
          if (mounted) setState(() => _cliente = c);
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _totalServicos() => _servicos.fold(0.0, (s, i) => s + i.quantidade * i.valorUnitario);
  double _totalPecas() => _pecas
      .where((i) => i.origemPeca != 'ClienteTrouxe')
      .fold(0.0, (s, i) => s + i.quantidade * i.valorUnitario);
  double _totalGeral() => _totalServicos() + _totalPecas();

  String _initials(String nome) {
    final parts = nome.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts.isNotEmpty ? parts[0][0] : '?';
  }

  bool _validarEtapa() {
    if (_activeStep == 0) {
      if (_cliente == null) { GamaSnackBar.error(context, 'Selecione um cliente.'); return false; }
      if (_veiculo == null) { GamaSnackBar.error(context, 'Selecione um veículo.'); return false; }
    }
    return true;
  }

  void _goNext() {
    if (!_validarEtapa()) return;
    if (_activeStep >= 3) return;
    setState(() => _activeStep++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[_activeStep].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  void _goToSection(int idx) {
    setState(() => _activeStep = idx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _previsaoEntrega = d);
  }

  Future<void> _salvar() async {
    if (_cliente == null) { GamaSnackBar.error(context, 'Selecione um cliente.'); return; }
    if (_veiculo == null) { GamaSnackBar.error(context, 'Selecione um veículo.'); return; }
    for (final item in [..._servicos, ..._pecas]) {
      if (item.descricao.trim().isEmpty) {
        GamaSnackBar.error(context, 'Preencha a descrição de todos os itens.');
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final todos = [..._servicos, ..._pecas];
      final id = await ref.read(ordensServicoRemoteDataSourceProvider).criar({
        'clienteId': _cliente!.id,
        'veiculoId': _veiculo!.id,
        if (_obsCtrl.text.trim().isNotEmpty) 'observacoes': _obsCtrl.text.trim(),
        if (_previsaoEntrega != null) 'previsaoEntrega': _previsaoEntrega!.toIso8601String(),
        if (_formaPagamento != null) 'formaPagamento': _formaPagamento,
        'mecanicoIds': _mecanico != null ? [_mecanico!.id] : <int>[],
        'itens': todos.map((i) => <String, dynamic>{
          'tipo': i.tipo,
          'descricao': i.descricao,
          'quantidade': i.quantidade,
          'valorUnitario': i.valorUnitario,
          if (i.tipo == 'Peca' && i.origemPeca != null) 'origemPeca': i.origemPeca,
          if (i.produtoId != null) 'produtoId': i.produtoId,
        }).toList(),
      });
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) {
        GamaSnackBar.success(context, 'OS #$id criada!');
        context.go('/ordens-servico/$id');
      }
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao criar OS.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    setTopBarSlot(TopBarSlot(
      mobileSubtitle: 'ORDENS / NOVA',
      pageTitle: 'Abrir OS',
      leading: IconButton(
        onPressed: () => context.go('/ordens-servico'),
        icon: const Icon(Icons.close),
        color: AppColors.ink2,
      ),
      mobileAction: const _RascunhoChip(),
    ));

    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ── Mobile: single scroll with accordion sections ───────────────────────────
  Widget _buildMobile() {
    return Column(
      children: [
        _StepBar(currentStep: _activeStep),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (int i = 0; i < 4; i++) _buildSection(i),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _MobileBottomBar(
          totalGeral: _totalGeral(),
          nServicos: _servicos.length,
          nPecas: _pecas.length,
          step: _activeStep,
          loading: _loading,
          onNext: _activeStep < 3 ? _goNext : null,
          onCriar: _activeStep == 3 ? _salvar : null,
        ),
      ],
    );
  }

  Widget _buildSection(int idx) {
    final isActive = idx == _activeStep;
    final isDone = idx < _activeStep;
    final isPending = idx > _activeStep;

    return Container(
      key: _sectionKeys[idx],
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.accent : AppColors.line,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.ok : isActive ? AppColors.accent : AppColors.line,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : AppColors.ink3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_sectionTitles[idx],
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: isPending ? AppColors.ink2 : AppColors.ink)),
                      Text(_sectionSubtitles[idx],
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3)),
                    ],
                  ),
                ),
                if (isDone)
                  GestureDetector(
                    onTap: () => _goToSection(idx),
                    child: Text('Editar',
                        style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ),
              ],
            ),
          ),
          if (!isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _sectionContent(idx, isDone),
            ),
        ],
      ),
    );
  }

  Widget _sectionContent(int idx, bool isDone) {
    switch (idx) {
      case 0:
        return isDone && _cliente != null ? _clienteSummary() : _step0Fields();
      case 1:
        return _step1Content();
      case 2:
        return _step2Content();
      case 3:
        return _step3Content();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _clienteSummary() {
    return Row(children: [
      GamaAvatar(initials: _initials(_cliente!.nome), size: 36),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_cliente!.nome,
              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (_veiculo != null)
            Row(children: [
              _SmallPlate(placa: _veiculo!.placa ?? ''),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_veiculo!.modeloNome,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
        ]),
      ),
    ]);
  }

  Future<void> _abrirNovoCliente() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => ClienteFormDialog(
        onCriado: (c) {
          if (mounted) setState(() { _cliente = c; _veiculo = null; });
        },
      ),
    );
  }

  Future<void> _abrirNovoVeiculo() async {
    if (_cliente == null) return;
    await showDialog<bool>(
      context: context,
      builder: (_) => VeiculoFormDialog(
        clienteIdFixo: _cliente!.id,
        onCriado: (v) {
          if (mounted) setState(() => _veiculo = v);
        },
      ),
    );
  }

  Widget _step0Fields() {
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GamaSearchableSelect<Cliente>(
              label: 'Cliente *',
              selectedValue: _cliente,
              optionsBuilder: (q) =>
                  ref.read(clientesRemoteDataSourceProvider).listar(busca: q.isEmpty ? null : q),
              displayString: (c) => c.nome,
              isRequired: true,
              onChanged: (c) => setState(() { _cliente = c; _veiculo = null; }),
            ),
          ),
          const SizedBox(width: 8),
          _AddShortcutButton(tooltip: 'Novo cliente', onTap: _abrirNovoCliente),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GamaSearchableSelect<Veiculo>(
              key: ValueKey(_cliente?.id),
              label: 'Veículo *',
              selectedValue: _veiculo,
              enabled: _cliente != null,
              hint: _cliente == null ? 'Selecione um cliente primeiro' : null,
              optionsBuilder: (q) => ref
                  .read(veiculosRemoteDataSourceProvider)
                  .listar(clienteId: _cliente?.id, busca: q.isEmpty ? null : q),
              displayString: (v) => v.placa != null ? '${v.modeloNome} · ${v.placa}' : v.modeloNome,
              isRequired: true,
              onChanged: (v) => setState(() => _veiculo = v),
            ),
          ),
          const SizedBox(width: 8),
          _AddShortcutButton(
            tooltip: 'Novo veículo',
            onTap: _cliente != null ? _abrirNovoVeiculo : null,
          ),
        ],
      ),
    ]);
  }

  Widget _step1Content() {
    return Column(children: [
      for (int i = 0; i < _servicos.length; i++)
        _MobileServicoTile(
          key: ValueKey('s-$i'),
          item: _servicos[i],
          onRemove: () => setState(() => _servicos.removeAt(i)),
          onChanged: () => setState(() {}),
        ),
      const SizedBox(height: 4),
      _AddItemButton(
        label: '+ Adicionar serviço',
        onTap: () => setState(() =>
            _servicos.add(_ItemInput(tipo: 'Servico', descricao: '', quantidade: 1, valorUnitario: 0))),
      ),
    ]);
  }

  Widget _step2Content() {
    final temEstoque = _pecas.any((p) => p.origemPeca == 'Estoque');
    return Column(children: [
      GamaSearchableSelect<ProdutoListagem>(
        key: ValueKey(_pecaSearchKey),
        label: 'Buscar peça no estoque…',
        selectedValue: null,
        displayString: (p) => '${p.nome} (${p.codigo})',
        optionsBuilder: (q) async {
          final todos = await ref.read(estoqueDataSourceProvider).listarProdutos(busca: q);
          final addedIds = _pecas.where((p) => p.produtoId != null).map((p) => p.produtoId!).toSet();
          return todos.where((p) => !addedIds.contains(p.id)).toList();
        },
        onChanged: (p) {
          if (p == null) return;
          setState(() {
            _pecas.add(_ItemInput(
              tipo: 'Peca', descricao: p.nome, quantidade: 1,
              valorUnitario: p.precoVenda, origemPeca: 'Estoque',
              produtoId: p.id, produtoCodigo: p.codigo, produtoEstoque: p.quantidadeAtual,
            ));
            _pecaSearchKey++;
          });
        },
      ),
      const SizedBox(height: 8),
      for (int i = 0; i < _pecas.length; i++)
        _MobilePecaTile(
          key: ValueKey('p-$i'),
          item: _pecas[i],
          onRemove: () => setState(() => _pecas.removeAt(i)),
          onChanged: () => setState(() {}),
        ),
      const SizedBox(height: 4),
      _AddItemButton(
        label: '+ Adicionar peça manual',
        onTap: () => setState(() => _pecas.add(
            _ItemInput(tipo: 'Peca', descricao: '', quantidade: 1, valorUnitario: 0, origemPeca: 'Comprado'))),
      ),
      if (temEstoque) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Peças do estoque serão baixadas ao criar a OS.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _step3Content() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GamaSearchableSelect<Funcionario>(
        label: 'Mecânico responsável (opcional)',
        selectedValue: _mecanico,
        optionsBuilder: (q) =>
            ref.read(funcionariosRemoteDataSourceProvider).listar(busca: q.isEmpty ? null : q),
        displayString: (f) => '${f.nome} · ${f.cargo}',
        onChanged: (f) => setState(() => _mecanico = f),
      ),
      const SizedBox(height: 14),
      Text('Prazo de entrega',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.ink2),
            const SizedBox(width: 10),
            Text(
              _previsaoEntrega != null
                  ? '${_previsaoEntrega!.day.toString().padLeft(2, '0')}/${_previsaoEntrega!.month.toString().padLeft(2, '0')}/${_previsaoEntrega!.year}'
                  : 'Selecionar data (opcional)',
              style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 14,
                  color: _previsaoEntrega != null ? AppColors.ink : AppColors.ink3),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Text('Observações',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _obsCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Notas internas ou relato do cliente…',
          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true, fillColor: AppColors.surface,
        ),
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
      ),
      const SizedBox(height: 14),
      _ResumoFinanceiro(
        totalServicos: _totalServicos(),
        totalPecas: _totalPecas(),
        totalGeral: _totalGeral(),
        nServicos: _servicos.length,
        nPecas: _pecas.length,
      ),
    ]);
  }

  // ── Desktop layout ──────────────────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 40),
            child: Column(children: [
              _deskCard(1, Icons.person_outline, 'Cliente e veículo',
                  'Procure o cliente ou cadastre um novo', _step0Fields()),
              const SizedBox(height: 12),
              _deskCard(2, Icons.build_outlined, 'Serviços',
                  'Adicione um ou mais serviços', _deskServicosContent()),
              const SizedBox(height: 12),
              _deskCard(3, Icons.inventory_2_outlined, 'Peças',
                  'Busque do estoque ou marque como compra externa', _deskPecasContent()),
              const SizedBox(height: 12),
              _deskCard(4, Icons.engineering_outlined, 'Atribuição e prazo',
                  'Mecânico responsável e previsão de entrega', _deskAtribuicaoContent()),
              const SizedBox(height: 12),
              _deskCard(5, Icons.notes_outlined, 'Observações',
                  'Opcional — notas internas e do cliente', _deskObsContent()),
            ]),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: _DeskSidebar(
              totalServicos: _totalServicos(),
              totalPecas: _totalPecas(),
              totalGeral: _totalGeral(),
              nServicos: _servicos.length,
              nPecas: _pecas.length,
              temEstoque: _pecas.any((p) => p.origemPeca == 'Estoque'),
              loading: _loading,
              onCriar: _salvar,
              onCancelar: () => context.go('/ordens-servico'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deskCard(int num, IconData icon, String title, String subtitle, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$num',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(subtitle,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink3)),
              ]),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.line),
        Padding(padding: const EdgeInsets.all(18), child: child),
      ]),
    );
  }

  Widget _deskServicosContent() {
    return Column(children: [
      for (int i = 0; i < _servicos.length; i++) ...[
        _DeskServicoRow(
          key: ValueKey('ds-$i'),
          item: _servicos[i],
          onRemove: () => setState(() => _servicos.removeAt(i)),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
      ],
      _AddItemButton(
        label: '+ Adicionar serviço',
        onTap: () => setState(() =>
            _servicos.add(_ItemInput(tipo: 'Servico', descricao: '', quantidade: 1, valorUnitario: 0))),
      ),
    ]);
  }

  Widget _deskPecasContent() {
    final temEstoque = _pecas.any((p) => p.origemPeca == 'Estoque');
    return Column(children: [
      for (int i = 0; i < _pecas.length; i++) ...[
        _DeskPecaRow(
          key: ValueKey('dp-$i'),
          item: _pecas[i],
          onRemove: () => setState(() => _pecas.removeAt(i)),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
      ],
      GamaSearchableSelect<ProdutoListagem>(
        key: ValueKey(_pecaSearchKey),
        label: 'Buscar peça no estoque…',
        selectedValue: null,
        displayString: (p) => '${p.nome} (${p.codigo})',
        optionsBuilder: (q) async {
          final todos = await ref.read(estoqueDataSourceProvider).listarProdutos(busca: q);
          final addedIds = _pecas.where((p) => p.produtoId != null).map((p) => p.produtoId!).toSet();
          return todos.where((p) => !addedIds.contains(p.id)).toList();
        },
        onChanged: (p) {
          if (p == null) return;
          setState(() {
            _pecas.add(_ItemInput(
              tipo: 'Peca', descricao: p.nome, quantidade: 1,
              valorUnitario: p.precoVenda, origemPeca: 'Estoque',
              produtoId: p.id, produtoCodigo: p.codigo, produtoEstoque: p.quantidadeAtual,
            ));
            _pecaSearchKey++;
          });
        },
      ),
      const SizedBox(height: 8),
      _AddItemButton(
        label: '+ Adicionar peça manual',
        onTap: () => setState(() => _pecas.add(
            _ItemInput(tipo: 'Peca', descricao: '', quantidade: 1, valorUnitario: 0, origemPeca: 'Comprado'))),
      ),
      if (temEstoque) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ao criar a OS, as peças listadas serão baixadas do estoque automaticamente.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent)),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _deskAtribuicaoContent() {
    final dateStr = _previsaoEntrega != null
        ? '${_previsaoEntrega!.day.toString().padLeft(2, '0')}/${_previsaoEntrega!.month.toString().padLeft(2, '0')}/${_previsaoEntrega!.year}'
        : null;
    return Column(children: [
      Row(children: [
        Expanded(
          child: GamaSearchableSelect<Funcionario>(
            label: 'Mecânico responsável (opcional)',
            selectedValue: _mecanico,
            optionsBuilder: (q) =>
                ref.read(funcionariosRemoteDataSourceProvider).listar(busca: q.isEmpty ? null : q),
            displayString: (f) => '${f.nome} · ${f.cargo}',
            onChanged: (f) => setState(() => _mecanico = f),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.ink2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateStr ?? 'Prazo de entrega (opcional)',
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14, color: dateStr != null ? AppColors.ink : AppColors.ink2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      GamaSearchableSelect<String>(
        label: 'Forma de pagamento',
        selectedValue: _formaPagamento,
        optionsBuilder: (q) async => _formasPagamento
            .where((f) => (_formasPagamentoLabels[f] ?? f).toLowerCase().contains(q.toLowerCase()))
            .toList(),
        displayString: (f) => _formasPagamentoLabels[f] ?? f,
        onChanged: (f) => setState(() => _formaPagamento = f),
      ),
    ]);
  }

  Widget _deskObsContent() {
    return TextFormField(
      controller: _obsCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Notas internas ou relato do cliente…',
        hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true, fillColor: AppColors.surface,
      ),
      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
    );
  }
}

// ── Step bar ───────────────────────────────────────────────────────────────────
class _StepBar extends StatelessWidget {
  const _StepBar({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < _stepLabels.length; i++) ...[
            _StepDot(index: i, currentStep: currentStep),
            if (i < _stepLabels.length - 1)
              Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i < currentStep ? AppColors.ok : AppColors.line,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.currentStep});
  final int index, currentStep;

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isActive = index == currentStep;
    final bgColor = isDone ? AppColors.ok : isActive ? AppColors.accent : AppColors.line;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text('${index + 1}',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.ink3,
                  )),
        ),
        const SizedBox(height: 3),
        Text(
          _stepLabels[index],
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accent : isDone ? AppColors.ink2 : AppColors.ink3,
          ),
        ),
      ],
    );
  }
}

// ── Mobile bottom bar ──────────────────────────────────────────────────────────
class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({
    required this.totalGeral, required this.nServicos, required this.nPecas,
    required this.step, required this.loading,
    this.onNext, this.onCriar,
  });
  final double totalGeral;
  final int nServicos, nPecas, step;
  final bool loading;
  final VoidCallback? onNext, onCriar;

  static const _nextLabels = ['Serviços', 'Peças', 'Resumo', ''];

  @override
  Widget build(BuildContext context) {
    final isLast = step == 3;
    final parts = <String>[];
    if (nServicos > 0) parts.add('$nServicos ${nServicos == 1 ? 'serviço' : 'serviços'}');
    if (nPecas > 0) parts.add('$nPecas ${nPecas == 1 ? 'peça' : 'peças'}');
    final countStr = parts.isEmpty ? 'Nenhum item adicionado' : parts.join(' · ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTAL PARCIAL',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.ink3, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmtMoney(totalGeral),
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.ink, letterSpacing: -0.5)),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(countStr,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: loading ? null : (isLast ? onCriar : onNext),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          isLast ? 'Criar OS →' : 'Próximo · ${_nextLabels[step]} →',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ── Rascunho chip ──────────────────────────────────────────────────────────────
class _RascunhoChip extends StatelessWidget {
  const _RascunhoChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Text('RASCUNHO',
          style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.ink2, letterSpacing: 0.6)),
    );
  }
}

// ── Add item button ────────────────────────────────────────────────────────────
class _AddItemButton extends StatelessWidget {
  const _AddItemButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
      ),
    );
  }
}

// ── Add shortcut button (+ novo cliente / veículo) ────────────────────────────
class _AddShortcutButton extends StatelessWidget {
  const _AddShortcutButton({required this.tooltip, this.onTap});
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: enabled ? AppColors.accentSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: enabled ? AppColors.accent : AppColors.line),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.add, size: 20, color: enabled ? AppColors.accent : AppColors.ink3),
        ),
      ),
    );
  }
}

// ── Small plate badge ──────────────────────────────────────────────────────────
class _SmallPlate extends StatelessWidget {
  const _SmallPlate({required this.placa});
  final String placa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(placa,
          style: TextStyle(fontFamily: 'JetBrains Mono', 
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink)),
    );
  }
}

// ── Mobile service tile ────────────────────────────────────────────────────────
class _MobileServicoTile extends StatefulWidget {
  const _MobileServicoTile({super.key, required this.item, required this.onRemove, required this.onChanged});
  final _ItemInput item;
  final VoidCallback onRemove, onChanged;

  @override
  State<_MobileServicoTile> createState() => _MobileServicoTileState();
}

class _MobileServicoTileState extends State<_MobileServicoTile> {
  late final TextEditingController _desc, _valor;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.item.descricao);
    _valor = TextEditingController(
        text: widget.item.valorUnitario == 0 ? '' : widget.item.valorUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() { _desc.dispose(); _valor.dispose(); super.dispose(); }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: 'Inter', color: AppColors.ink2, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: AppColors.surface,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.build_circle_outlined, size: 15, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text('Serviço',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
            const Spacer(),
            GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(Icons.close, size: 18, color: AppColors.ink3),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _desc,
                decoration: _dec('Descrição'),
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                onChanged: (v) { widget.item.descricao = v; widget.onChanged(); },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('R\$'),
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                onChanged: (v) {
                  widget.item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  widget.onChanged();
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Mobile peça tile ───────────────────────────────────────────────────────────
class _MobilePecaTile extends StatefulWidget {
  const _MobilePecaTile({super.key, required this.item, required this.onRemove, required this.onChanged});
  final _ItemInput item;
  final VoidCallback onRemove, onChanged;

  @override
  State<_MobilePecaTile> createState() => _MobilePecaTileState();
}

class _MobilePecaTileState extends State<_MobilePecaTile> {
  late final TextEditingController _desc, _qtd, _valor;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.item.descricao);
    _qtd = TextEditingController(text: widget.item.quantidade.toInt().toString());
    _valor = TextEditingController(
        text: widget.item.valorUnitario == 0 ? '' : widget.item.valorUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() { _desc.dispose(); _qtd.dispose(); _valor.dispose(); super.dispose(); }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontFamily: 'Inter', color: AppColors.ink2, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: AppColors.surface,
  );

  void _incQty(int delta) {
    final v = (double.tryParse(_qtd.text) ?? 1) + delta;
    if (v < 1) return;
    _qtd.text = v.toInt().toString();
    widget.item.quantidade = v;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isEstoque = widget.item.origemPeca == 'Estoque';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text('Peça',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2)),
            if (isEstoque) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(4)),
                child: Text('Estoque',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            ),
          ]),
          const SizedBox(height: 8),
          if (isEstoque) ...[
            Text(widget.item.descricao,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 3),
            Row(children: [
              if (widget.item.produtoCodigo != null)
                Text(widget.item.produtoCodigo!,
                    style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.ink2)),
              if (widget.item.produtoEstoque != null) ...[
                const SizedBox(width: 4),
                Text('· estoque ${widget.item.produtoEstoque!.toInt()}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3)),
              ],
              const Spacer(),
              Text(_fmtMoney(widget.item.valorUnitario * widget.item.quantidade),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('Qtd:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
              const SizedBox(width: 8),
              _QtyControl(controller: _qtd, onInc: () => _incQty(1), onDec: () => _incQty(-1)),
            ]),
          ] else ...[
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _desc,
                  decoration: _dec('Descrição'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                  onChanged: (v) { widget.item.descricao = v; widget.onChanged(); },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _qtd,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Qtd'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                  onChanged: (v) { widget.item.quantidade = double.tryParse(v) ?? 1; widget.onChanged(); },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _valor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('R\$'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                  onChanged: (v) {
                    widget.item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('Origem:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
              const SizedBox(width: 8),
              _OrigemToggle(
                value: widget.item.origemPeca ?? 'Comprado',
                onChanged: (v) => setState(() { widget.item.origemPeca = v; widget.onChanged(); }),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Qty stepper control ────────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.controller, required this.onInc, required this.onDec});
  final TextEditingController controller;
  final VoidCallback onInc, onDec;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _QtyBtn(icon: Icons.remove, onTap: onDec),
      SizedBox(
        width: 38,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      ),
      _QtyBtn(icon: Icons.add, onTap: onInc),
    ]);
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(6),
            color: AppColors.surface),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AppColors.ink2),
      ),
    );
  }
}

// ── Resumo financeiro ──────────────────────────────────────────────────────────
class _ResumoFinanceiro extends StatelessWidget {
  const _ResumoFinanceiro({
    required this.totalServicos, required this.totalPecas,
    required this.totalGeral, required this.nServicos, required this.nPecas,
  });
  final double totalServicos, totalPecas, totalGeral;
  final int nServicos, nPecas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        _FinRow('$nServicos ${nServicos == 1 ? 'serviço' : 'serviços'}', totalServicos),
        const SizedBox(height: 6),
        _FinRow('$nPecas ${nPecas == 1 ? 'peça' : 'peças'}', totalPecas),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: AppColors.line),
        ),
        Row(children: [
          Text('Total',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Spacer(),
          Text(_fmtMoney(totalGeral),
              style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ]),
      ]),
    );
  }
}

class _FinRow extends StatelessWidget {
  const _FinRow(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink2)),
      const Spacer(),
      Text(_fmtMoney(value), style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink)),
    ]);
  }
}

// ── Desktop service row ────────────────────────────────────────────────────────
class _DeskServicoRow extends StatefulWidget {
  const _DeskServicoRow({super.key, required this.item, required this.onRemove, required this.onChanged});
  final _ItemInput item;
  final VoidCallback onRemove, onChanged;

  @override
  State<_DeskServicoRow> createState() => _DeskServicoRowState();
}

class _DeskServicoRowState extends State<_DeskServicoRow> {
  late final TextEditingController _desc, _qtd, _valor;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.item.descricao);
    _qtd = TextEditingController(text: widget.item.quantidade.toInt().toString());
    _valor = TextEditingController(
        text: widget.item.valorUnitario == 0 ? '' : widget.item.valorUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() { _desc.dispose(); _qtd.dispose(); _valor.dispose(); super.dispose(); }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: 'Inter', color: AppColors.ink3, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: AppColors.surface,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.ink3),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _desc,
            decoration: _dec('Descrição do serviço'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) { widget.item.descricao = v; widget.onChanged(); },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: TextField(
            controller: _qtd,
            keyboardType: TextInputType.number,
            decoration: _dec('Qtd'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) { widget.item.quantidade = double.tryParse(v) ?? 1; widget.onChanged(); },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec('R\$'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) {
              widget.item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0;
              widget.onChanged();
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            _fmtMoney(widget.item.quantidade * widget.item.valorUnitario),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.close, size: 16),
          color: AppColors.ink3,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ]),
    );
  }
}

// ── Desktop peça row ───────────────────────────────────────────────────────────
class _DeskPecaRow extends StatefulWidget {
  const _DeskPecaRow({super.key, required this.item, required this.onRemove, required this.onChanged});
  final _ItemInput item;
  final VoidCallback onRemove, onChanged;

  @override
  State<_DeskPecaRow> createState() => _DeskPecaRowState();
}

class _DeskPecaRowState extends State<_DeskPecaRow> {
  late final TextEditingController _desc, _qtd, _valor;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.item.descricao);
    _qtd = TextEditingController(text: widget.item.quantidade.toInt().toString());
    _valor = TextEditingController(
        text: widget.item.valorUnitario == 0 ? '' : widget.item.valorUnitario.toStringAsFixed(2));
  }

  @override
  void dispose() { _desc.dispose(); _qtd.dispose(); _valor.dispose(); super.dispose(); }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: 'Inter', color: AppColors.ink3, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: AppColors.surface,
  );

  void _incQty(int delta) {
    final v = (double.tryParse(_qtd.text) ?? 1) + delta;
    if (v < 1) return;
    _qtd.text = v.toInt().toString();
    widget.item.quantidade = v;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isEstoque = widget.item.origemPeca == 'Estoque';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: isEstoque ? _buildEstoqueLayout() : _buildManualLayout(),
    );
  }

  Widget _buildEstoqueLayout() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(4)),
        child: Text('Estoque',
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.item.descricao,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (widget.item.produtoCodigo != null)
            Row(children: [
              Text(widget.item.produtoCodigo!,
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.ink2)),
              if (widget.item.produtoEstoque != null)
                Text(' · estoque: ${widget.item.produtoEstoque!.toInt()} un',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3)),
            ]),
        ]),
      ),
      const SizedBox(width: 12),
      _QtyControl(controller: _qtd, onInc: () => _incQty(1), onDec: () => _incQty(-1)),
      const SizedBox(width: 16),
      SizedBox(
        width: 90,
        child: Text(
          _fmtMoney(widget.item.valorUnitario * widget.item.quantidade),
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
          textAlign: TextAlign.right,
        ),
      ),
      const SizedBox(width: 4),
      IconButton(
        onPressed: widget.onRemove,
        icon: const Icon(Icons.delete_outline, size: 16),
        color: AppColors.danger,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    ]);
  }

  Widget _buildManualLayout() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _desc,
            decoration: _dec('Descrição da peça'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) { widget.item.descricao = v; widget.onChanged(); },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: TextField(
            controller: _qtd,
            keyboardType: TextInputType.number,
            decoration: _dec('Qtd'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) { widget.item.quantidade = double.tryParse(v) ?? 1; widget.onChanged(); },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec('R\$'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
            onChanged: (v) {
              widget.item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0;
              widget.onChanged();
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.delete_outline, size: 16),
          color: AppColors.danger,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('Origem:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2)),
        const SizedBox(width: 8),
        _OrigemToggle(
          value: widget.item.origemPeca ?? 'Comprado',
          onChanged: (v) => setState(() { widget.item.origemPeca = v; widget.onChanged(); }),
        ),
      ]),
    ]);
  }
}

// ── Desktop sidebar ────────────────────────────────────────────────────────────
class _DeskSidebar extends StatelessWidget {
  const _DeskSidebar({
    required this.totalServicos, required this.totalPecas, required this.totalGeral,
    required this.nServicos, required this.nPecas,
    required this.temEstoque, required this.loading,
    required this.onCriar, required this.onCancelar,
  });
  final double totalServicos, totalPecas, totalGeral;
  final int nServicos, nPecas;
  final bool temEstoque, loading;
  final VoidCallback? onCriar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.ink2),
            const SizedBox(width: 8),
            Text('Resumo da OS',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ]),
          const SizedBox(height: 16),
          _FinRow('$nServicos ${nServicos == 1 ? 'serviço' : 'serviços'}', totalServicos),
          const SizedBox(height: 6),
          _FinRow('$nPecas ${nPecas == 1 ? 'peça' : 'peças'}', totalPecas),
          const SizedBox(height: 6),
          _FinRow('Desconto', 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.line),
          ),
          Row(children: [
            Text('Total',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const Spacer(),
            Text(_fmtMoney(totalGeral),
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.ink, letterSpacing: -0.5)),
          ]),
        ]),
      ),
      if (temEstoque) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Ao criar a OS, as peças listadas serão baixadas do estoque automaticamente.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.accent)),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      FilledButton(
        onPressed: loading ? null : onCriar,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Criar OS',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      TextButton(
        onPressed: null,
        style: TextButton.styleFrom(foregroundColor: AppColors.ink2),
        child: Text('Salvar como rascunho',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      TextButton(
        onPressed: onCancelar,
        style: TextButton.styleFrom(foregroundColor: AppColors.ink3),
        child: Text('Cancelar', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
      ),
    ]);
  }
}

// ── Origem toggle (manual peça) ────────────────────────────────────────────────
class _OrigemToggle extends StatelessWidget {
  const _OrigemToggle({required this.value, required this.onChanged});
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _ToggleBtn('Ir comprar', 'Comprado', value, onChanged),
      const SizedBox(width: 6),
      _ToggleBtn('Cliente trouxe', 'ClienteTrouxe', value, onChanged),
    ]);
  }
}


class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn(this.label, this.v, this.current, this.onChanged);
  final String label, v, current;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final active = v == current;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.accent : AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Inter', 
                fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.ink2)),
      ),
    );
  }
}
