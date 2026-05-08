import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/auth_state.dart';
import 'auth_notifier.dart';

class SelectOficinaScreen extends ConsumerStatefulWidget {
  const SelectOficinaScreen({super.key});

  @override
  ConsumerState<SelectOficinaScreen> createState() => _SelectOficinaScreenState();
}

class _SelectOficinaScreenState extends ConsumerState<SelectOficinaScreen> {
  int? _loadingId;

  Future<void> _selecionar(int oficinaId) async {
    setState(() => _loadingId = oficinaId);
    try {
      await ref.read(authNotifierProvider.notifier).selectOficina(oficinaId);
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  static String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nome.substring(0, nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final oficinas = ref.watch(authNotifierProvider).valueOrNull?.availableOficinas ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Selecione a unidade',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Em qual unidade você vai trabalhar hoje?',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < oficinas.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 70),
                        _OficinaItem(
                          oficina: oficinas[i],
                          initials: _initials(oficinas[i].nome),
                          isLoading: _loadingId == oficinas[i].id,
                          isDisabled: _loadingId != null,
                          onTap: () => _selecionar(oficinas[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OficinaItem extends StatelessWidget {
  const _OficinaItem({
    required this.oficina,
    required this.initials,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final OficinaItem oficina;
  final String initials;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            GamaAvatar(initials: initials, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oficina.nome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Toque para entrar',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
