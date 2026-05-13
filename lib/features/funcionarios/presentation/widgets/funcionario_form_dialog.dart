import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/oficinas/data/oficinas_remote_data_source.dart';
import '../../../../features/oficinas/domain/oficina_model.dart';
import '../../../../shared/widgets/gama_button.dart';
import '../../../../shared/widgets/gama_searchable_select.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../domain/funcionario.dart';
import '../funcionarios_notifier.dart';

const _cargos = [
  'Gerente', 'Mecanico', 'Auxiliar', 'Atendente',
  'Lavador', 'Funileiro', 'Eletricista', 'Pintor', 'TecnicoArCondicionado',
];

const _cargoLabels = {
  'Gerente': 'Gerente',
  'Mecanico': 'Mecânico',
  'Auxiliar': 'Auxiliar',
  'Atendente': 'Atendente',
  'Lavador': 'Lavador',
  'Funileiro': 'Funileiro',
  'Eletricista': 'Eletricista',
  'Pintor': 'Pintor',
  'TecnicoArCondicionado': 'Técnico AC',
};

const _tiposRemuneracao = ['Fixo', 'Porcentagem'];
const _tipoRemuneracaoLabels = {
  'Fixo': 'Salário fixo',
  'Porcentagem': 'Porcentagem da OS',
};

class FuncionarioFormDialog extends ConsumerStatefulWidget {
  const FuncionarioFormDialog({super.key, this.funcionario});
  final Funcionario? funcionario;

  @override
  ConsumerState<FuncionarioFormDialog> createState() => _FuncionarioFormDialogState();
}

class _FuncionarioFormDialogState extends ConsumerState<FuncionarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _valor;
  String? _cargo;
  String? _tipoRemuneracao;
  final Set<int> _oficinasSelected = {};
  List<OficinaModel> _oficinas = [];
  bool _loadingOficinas = true;
  bool _loading = false;

  bool get _editando => widget.funcionario != null;

  @override
  void initState() {
    super.initState();
    final f = widget.funcionario;
    _nome = TextEditingController(text: f?.nome ?? '');
    _email = TextEditingController(text: f?.email ?? '');
    _telefone = TextEditingController(text: f?.telefone ?? '');
    _cargo = f?.cargo ?? _cargos.first;
    _tipoRemuneracao = (_cargo == 'Gerente') ? null : (f?.tipoRemuneracao ?? 'Fixo');
    _valor = TextEditingController(
      text: f == null ? '' : (_tipoRemuneracao == 'Fixo' ? f.salario?.toString() : f.porcentagem?.toString()) ?? '',
    );
    if (f != null) _oficinasSelected.addAll(f.oficinas.map((o) => o.id));
    _carregarOficinas();
  }

  Future<void> _carregarOficinas() async {
    try {
      final lista = await ref.read(oficinasRemoteDataSourceProvider).listar();
      if (mounted) setState(() { _oficinas = lista; _loadingOficinas = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOficinas = false);
    }
  }

  @override
  void dispose() {
    _nome.dispose(); _email.dispose(); _telefone.dispose(); _valor.dispose();
    super.dispose();
  }

  Future<List<String>> _filtrarCargos(String q) async =>
      _cargos.where((c) => (_cargoLabels[c] ?? c).toLowerCase().contains(q.toLowerCase())).toList();

  Future<List<String>> _filtrarTipos(String q) async =>
      _tiposRemuneracao.where((t) => (_tipoRemuneracaoLabels[t] ?? t).toLowerCase().contains(q.toLowerCase())).toList();

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cargo == null) {
      GamaSnackBar.error(context, 'Selecione um cargo.');
      return;
    }
    final isGerente = _cargo == 'Gerente';
    if (!isGerente && _tipoRemuneracao == null) {
      GamaSnackBar.error(context, 'Selecione o tipo de remuneração.');
      return;
    }
    setState(() => _loading = true);
    try {
      final tipoFinal = isGerente ? 'Socio' : _tipoRemuneracao!;
      final valorNum = double.tryParse(_valor.text.trim().replaceAll(',', '.'));
      final data = {
        'cargo': _cargo,
        'tipoRemuneracao': tipoFinal,
        if (tipoFinal == 'Fixo') 'salario': valorNum,
        if (tipoFinal == 'Porcentagem') 'porcentagem': valorNum,
        if (_telefone.text.trim().isNotEmpty) 'telefone': _telefone.text.trim(),
        'oficinaIds': _oficinasSelected.toList(),
      };

      final notifier = ref.read(funcionariosNotifierProvider.notifier);
      if (_editando) {
        await notifier.atualizar(widget.funcionario!.id, data);
      } else {
        await notifier.criar({
          'nome': _nome.text.trim(),
          'email': _email.text.trim(),
          ...data,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao salvar funcionário.');
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
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
                      _editando ? 'Editar funcionário' : 'Novo funcionário',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_editando) ...[
                          _campo(_nome, 'Nome *', obrigatorio: true),
                          const SizedBox(height: 12),
                          _campo(_email, 'E-mail *', teclado: TextInputType.emailAddress, obrigatorio: true),
                          const SizedBox(height: 12),
                        ],
                        _campo(_telefone, 'Telefone', teclado: TextInputType.phone),
                        const SizedBox(height: 12),
                        GamaSearchableSelect<String>(
                          label: 'Cargo *',
                          selectedValue: _cargo,
                          optionsBuilder: _filtrarCargos,
                          displayString: (c) => _cargoLabels[c] ?? c,
                          isRequired: true,
                          onChanged: (v) => setState(() {
                            _cargo = v;
                            if (v == 'Gerente') {
                              _tipoRemuneracao = null;
                              _valor.clear();
                            }
                          }),
                        ),
                        if (_cargo != null && _cargo != 'Gerente') ...[
                          const SizedBox(height: 12),
                          GamaSearchableSelect<String>(
                            label: 'Remuneração *',
                            selectedValue: _tipoRemuneracao,
                            optionsBuilder: _filtrarTipos,
                            displayString: (t) => _tipoRemuneracaoLabels[t] ?? t,
                            isRequired: true,
                            onChanged: (v) => setState(() {
                              _tipoRemuneracao = v;
                              _valor.clear();
                            }),
                          ),
                          const SizedBox(height: 12),
                          _campo(
                            _valor,
                            _tipoRemuneracao == 'Porcentagem' ? 'Porcentagem (%)' : 'Salário (R\$)',
                            teclado: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text('Oficinas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        if (_loadingOficinas)
                          const Center(child: CircularProgressIndicator())
                        else if (_oficinas.isEmpty)
                          const Text('Nenhuma oficina disponível', style: TextStyle(color: AppColors.textSecondary))
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: _oficinas.map((o) => CheckboxListTile(
                                dense: true,
                                title: Text(o.nome, style: const TextStyle(fontSize: 14)),
                                value: _oficinasSelected.contains(o.id),
                                onChanged: (v) => setState(() {
                                  if (v == true) { _oficinasSelected.add(o.id); }
                                  else { _oficinasSelected.remove(o.id); }
                                }),
                                activeColor: AppColors.primary,
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GamaButton(
                  label: _editando ? 'Salvar alterações' : 'Criar funcionário',
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
    bool obrigatorio = false,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true, fillColor: Colors.white,
      ),
      validator: obrigatorio ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null : null,
    );
  }
}
