import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: const Color(0xFFF5F7FA), // cor de fundo neutra, intencional
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
        // Painel esquerdo — branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primaryMid, AppColors.primaryLight],
              ),
            ),
            child: Stack(
              children: [
                // Círculos decorativos de fundo
                Positioned(
                  top: -80,
                  left: -80,
                  child: _DecorativeCircle(size: 320, opacity: 0.08),
                ),
                Positioned(
                  bottom: -60,
                  right: -60,
                  child: _DecorativeCircle(size: 280, opacity: 0.08),
                ),
                Positioned(
                  top: 160,
                  right: -40,
                  child: _DecorativeCircle(size: 180, opacity: 0.06),
                ),
                // Conteúdo central
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.build_circle,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'GAMA',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gestão Automotiva de\nMecânica e Atendimento',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withAlpha(210),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 56),
                        ..._features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(f.$1, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  f.$2,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Painel direito — formulário
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
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
            ],
          ),
        ),
      ],
    ),
    );
  }

  static const _features = [
    (Icons.receipt_long_outlined, 'Ordens de serviço completas'),
    (Icons.people_outline, 'Gestão de equipe por oficina'),
    (Icons.bar_chart_outlined, 'Relatórios e indicadores'),
  ];
}

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
        // Fundo gradiente — ocupa o topo da tela
        Container(
          height: screenHeight * 0.42,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primaryMid, AppColors.primaryLight],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: _DecorativeCircle(size: 220, opacity: 0.08),
              ),
              Positioned(
                bottom: 20,
                left: -40,
                child: _DecorativeCircle(size: 160, opacity: 0.06),
              ),
            ],
          ),
        ),

        // Conteúdo scrollável sobre o fundo
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Branding no topo azul
                SizedBox(
                  height: screenHeight * 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GAMA',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gestão Automotiva de Mecânica e Atendimento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card branco com o formulário, sobrepondo o azul
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
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
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bem-vindo de volta',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Acesse sua conta para continuar',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 36),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-mail',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: senhaController,
            obscureText: obscureSenha,
            onFieldSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleSenha,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe a senha' : null,
          ),
          const SizedBox(height: 28),
          GamaButton(
            label: 'Entrar',
            isLoading: isLoading,
            onPressed: isLoading ? null : onLogin,
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
