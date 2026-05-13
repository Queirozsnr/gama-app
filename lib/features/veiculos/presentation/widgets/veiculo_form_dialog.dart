import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_button.dart';
import '../../../../shared/widgets/gama_searchable_select.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../data/marcas_remote_data_source.dart';
import '../../data/modelos_remote_data_source.dart';
import '../../domain/marca.dart';
import '../../domain/modelo.dart';
import '../../domain/veiculo.dart';
import '../veiculos_notifier.dart';

const _combustiveis = ['Gasolina', 'Etanol', 'Flex', 'Diesel', 'Eletrico', 'Hibrido', 'GNV'];
const _combustiveisLabels = {
  'Gasolina': 'Gasolina',
  'Etanol': 'Etanol',
  'Flex': 'Flex',
  'Diesel': 'Diesel',
  'Eletrico': 'Elétrico',
  'Hibrido': 'Híbrido',
  'GNV': 'GNV',
};

const _coresPredefinidas = [
  ('Branco',   Color(0xFFF0F0F0)),
  ('Prata',    Color(0xFF9E9E9E)),
  ('Preto',    Color(0xFF1C1C1C)),
  ('Vermelho', Color(0xFFC62828)),
  ('Azul',     Color(0xFF1565C0)),
  ('Verde',    Color(0xFF2E7D32)),
  ('Amarelo',  Color(0xFFF9A825)),
  ('Cinza',    Color(0xFF757575)),
  ('Marrom',   Color(0xFF5D4037)),
  ('Laranja',  Color(0xFFE65100)),
];

class VeiculoFormDialog extends ConsumerStatefulWidget {
  const VeiculoFormDialog({super.key, this.veiculo, this.clienteIdFixo});

  final Veiculo? veiculo;
  final int? clienteIdFixo;

  @override
  ConsumerState<VeiculoFormDialog> createState() => _VeiculoFormDialogState();
}

class _VeiculoFormDialogState extends ConsumerState<VeiculoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placa;
  late final TextEditingController _ano;
  late final TextEditingController _corCustom;
  late final TextEditingController _km;
  late final TextEditingController _obs;

  Marca? _marcaSelecionada;
  Modelo? _modeloSelecionado;
  String? _corSelecionada;
  String? _combustivel;
  bool _loading = false;

  bool get _editando => widget.veiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.veiculo;
    _placa     = TextEditingController(text: v?.placa ?? '');
    _ano       = TextEditingController(text: v?.ano?.toString() ?? '');
    _corCustom = TextEditingController();
    _km        = TextEditingController(text: v?.quilometragem?.toString() ?? '');
    _obs       = TextEditingController(text: v?.observacoes ?? '');
    _combustivel = v?.combustivel;
    if (v != null) {
      _corSelecionada = v.cor;
      _marcaSelecionada = Marca(id: v.marcaId, nome: v.marcaNome);
      _modeloSelecionado = Modelo(id: v.modeloId, nome: v.modeloNome, marcaId: v.marcaId, marcaNome: v.marcaNome);
    }
  }

  @override
  void dispose() {
    _placa.dispose(); _ano.dispose(); _corCustom.dispose();
    _km.dispose(); _obs.dispose();
    super.dispose();
  }

  Future<List<Marca>> _buscarMarcas(String q) =>
      ref.read(marcasRemoteDataSourceProvider).listar(busca: q);

  Future<List<Modelo>> _buscarModelos(String q) =>
      ref.read(modelosRemoteDataSourceProvider).listar(marcaId: _marcaSelecionada?.id, busca: q);

  Future<List<String>> _filtrarCombustivel(String q) async =>
      _combustiveis.where((c) => (_combustiveisLabels[c] ?? c).toLowerCase().contains(q.toLowerCase())).toList();

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modeloSelecionado == null) {
      GamaSnackBar.error(context, 'Selecione um modelo.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cor = (_corSelecionada?.isNotEmpty == true)
          ? _corSelecionada
          : (_corCustom.text.trim().isNotEmpty ? _corCustom.text.trim() : null);

      final clienteId = widget.clienteIdFixo ?? widget.veiculo?.clienteId;
      final data = {
        'clienteId': ?clienteId,
        'modeloId': _modeloSelecionado!.id,
        if (_placa.text.trim().isNotEmpty) 'placa': _placa.text.trim().toUpperCase(),
        if (_ano.text.trim().isNotEmpty) 'ano': int.tryParse(_ano.text.trim()),
        'cor': ?cor,
        if (_combustivel != null) 'combustivel': _combustivel,
        if (_km.text.trim().isNotEmpty) 'quilometragem': int.tryParse(_km.text.trim()),
        if (_obs.text.trim().isNotEmpty) 'observacoes': _obs.text.trim(),
      };

      final notifier = ref.read(veiculosNotifierProvider.notifier);
      if (_editando) {
        await notifier.atualizar(widget.veiculo!.id, data);
      } else {
        await notifier.criar(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao salvar veículo.');
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _editando ? 'Editar veículo' : 'Novo veículo',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
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
                        // Marca
                        GamaSearchableSelect<Marca>(
                          label: 'Marca *',
                          selectedValue: _marcaSelecionada,
                          optionsBuilder: _buscarMarcas,
                          displayString: (m) => m.nome,
                          isRequired: true,
                          onChanged: (m) => setState(() {
                            _marcaSelecionada = m;
                            _modeloSelecionado = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        // Modelo (depende da marca — key garante reset ao trocar marca)
                        GamaSearchableSelect<Modelo>(
                          key: ValueKey(_marcaSelecionada?.id),
                          label: 'Modelo *',
                          selectedValue: _modeloSelecionado,
                          enabled: _marcaSelecionada != null,
                          hint: _marcaSelecionada == null ? 'Selecione uma marca primeiro' : null,
                          optionsBuilder: _buscarModelos,
                          displayString: (m) => m.nome,
                          isRequired: true,
                          onChanged: (m) => setState(() => _modeloSelecionado = m),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _campo(_placa, 'Placa')),
                            const SizedBox(width: 12),
                            Expanded(child: _campo(_ano, 'Ano', teclado: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Cor
                        const Text('Cor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _coresPredefinidas.map((entry) {
                            final (nome, color) = entry;
                            final selected = _corSelecionada == nome;
                            final isLight = color.computeLuminance() > 0.5;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _corSelecionada = selected ? null : nome;
                                if (!selected) _corCustom.clear();
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? AppColors.primary : Colors.black12,
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)] : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      Icon(Icons.check, size: 12, color: isLight ? Colors.black87 : Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(nome, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isLight ? Colors.black87 : Colors.white)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_corSelecionada == null) ...[
                          const SizedBox(height: 8),
                          _campo(_corCustom, 'Ou digite a cor (ex: Vinho, Bege...)'),
                        ],
                        const SizedBox(height: 12),
                        // Combustível — select com busca
                        GamaSearchableSelect<String>(
                          label: 'Combustível',
                          selectedValue: _combustivel,
                          optionsBuilder: _filtrarCombustivel,
                          displayString: (c) => _combustiveisLabels[c] ?? c,
                          onChanged: (c) => setState(() => _combustivel = c),
                        ),
                        const SizedBox(height: 12),
                        _campo(_km, 'Quilometragem', teclado: TextInputType.number),
                        const SizedBox(height: 12),
                        _campo(_obs, 'Observações', maxLines: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GamaButton(
                  label: _editando ? 'Salvar alterações' : 'Cadastrar veículo',
                  onPressed: _salvar,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, {
    TextInputType teclado = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
