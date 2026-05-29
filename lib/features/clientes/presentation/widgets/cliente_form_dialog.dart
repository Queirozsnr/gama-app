import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_button.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../data/clientes_remote_data_source.dart';
import '../../domain/cliente.dart';
import '../clientes_notifier.dart';

class ClienteFormDialog extends ConsumerStatefulWidget {
  const ClienteFormDialog({super.key, this.cliente, this.onCriado});

  final Cliente? cliente;
  final void Function(Cliente)? onCriado;

  @override
  ConsumerState<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends ConsumerState<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _cpf;
  late final TextEditingController _cidade;
  bool _loading = false;

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nome = TextEditingController(text: c?.nome ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _telefone = TextEditingController(text: formatPhone(c?.telefone));
    _cpf = TextEditingController(text: formatCpfCnpj(c?.cpf));
    _cidade = TextEditingController(text: c?.cidade ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _cpf.dispose();
    _cidade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(clientesNotifierProvider.notifier);
      if (_editando) {
        await notifier.atualizar(
          id: widget.cliente!.id,
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          telefone: _telefone.text.trim(),
          cpf: _cpf.text.trim(),
          cidade: _cidade.text.trim(),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        final id = await notifier.criar(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          telefone: _telefone.text.trim(),
          cpf: _cpf.text.trim(),
          cidade: _cidade.text.trim(),
        );
        if (mounted) {
          final nav = Navigator.of(context);
          if (widget.onCriado != null) {
            final cliente = await ref.read(clientesRemoteDataSourceProvider).obter(id);
            if (mounted) widget.onCriado!(cliente);
          }
          nav.pop(true);
        }
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao salvar cliente.');
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _editando ? 'Editar cliente' : 'Novo cliente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _campo(_nome, 'Nome *', obrigatorio: true),
                const SizedBox(height: 12),
                _campo(_telefone, 'Telefone', teclado: TextInputType.phone,
                    formatters: [PhoneInputFormatter()]),
                const SizedBox(height: 12),
                _campo(_email, 'E-mail', teclado: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _campo(_cpf, 'CPF / CNPJ', teclado: TextInputType.number,
                    formatters: [CpfCnpjInputFormatter()]),
                const SizedBox(height: 12),
                _campo(_cidade, 'Cidade'),
                const SizedBox(height: 24),
                GamaButton(
                  label: _editando ? 'Salvar alterações' : 'Criar cliente',
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

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    bool obrigatorio = false,
    TextInputType teclado = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: obrigatorio
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
          : null,
    );
  }
}
