import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_button.dart';
import '../../../../shared/widgets/gama_searchable_select.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../clientes/data/clientes_remote_data_source.dart';
import '../../clientes/domain/cliente.dart';
import '../../veiculos/data/veiculos_remote_data_source.dart';
import '../../veiculos/domain/veiculo.dart';
import '../data/ordens_servico_remote_data_source.dart';
import 'ordens_servico_notifier.dart';

const _formasPagamento = ['Dinheiro', 'Pix', 'CartaoDebito', 'CartaoCredito', 'Transferencia', 'Outro'];
const _formasPagamentoLabels = {
  'Dinheiro': 'Dinheiro',
  'Pix': 'Pix',
  'CartaoDebito': 'Cartão de débito',
  'CartaoCredito': 'Cartão de crédito',
  'Transferencia': 'Transferência',
  'Outro': 'Outro',
};
const _origens = ['Estoque', 'Comprado', 'ClienteTrouxe'];
const _origensLabels = {
  'Estoque': 'Do estoque',
  'Comprado': 'Comprado',
  'ClienteTrouxe': 'Cliente trouxe',
};

class _ItemInput {
  _ItemInput({required this.tipo, required this.descricao, required this.quantidade, required this.valorUnitario, this.origemPeca});
  String tipo;
  String descricao;
  double quantidade;
  double valorUnitario;
  String? origemPeca;
}

class OsNovaScreen extends ConsumerStatefulWidget {
  const OsNovaScreen({super.key});

  @override
  ConsumerState<OsNovaScreen> createState() => _OsNovaScreenState();
}

class _OsNovaScreenState extends ConsumerState<OsNovaScreen> {
  final _obsCtrl = TextEditingController();
  Cliente? _cliente;
  Veiculo? _veiculo;
  String? _formaPagamento;
  DateTime? _previsaoEntrega;
  final List<_ItemInput> _servicos = [];
  final List<_ItemInput> _pecas = [];
  bool _loading = false;

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<List<Cliente>> _buscarClientes(String q) =>
      ref.read(clientesRemoteDataSourceProvider).listar(busca: q.isEmpty ? null : q);

  Future<List<Veiculo>> _buscarVeiculos(String q) =>
      ref.read(veiculosRemoteDataSourceProvider).listar(clienteId: _cliente?.id, busca: q.isEmpty ? null : q);

  Future<List<String>> _buscarFormas(String q) async => _formasPagamento
      .where((f) => (_formasPagamentoLabels[f] ?? f).toLowerCase().contains(q.toLowerCase()))
      .toList();

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _previsaoEntrega = d);
  }

  void _addServico() => setState(() => _servicos.add(
      _ItemInput(tipo: 'Servico', descricao: '', quantidade: 1, valorUnitario: 0)));

  void _addPeca() => setState(() => _pecas.add(
      _ItemInput(tipo: 'Peca', descricao: '', quantidade: 1, valorUnitario: 0)));

  Future<void> _salvar() async {
    if (_cliente == null) { GamaSnackBar.error(context, 'Selecione um cliente.'); return; }
    if (_veiculo == null) { GamaSnackBar.error(context, 'Selecione um veículo.'); return; }
    final todos = [..._servicos, ..._pecas];
    for (final item in todos) {
      if (item.descricao.trim().isEmpty) {
        GamaSnackBar.error(context, 'Preencha a descrição de todos os itens.');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final ds = ref.read(ordensServicoRemoteDataSourceProvider);
      final id = await ds.criar({
        'clienteId': _cliente!.id,
        'veiculoId': _veiculo!.id,
        if (_obsCtrl.text.trim().isNotEmpty) 'observacoes': _obsCtrl.text.trim(),
        if (_previsaoEntrega != null) 'previsaoEntrega': _previsaoEntrega!.toIso8601String(),
        if (_formaPagamento != null) 'formaPagamento': _formaPagamento,
        'mecanicoIds': <int>[],
        'itens': todos.map((i) => {
          'tipo': i.tipo,
          'descricao': i.descricao,
          'quantidade': i.quantidade,
          'valorUnitario': i.valorUnitario,
          if (i.tipo == 'Peca' && i.origemPeca != null) 'origemPeca': i.origemPeca,
        }).toList(),
      });
      ref.invalidate(ordensServicoNotifierProvider);
      if (mounted) {
        GamaSnackBar.success(context, 'OS #$id criada!');
        context.pushReplacement('/ordens-servico/$id');
      }
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao criar OS.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Nova OS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cliente
              GamaSearchableSelect<Cliente>(
                label: 'Cliente *',
                selectedValue: _cliente,
                optionsBuilder: _buscarClientes,
                displayString: (c) => c.nome,
                isRequired: true,
                onChanged: (c) => setState(() { _cliente = c; _veiculo = null; }),
              ),
              const SizedBox(height: 12),
              // Veículo
              GamaSearchableSelect<Veiculo>(
                key: ValueKey(_cliente?.id),
                label: 'Veículo *',
                selectedValue: _veiculo,
                enabled: _cliente != null,
                hint: _cliente == null ? 'Selecione um cliente primeiro' : null,
                optionsBuilder: _buscarVeiculos,
                displayString: (v) => v.placa != null ? '${v.modeloNome} · ${v.placa}' : v.modeloNome,
                isRequired: true,
                onChanged: (v) => setState(() => _veiculo = v),
              ),
              const SizedBox(height: 12),
              // Previsão + Pagamento
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _previsaoEntrega != null
                                  ? '${_previsaoEntrega!.day.toString().padLeft(2, '0')}/${_previsaoEntrega!.month.toString().padLeft(2, '0')}/${_previsaoEntrega!.year}'
                                  : 'Previsão entrega',
                              style: TextStyle(
                                fontSize: 14,
                                color: _previsaoEntrega != null ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GamaSearchableSelect<String>(
                      label: 'Pagamento',
                      selectedValue: _formaPagamento,
                      optionsBuilder: _buscarFormas,
                      displayString: (f) => _formasPagamentoLabels[f] ?? f,
                      onChanged: (f) => setState(() => _formaPagamento = f),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Observações
              TextFormField(
                controller: _obsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true, fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Serviços
              _ItemSection(
                label: 'Serviços',
                tipo: 'Servico',
                itens: _servicos,
                onAdd: _addServico,
                onRemove: (i) => setState(() => _servicos.removeAt(i)),
                onChanged: () => setState(() {}),
                origensLabels: _origensLabels,
                origens: _origens,
              ),
              const SizedBox(height: 20),

              // Peças
              _ItemSection(
                label: 'Peças',
                tipo: 'Peca',
                itens: _pecas,
                onAdd: _addPeca,
                onRemove: (i) => setState(() => _pecas.removeAt(i)),
                onChanged: () => setState(() {}),
                origensLabels: _origensLabels,
                origens: _origens,
              ),
              const SizedBox(height: 32),

              GamaButton(label: 'Criar OS', onPressed: _salvar, isLoading: _loading),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ── Seção de itens (serviços ou peças) ───────────────────────────────────────

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.label,
    required this.tipo,
    required this.itens,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    required this.origensLabels,
    required this.origens,
  });

  final String label;
  final String tipo;
  final List<_ItemInput> itens;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final VoidCallback onChanged;
  final Map<String, String> origensLabels;
  final List<String> origens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Nenhum ${label.toLowerCase()} adicionado.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          )
        else
          for (int i = 0; i < itens.length; i++)
            _ItemInputTile(
              key: ValueKey('$tipo-$i'),
              item: itens[i],
              isPeca: tipo == 'Peca',
              onRemove: () => onRemove(i),
              onChanged: onChanged,
              origensLabels: origensLabels,
              origens: origens,
            ),
      ],
    );
  }
}

// ── Tile de item ──────────────────────────────────────────────────────────────

class _ItemInputTile extends StatefulWidget {
  const _ItemInputTile({
    super.key,
    required this.item,
    required this.isPeca,
    required this.onRemove,
    required this.onChanged,
    required this.origensLabels,
    required this.origens,
  });
  final _ItemInput item;
  final bool isPeca;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Map<String, String> origensLabels;
  final List<String> origens;

  @override
  State<_ItemInputTile> createState() => _ItemInputTileState();
}

class _ItemInputTileState extends State<_ItemInputTile> {
  late final TextEditingController _desc;
  late final TextEditingController _qtd;
  late final TextEditingController _valor;

  @override
  void initState() {
    super.initState();
    _desc  = TextEditingController(text: widget.item.descricao);
    _qtd   = TextEditingController(text: widget.item.quantidade.toString());
    _valor = TextEditingController(text: widget.item.valorUnitario == 0 ? '' : widget.item.valorUnitario.toString());
  }

  @override
  void dispose() {
    _desc.dispose(); _qtd.dispose(); _valor.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true, fillColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isPeca ? AppColors.warningLight : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.isPeca ? 'Peça' : 'Serviço',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isPeca ? AppColors.warning : AppColors.primary),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            decoration: _dec('Descrição'),
            onChanged: (v) { item.descricao = v; widget.onChanged(); },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtd,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Qtd'),
                  onChanged: (v) { item.quantidade = double.tryParse(v) ?? 1; widget.onChanged(); },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _valor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Valor unit. (R\$)'),
                  onChanged: (v) { item.valorUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0; widget.onChanged(); },
                ),
              ),
            ],
          ),
          if (widget.isPeca) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: item.origemPeca,
              decoration: _dec('Origem da peça'),
              items: widget.origens.map((o) => DropdownMenuItem(value: o, child: Text(widget.origensLabels[o] ?? o))).toList(),
              onChanged: (v) { setState(() => item.origemPeca = v); widget.onChanged(); },
            ),
          ],
        ],
      ),
    );
  }
}
