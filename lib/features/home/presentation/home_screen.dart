import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../gerencial/presentation/gerencial_screen.dart';
import '../../painel/presentation/painel_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final token = auth?.token;
    final isGerencial =
        token != null && JwtDecoder.permissaoGerenciarOficinas(token);

    return isGerencial ? const GerencialScreen() : const PainelScreen();
  }
}
