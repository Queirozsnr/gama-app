import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/conta_remote_data_source.dart';

/// Seção "Conta" das Configurações: exclusão da própria conta, exigida pela
/// Play Store e pela App Store para apps em que dá para criar conta.
class ContaSection extends StatelessWidget {
  const ContaSection({super.key});

  @override
  Widget build(BuildContext context) {
    const texto = Text(
      'Excluir a sua conta apaga os seus dados pessoais do GAMA. Essa ação não pode ser desfeita.',
      style: TextStyle(fontSize: 13, color: AppColors.ink2),
    );
    final botao = OutlinedButton.icon(
      onPressed: () => showDialog<void>(context: context, builder: (_) => const _ExcluirContaDialog()),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: const Text('Excluir minha conta'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
    );
    return SectionCard(
      title: 'Conta',
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [texto, const SizedBox(height: 12), botao],
              )
            : Row(children: [const Expanded(child: texto), const SizedBox(width: 12), botao]),
      ),
    );
  }
}

class _ExcluirContaDialog extends ConsumerStatefulWidget {
  const _ExcluirContaDialog();

  @override
  ConsumerState<_ExcluirContaDialog> createState() => _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends ConsumerState<_ExcluirContaDialog> {
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  late final Future<PreviaExclusaoConta> _previa;
  bool _excluindo = false;

  @override
  void initState() {
    super.initState();
    _previa = ref.read(contaRemoteDataSourceProvider).previaExclusao();
    _confirmacao.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  bool get _confirmado => _confirmacao.text.trim().toUpperCase() == 'EXCLUIR' && _senha.text.isNotEmpty;

  Future<void> _excluir() async {
    setState(() => _excluindo = true);
    try {
      await ref.read(contaRemoteDataSourceProvider).excluir(senha: _senha.text, confirmacao: _confirmacao.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await ref.read(authNotifierProvider.notifier).logout();
      messenger.showSnackBar(const SnackBar(content: Text('Sua conta foi excluída.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _excluindo = false);
      final msg = e is DioException
          ? ((e.response?.data as Map?)?['error'] as String? ?? 'Erro ao excluir a conta.')
          : 'Erro ao excluir a conta.';
      GamaSnackBar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<PreviaExclusaoConta>(
            future: _previa,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return _Mensagem(
                  titulo: 'Excluir minha conta',
                  texto: 'Não foi possível carregar as informações agora. Tente novamente.',
                  onFechar: () => Navigator.pop(context),
                );
              }
              final previa = snap.data!;
              if (!previa.permitida) {
                return _Mensagem(
                  titulo: 'Excluir minha conta',
                  texto: previa.motivo ?? 'Esta conta não pode ser excluída pelo app.',
                  onFechar: () => Navigator.pop(context),
                );
              }
              return _formulario(previa);
            },
          ),
        ),
      ),
    );
  }

  Widget _formulario(PreviaExclusaoConta previa) {
    final levaOficina = previa.oficinasExcluidas.isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Excluir minha conta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (levaOficina)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Você é o único gestor de ${previa.oficinasExcluidas.join(', ')}. '
                'Excluir a sua conta exclui também a oficina e todos os dados dela: '
                'clientes, veículos, ordens de serviço, fotos, estoque e funcionários.\n\n'
                'A oficina é desativada agora e os dados são apagados em ${previa.diasAteApagar} dias. '
                'Até lá, dá para desfazer falando com o suporte.',
                style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.danger),
              ),
            )
          else
            const Text(
              'Seu nome, e-mail e senha serão apagados e você não conseguirá mais entrar. '
              'As ordens de serviço e pagamentos em que você aparece continuam na oficina, '
              'como "Usuário removido".',
              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.ink2),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _senha,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: _dec('Sua senha'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmacao,
            textCapitalization: TextCapitalization.characters,
            decoration: _dec('Digite EXCLUIR para confirmar'),
          ),
          const SizedBox(height: 20),
          GamaButton(
            label: levaOficina ? 'Excluir conta e oficina' : 'Excluir minha conta',
            variant: GamaButtonVariant.danger,
            isLoading: _excluindo,
            onPressed: _confirmado && !_excluindo ? _excluir : null,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _excluindo ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink2),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.ink2, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      );
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.titulo, required this.texto, required this.onFechar});
  final String titulo;
  final String texto;
  final VoidCallback onFechar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 12),
        Text(texto, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.ink2)),
        const SizedBox(height: 20),
        GamaButton(label: 'Fechar', variant: GamaButtonVariant.secondary, onPressed: onFechar),
      ],
    );
  }
}
