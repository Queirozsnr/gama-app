import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/gama_button.dart';
import '../../../../../shared/widgets/gama_searchable_select.dart';
import '../../../../../shared/widgets/gama_snack_bar.dart';
import '../../../clientes/data/clientes_remote_data_source.dart';
import '../../../clientes/domain/cliente.dart';
import '../../../veiculos/data/veiculos_remote_data_source.dart';
import '../../../veiculos/domain/veiculo.dart';
import '../../data/ordens_servico_remote_data_source.dart';
import '../../../estoque/data/estoque_remote_data_source.dart';
import '../../../estoque/domain/estoque.dart';

// Payloads locais para itens novos (antes de salvar)
class _ItemInput {
  _ItemInput({
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    this.origemPeca,
    this.produtoId,
  });
  String tipo;
  String descricao;
  double quantidade;
  double valorUnitario;
  String? origemPeca;
  int? produtoId;
}

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

class OsFormDialog extends ConsumerStatefulWidget {
  const OsFormDialog({super.key, this.clienteIdFixo, this.veiculoIdFixo});

  final int? clienteIdFixo;
  final int? veiculoIdFixo;

  @override
  ConsumerState<OsFormDialog> createState() => _OsFormDialogState();
}

class _OsFormDialogState extends ConsumerState<OsFormDialog> {
  final _obsCtrl = TextEditingController();
  Cliente? _cliente;
  Veiculo? _veiculo;
  String? _formaPagamento;
  DateTime? _previsaoEntrega;
  final List<_ItemInput> _itens = [];
  bool _loading = false;

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<List<Cliente>> _buscarClientes(String q) async {
    final ds = ref.read(clientesRemoteDataSourceProvider);
    return ds.listar(busca: q.isEmpty ? null : q);
  }

  Future<List<Veiculo>> _buscarVeiculos(String q) async {
    final ds = ref.read(veiculosRemoteDataSourceProvider);
    return ds.listar(clienteId: _cliente?.id, busca: q.isEmpty ? null : q);
  }

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

  void _addItem() {
    setState(() => _itens.add(_ItemInput(
          tipo: 'Servico',
          descricao: '',
          quantidade: 1,
          valorUnitario: 0,
        )));
  }

  void _removeItem(int i) => setState(() => _itens.removeAt(i));

  Future<void> _salvar() async {
    if (_cliente == null) { GamaSnackBar.error(context, 'Selecione um cliente.'); return; }
    if (_veiculo == null) { GamaSnackBar.error(context, 'Selecione um veículo.'); return; }
    for (final item in _itens) {
      if (item.descricao.trim().isEmpty) { GamaSnackBar.error(context, 'Preencha a descrição dos itens.'); return; }
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
        'itens': _itens.map((i) => <String, dynamic>{
          'tipo': i.tipo,
          'descricao': i.descricao,
          'quantidade': i.quantidade,
          'valorUnitario': i.valorUnitario,
          if (i.tipo == 'Peca' && i.origemPeca != null) 'origemPeca': i.origemPeca,
          if (i.produtoId != null) 'produtoId': i.produtoId,
        }).toList(),
      });
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao criar OS.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Nova OS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
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
                        onChanged: (c) => setState(() {
                          _cliente = c;
                          _veiculo = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      // Veículo (depende do cliente)
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
                      // Previsão + Forma de pagamento
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
                      const SizedBox(height: 16),
                      // Itens
                      Row(
                        children: [
                          const Text('Itens', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Adicionar'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                          ),
                        ],
                      ),
                      if (_itens.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Nenhum item — pode adicionar depois.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      for (int i = 0; i < _itens.length; i++)
                        _ItemInputTile(
                          key: ValueKey(i),
                          item: _itens[i],
                          onRemove: () => _removeItem(i),
                          onChanged: () => setState(() {}),
                          origensLabels: _origensLabels,
                          origens: _origens,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GamaButton(label: 'Criar OS', onPressed: _salvar, isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemInputTile extends ConsumerStatefulWidget {
  const _ItemInputTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onChanged,
    required this.origensLabels,
    required this.origens,
  });
  final _ItemInput item;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Map<String, String> origensLabels;
  final List<String> origens;

  @override
  ConsumerState<_ItemInputTile> createState() => _ItemInputTileState();
}

class _ItemInputTileState extends ConsumerState<_ItemInputTile> {
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
              _TypeToggle(
                value: item.tipo,
                onChanged: (t) { setState(() => item.tipo = t); widget.onChanged(); },
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
          if (item.origemPeca == 'Estoque')
            GamaSearchableSelect<ProdutoListagem>(
              label: 'Produto do estoque *',
              selectedValue: null,
              displayString: (p) => p.nome,
              optionsBuilder: (query) =>
                  ref.read(estoqueDataSourceProvider).listarProdutos(busca: query),
              onChanged: (p) {
                setState(() {
                  item.produtoId = p?.id;
                  item.descricao = p?.nome ?? item.descricao;
                  if (p != null) {
                    _desc.text = p.nome;
                    if (_valor.text.isEmpty) _valor.text = p.precoVenda.toStringAsFixed(2);
                    item.valorUnitario = p.precoVenda;
                  }
                });
                widget.onChanged();
              },
            )
          else
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
          if (item.tipo == 'Peca') ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: item.origemPeca,
              decoration: _dec('Origem da peça'),
              items: widget.origens.map((o) => DropdownMenuItem(value: o, child: Text(widget.origensLabels[o] ?? o))).toList(),
              onChanged: (v) { setState(() { item.origemPeca = v; item.produtoId = null; _desc.clear(); _valor.clear(); }); widget.onChanged(); },
            ),
          ],
        ],
      ),
    );
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
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn('Serviço', 'Servico', value, onChanged),
        const SizedBox(width: 6),
        _Btn('Peça', 'Peca', value, onChanged),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.v, this.current, this.onChanged);
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
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
