import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../data/assinatura_remote_data_source.dart';
import '../../domain/assinatura_models.dart';

/// Lógica de cobrança via Pagar.me — pronta para ser ativada quando o
/// pagamento online for integrado. Por enquanto não é chamada.
///
/// Para ativar: substituir [showMudarPlanoWhatsappModal] em
/// assinatura_screen.dart por [executarMudancaDePlano].
Future<void> executarMudancaDePlano({
  required BuildContext context,
  required WidgetRef ref,
  required NomePlano novoPlano,
  required CicloCobranca ciclo,
  required VoidCallback onSubmittingChanged,
}) async {
  onSubmittingChanged();
  try {
    await ref
        .read(assinaturaRemoteDataSourceProvider)
        .mudarPlano(novoPlano, ciclo);

    final nomes = {
      NomePlano.solo: 'Solo',
      NomePlano.oficina: 'Oficina',
      NomePlano.rede: 'Rede',
    };
    if (context.mounted) {
      GamaSnackBar.success(
          context, 'Plano atualizado para ${nomes[novoPlano]}.');
    }
  } catch (e) {
    if (context.mounted) GamaSnackBar.error(context, e.toString());
  } finally {
    onSubmittingChanged();
  }
}
