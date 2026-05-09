import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import 'auth_notifier.dart';

class TrocarSenhaScreen extends ConsumerStatefulWidget {
  const TrocarSenhaScreen({super.key});

  @override
  ConsumerState<TrocarSenhaScreen> createState() => _TrocarSenhaScreenState();
}

class _TrocarSenhaScreenState extends ConsumerState<TrocarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenha = TextEditingController();
  final _confirmar = TextEditingController();
  bool _loading = false;
  bool _obscureNova = true;
  bool _obscureConfirmar = true;

  @override
  void dispose() {
    _novaSenha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(dioClientProvider).post('/auth/trocar-senha', data: {
        'novaSenha': _novaSenha.text.trim(),
      });
      await ref.read(authNotifierProvider.notifier).confirmarTrocaSenha();
      if (mounted) GamaSnackBar.success(context, 'Senha alterada com sucesso!');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao trocar senha.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Defina sua senha',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'É seu primeiro acesso. Crie uma senha para continuar.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  _campoSenha(_novaSenha, 'Nova senha', _obscureNova, () => setState(() => _obscureNova = !_obscureNova)),
                  const SizedBox(height: 16),
                  _campoSenha(_confirmar, 'Confirmar senha', _obscureConfirmar, () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      if (v != _novaSenha.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  GamaButton(label: 'Salvar senha', onPressed: _salvar, isLoading: _loading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoSenha(
    TextEditingController ctrl,
    String label,
    bool obscure,
    VoidCallback toggleObscure, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
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
        suffixIcon: IconButton(
          onPressed: toggleObscure,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
        ),
      ),
      validator: validator ?? (v) {
        if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
        if (v.trim().length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }
}
