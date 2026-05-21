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

  static String _tenantCode(int id) => '#${id.toString().padLeft(3, '0')}';

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final auth = authAsync.valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _Header(
            count: oficinas.length,
            isDesktop: isDesktop,
            onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
          Expanded(
            child: isDesktop
                ? _DesktopBody(
                    oficinas: oficinas,
                    loadingId: _loadingId,
                    onSelect: _selecionar,
                    initials: _initials,
                    tenantCode: _tenantCode,
                  )
                : _MobileBody(
                    oficinas: oficinas,
                    loadingId: _loadingId,
                    onSelect: _selecionar,
                    initials: _initials,
                    tenantCode: _tenantCode,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.isDesktop,
    required this.onLogout,
  });

  final int count;
  final bool isDesktop;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 20,
        MediaQuery.of(context).padding.top + (isDesktop ? 16 : 12),
        isDesktop ? 32 : 20,
        isDesktop ? 16 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 36 : 32,
            height: isDesktop ? 36 : 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: isDesktop ? 18 : 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${count.toString().padLeft(2, '0')} · ${isDesktop ? 'SELECIONAR UNIDADE' : 'UNIDADE'}',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (isDesktop)
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_outlined, size: 16, color: AppColors.ink3),
              label: const Text(
                'Sair',
                style: TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
            )
          else
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_outlined, size: 20, color: AppColors.ink3),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ── Desktop body ──────────────────────────────────────────────────────────────

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({
    required this.oficinas,
    required this.loadingId,
    required this.onSelect,
    required this.initials,
    required this.tenantCode,
  });

  final List<OficinaItem> oficinas;
  final int? loadingId;
  final void Function(int) onSelect;
  final String Function(String) initials;
  final String Function(int) tenantCode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Onde você vai trabalhar hoje?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppColors.ink2),
                  children: [
                    const TextSpan(text: 'Sua conta tem acesso a '),
                    TextSpan(
                      text: '${oficinas.length} ${oficinas.length == 1 ? 'unidade' : 'unidades'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const TextSpan(
                      text: '. Os dados são separados — você só vê o que pertence à unidade escolhida.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: oficinas
                    .map((o) => SizedBox(
                          width: 300,
                          child: _DesktopCard(
                            oficina: o,
                            initials: initials(o.nome),
                            tenantCode: tenantCode(o.id),
                            isLoading: loadingId == o.id,
                            isDisabled: loadingId != null,
                            onTap: () => onSelect(o.id),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você pode trocar de unidade a qualquer momento pelo menu lateral. '
                        'Cada oficina mantém seus próprios clientes, OS, estoque e equipe.',
                        style: TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopCard extends StatelessWidget {
  const _DesktopCard({
    required this.oficina,
    required this.initials,
    required this.tenantCode,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final OficinaItem oficina;
  final String initials;
  final String tenantCode;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GamaAvatar(initials: initials, size: 40),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              oficina.nome,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatColumn(
                  value: oficina.osAbertas.toString(),
                  label: 'OS ABERTAS',
                ),
                const SizedBox(width: 24),
                _StatColumn(
                  value: oficina.equipeCount.toString(),
                  label: 'NA EQUIPE',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TENANT · $tenantCode',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: AppColors.ink3,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Entrar →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? AppColors.ink3 : AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Mobile body ───────────────────────────────────────────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody({
    required this.oficinas,
    required this.loadingId,
    required this.onSelect,
    required this.initials,
    required this.tenantCode,
  });

  final List<OficinaItem> oficinas;
  final int? loadingId;
  final void Function(int) onSelect;
  final String Function(String) initials;
  final String Function(int) tenantCode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Onde você vai trabalhar hoje?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.ink2),
              children: [
                const TextSpan(text: 'Sua conta tem acesso a '),
                TextSpan(
                  text: '${oficinas.length} ${oficinas.length == 1 ? 'unidade' : 'unidades'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...oficinas.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MobileCard(
                  oficina: o,
                  initials: initials(o.nome),
                  isLoading: loadingId == o.id,
                  isDisabled: loadingId != null,
                  onTap: () => onSelect(o.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            GamaAvatar(initials: initials, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oficina.nome,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${oficina.osAbertas} OS',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${oficina.equipeCount} na equipe',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
