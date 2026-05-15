import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import 'auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscureSenha = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _senhaController.text,
          );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: isDesktop
          ? _DesktopLayout(
              formKey: _formKey,
              emailController: _emailController,
              senhaController: _senhaController,
              obscureSenha: _obscureSenha,
              onToggleSenha: () => setState(() => _obscureSenha = !_obscureSenha),
              isLoading: _isLoading,
              error: _error,
              onLogin: _handleLogin,
            )
          : _MobileLayout(
              formKey: _formKey,
              emailController: _emailController,
              senhaController: _senhaController,
              obscureSenha: _obscureSenha,
              onToggleSenha: () => setState(() => _obscureSenha = !_obscureSenha),
              isLoading: _isLoading,
              error: _error,
              onLogin: _handleLogin,
            ),
    );
  }
}

// ── Desktop: dark left panel + warm form ──────────────────────────
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.formKey,
    required this.emailController,
    required this.senhaController,
    required this.obscureSenha,
    required this.onToggleSenha,
    required this.isLoading,
    required this.error,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController senhaController;
  final bool obscureSenha;
  final VoidCallback onToggleSenha;
  final bool isLoading;
  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 56, child: const _BrandPanel()),
          Expanded(
            flex: 44,
            child: Container(
              color: AppColors.bg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 56),
                    child: _LoginForm(
                      formKey: formKey,
                      emailController: emailController,
                      senhaController: senhaController,
                      obscureSenha: obscureSenha,
                      onToggleSenha: onToggleSenha,
                      isLoading: isLoading,
                      error: error,
                      onLogin: onLogin,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark background
        Container(color: AppColors.sidebarBg),
        // Subtle grid texture
        Positioned.fill(
          child: CustomPaint(painter: const _GridPainter()),
        ),
        // Diagonal accent strip
        Positioned(
          top: -40,
          right: -120,
          child: Transform.rotate(
            angle: 28 * pi / 180,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'G',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1714),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GAMA',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'oficina · sistema',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.sidebarText,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Headline block
                Text(
                  '── Gestão Automotiva',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: -1.8,
                    ),
                    children: const [
                      TextSpan(text: 'A sua oficina,\n'),
                      TextSpan(
                        text: 'do balcão',
                        style: TextStyle(color: AppColors.accent),
                      ),
                      TextSpan(text: '\nao elevador.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ordens de serviço, clientes, veículos, estoque e equipe em um só lugar — separado por oficina, para você gerenciar todas as suas unidades.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFFD4CBB9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Stats row
                Row(
                  children: [
                    for (final item in [
                      ('OS', 'ordens de serviço'),
                      ('MULTI', 'tenant por oficina'),
                      ('LIVE', 'estoque + agenda'),
                    ]) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$2.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: AppColors.sidebarText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (item.$1 != 'LIVE') const SizedBox(width: 28),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Grid texture painter
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sidebarLine.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Mobile: dark header + card form ───────────────────────────────
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.formKey,
    required this.emailController,
    required this.senhaController,
    required this.obscureSenha,
    required this.onToggleSenha,
    required this.isLoading,
    required this.error,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController senhaController;
  final bool obscureSenha;
  final VoidCallback onToggleSenha;
  final bool isLoading;
  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Dark top section
        Container(
          height: screenHeight * 0.44,
          color: AppColors.sidebarBg,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: const _GridPainter()),
              ),
              Positioned(
                top: -40,
                right: -60,
                child: Transform.rotate(
                  angle: 28 * pi / 180,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.36,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'G',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1714),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GAMA',
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gestão de Oficinas',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.sidebarText,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _LoginForm(
                    formKey: formKey,
                    emailController: emailController,
                    senhaController: senhaController,
                    obscureSenha: obscureSenha,
                    onToggleSenha: onToggleSenha,
                    isLoading: isLoading,
                    error: error,
                    onLogin: onLogin,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared form ────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.senhaController,
    required this.obscureSenha,
    required this.onToggleSenha,
    required this.isLoading,
    required this.error,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController senhaController;
  final bool obscureSenha;
  final VoidCallback onToggleSenha;
  final bool isLoading;
  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '01 · Acesso',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bem-vindo de volta',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Acesse sua conta para abrir o dia.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink2),
          ),
          const SizedBox(height: 32),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error!,
                      style: GoogleFonts.inter(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _FieldLabel('E-MAIL'),
          const SizedBox(height: 6),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'seu@email.com.br',
              prefixIcon: const Icon(Icons.alternate_email, size: 18),
              fillColor: AppColors.surface,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
          ),
          const SizedBox(height: 18),
          _FieldLabel('SENHA'),
          const SizedBox(height: 6),
          TextFormField(
            controller: senhaController,
            obscureText: obscureSenha,
            onFieldSubmitted: (_) => onLogin(),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              fillColor: AppColors.surface,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: onToggleSenha,
                color: AppColors.ink2,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe a senha' : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Esqueci a senha',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          GamaButton(
            label: 'Entrar',
            isLoading: isLoading,
            onPressed: isLoading ? null : onLogin,
            height: 50,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GAMA v1.0.0',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.ink3,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'API · OK',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.ink3,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.ink2,
        letterSpacing: 0.5,
      ),
    );
  }
}
