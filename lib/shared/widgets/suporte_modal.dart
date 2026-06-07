import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import 'gama_snack_bar.dart';

const _kWhatsappNumber = '5592992790397'; // substitua pelo número real
const _kSupportEmail = 'suporte@gama.com.br';

/// Abre o modal de suporte sobre a tela atual.
void showSuporteModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _SuporteDialog(),
  );
}

class _SuporteDialog extends ConsumerWidget {
  const _SuporteDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final currentOficina = oficinas.cast<OficinaItem?>().firstWhere(
      (o) => o?.id == auth?.oficinaId,
      orElse: () => null,
    );
    final oficinaNome = currentOficina?.nome ?? 'Minha Oficina';

    final grupos = auth?.availableGroups ?? [];
    final currentGrupoId = auth?.grupoOficinaId;
    final currentGrupo = grupos.cast<GrupoItem?>().firstWhere(
      (g) => g?.id == currentGrupoId,
      orElse: () => null,
    );
    final grupoNome = currentGrupo?.nome ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            _Body(
              context: context,
              oficinaNome: oficinaNome,
              grupoNome: grupoNome,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header escuro ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUPORTE GAMA',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sidebarText.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Como podemos ajudar?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online agora  ·  Seg a sex, 8h às 18h',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.sidebarText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Body claro ────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.context,
    required this.oficinaNome,
    required this.grupoNome,
  });

  final BuildContext context;
  final String oficinaNome;
  final String grupoNome;

  @override
  Widget build(BuildContext _) {
    return Container(
      color: const Color(0xFFF8F5F0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contexto da oficina
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 14, color: AppColors.ink3),
                const SizedBox(width: 6),
                Text(
                  'Atendendo como  ',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ink3,
                  ),
                ),
                Expanded(
                  child: Text(
                    oficinaNome,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (grupoNome.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      grupoNome.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAE4DC)),

          // WhatsApp
          Padding(
            padding: const EdgeInsets.all(16),
            child: _WhatsAppCard(context: context),
          ),

          // Divisor e-mail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFD6CFC4))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OU POR E-MAIL',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFD6CFC4))),
              ],
            ),
          ),

          // E-mail
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _EmailSection(context: context),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── WhatsApp card ─────────────────────────────────────────────────────────────

class _WhatsAppCard extends StatelessWidget {
  const _WhatsAppCard({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF25D366), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _openWhatsApp,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.chat_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '+ RÁPIDO',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Resposta em ~5 min · ${_formatPhone(_kWhatsappNumber)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_outward,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWhatsApp() {
    final uri = Uri.parse('https://wa.me/$_kWhatsappNumber');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatPhone(String number) {
    if (number.startsWith('55') && number.length >= 12) {
      final local = number.substring(2);
      if (local.length == 11) {
        return '(${local.substring(0, 2)}) ${local.substring(2, 7)}-${local.substring(7)}';
      }
    }
    return number;
  }
}

// ── E-mail section ────────────────────────────────────────────────────────────

class _EmailSection extends StatelessWidget {
  const _EmailSection({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEAE4DC)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.mail_outline,
                      size: 18, color: AppColors.ink2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    _kSupportEmail,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Resposta em até 24h úteis',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.ink3.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        const ClipboardData(text: _kSupportEmail));
                    GamaSnackBar.success(context, 'E-mail copiado');
                  },
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  label: const Text('Copiar e-mail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: Color(0xFFD6CFC4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.send_outlined, size: 14),
                  label: const Text('Enviar e-mail'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendEmail() {
    final uri = Uri(scheme: 'mailto', path: _kSupportEmail);
    launchUrl(uri);
  }
}
