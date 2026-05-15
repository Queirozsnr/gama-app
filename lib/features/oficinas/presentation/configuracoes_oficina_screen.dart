import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../shared/utils/file_picker_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/oficina_model.dart';
import 'oficinas_notifier.dart';

class ConfiguracoesOficinaScreen extends ConsumerWidget {
  const ConfiguracoesOficinaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oficinasNotifierProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(e.toString(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GamaButton(
              label: 'Tentar novamente',
              isFullWidth: false,
              onPressed: () => ref.invalidate(oficinasNotifierProvider),
            ),
          ],
        ),
      ),
      data: (oficinas) {
        if (oficinas.isEmpty) {
          return const Center(
            child: Text('Nenhuma oficina encontrada.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          );
        }
        return _ConfigScreen(oficinas: oficinas);
      },
    );
  }
}

// ── Seletor + form ─────────────────────────────────────────────────────────────

class _ConfigScreen extends StatefulWidget {
  const _ConfigScreen({required this.oficinas});
  final List<OficinaModel> oficinas;

  @override
  State<_ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<_ConfigScreen> {
  late int _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.oficinas.first.id;
  }

  OficinaModel get _oficina =>
      widget.oficinas.firstWhere((o) => o.id == _selectedId, orElse: () => widget.oficinas.first);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.oficinas.length > 1) ...[
            _OficinaSeletor(
              oficinas: widget.oficinas,
              selectedId: _selectedId,
              onChanged: (id) => setState(() => _selectedId = id),
            ),
            const SizedBox(height: 24),
          ],
          _ConfigForm(key: ValueKey(_selectedId), oficina: _oficina),
        ],
      ),
    );
  }
}

// ── Seletor de oficina ─────────────────────────────────────────────────────────

class _OficinaSeletor extends StatelessWidget {
  const _OficinaSeletor({
    required this.oficinas,
    required this.selectedId,
    required this.onChanged,
  });

  final List<OficinaModel> oficinas;
  final int selectedId;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: oficinas
              .map((o) => DropdownMenuItem(value: o.id, child: Text(o.nome)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

// ── Formulário principal ───────────────────────────────────────────────────────

class _ConfigForm extends ConsumerStatefulWidget {
  const _ConfigForm({super.key, required this.oficina});
  final OficinaModel oficina;

  @override
  ConsumerState<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends ConsumerState<_ConfigForm> {
  final _formKey = GlobalKey<FormState>();

  late final _nomeCtrl       = TextEditingController(text: widget.oficina.nome);
  late final _enderecoCtrl   = TextEditingController(text: widget.oficina.endereco);
  late final _telefoneCtrl   = TextEditingController(text: widget.oficina.telefone);
  late final _telefone2Ctrl  = TextEditingController(text: widget.oficina.telefone2);
  late final _emailCtrl      = TextEditingController(text: widget.oficina.email);
  late final _whatsappCtrl   = TextEditingController(text: widget.oficina.whatsapp);
  late final _instagramCtrl  = TextEditingController(text: widget.oficina.instagram);
  late final _cnpjCtrl       = TextEditingController(text: widget.oficina.cnpj);
  late final _corCtrl        = TextEditingController(text: widget.oficina.corPadrao ?? '#B83524');

  bool _saving = false;
  Uint8List? _logoPreview;
  bool _uploadingLogo = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _enderecoCtrl.dispose();
    _telefoneCtrl.dispose();
    _telefone2Ctrl.dispose();
    _emailCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    _cnpjCtrl.dispose();
    _corCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await pickImageBytes();
    if (result == null) return;

    setState(() {
      _uploadingLogo = true;
      _logoPreview = result.bytes;
    });
    try {
      await ref
          .read(oficinasNotifierProvider.notifier)
          .uploadLogo(widget.oficina.id, result.bytes, result.name);
      if (mounted) GamaSnackBar.success(context, 'Logo atualizado com sucesso.');
    } catch (e) {
      if (mounted) {
        GamaSnackBar.error(context, e.toString());
        setState(() => _logoPreview = null);
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(oficinasNotifierProvider.notifier).atualizar(
            widget.oficina.id,
            nome: _nomeCtrl.text.trim(),
            endereco: _enderecoCtrl.text.trim(),
            telefone: _telefoneCtrl.text.trim(),
            ativo: widget.oficina.ativo,
            telefone2: _telefone2Ctrl.text.trim().isEmpty ? null : _telefone2Ctrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
            whatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
            instagram: _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
            cnpj: _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
            corPadrao: _corCtrl.text.trim().isEmpty ? null : _corCtrl.text.trim(),
          );
      if (mounted) GamaSnackBar.success(context, 'Configurações salvas.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LogoSection(
                  oficina: widget.oficina,
                  preview: _logoPreview,
                  uploading: _uploadingLogo,
                  onPick: _pickLogo,
                ),
                const SizedBox(width: 28),
                Expanded(child: _Fields(
                  nomeCtrl: _nomeCtrl,
                  enderecoCtrl: _enderecoCtrl,
                  telefoneCtrl: _telefoneCtrl,
                  telefone2Ctrl: _telefone2Ctrl,
                  emailCtrl: _emailCtrl,
                  whatsappCtrl: _whatsappCtrl,
                  instagramCtrl: _instagramCtrl,
                  cnpjCtrl: _cnpjCtrl,
                  corCtrl: _corCtrl,
                  onColorChanged: (c) => setState(() {}),
                )),
              ],
            )
          else
            Column(
              children: [
                _LogoSection(
                  oficina: widget.oficina,
                  preview: _logoPreview,
                  uploading: _uploadingLogo,
                  onPick: _pickLogo,
                ),
                const SizedBox(height: 24),
                _Fields(
                  nomeCtrl: _nomeCtrl,
                  enderecoCtrl: _enderecoCtrl,
                  telefoneCtrl: _telefoneCtrl,
                  telefone2Ctrl: _telefone2Ctrl,
                  emailCtrl: _emailCtrl,
                  whatsappCtrl: _whatsappCtrl,
                  instagramCtrl: _instagramCtrl,
                  cnpjCtrl: _cnpjCtrl,
                  corCtrl: _corCtrl,
                  onColorChanged: (c) => setState(() {}),
                ),
              ],
            ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: GamaButton(
              label: 'Salvar alterações',
              isLoading: _saving,
              isFullWidth: false,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seção de logo ──────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.oficina,
    required this.preview,
    required this.uploading,
    required this.onPick,
  });

  final OficinaModel oficina;
  final Uint8List? preview;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Logo da oficina',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _LogoPreview(oficina: oficina, preview: preview),
          const SizedBox(height: 16),
          if (uploading)
            const SizedBox(
              height: 36,
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            GamaButton(
              label: oficina.logoUrl != null ? 'Trocar logo' : 'Enviar logo',
              icon: Icons.upload_outlined,
              variant: GamaButtonVariant.secondary,
              height: 36,
              onPressed: onPick,
            ),
          const SizedBox(height: 8),
          const Text(
            'PNG ou JPG, máx. 2 MB',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.oficina, required this.preview});
  final OficinaModel oficina;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final hasLogo = preview != null || oficina.logoUrl != null;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? (preview != null
              ? Image.memory(preview!, fit: BoxFit.contain)
              : Image.network(
                  '$kBaseUrl${oficina.logoUrl}',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _Placeholder(nome: oficina.nome),
                ))
          : _Placeholder(nome: oficina.nome),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.nome});
  final String nome;

  String get _initials {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nome.substring(0, nome.length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Campos do formulário ───────────────────────────────────────────────────────

class _Fields extends StatelessWidget {
  const _Fields({
    required this.nomeCtrl,
    required this.enderecoCtrl,
    required this.telefoneCtrl,
    required this.telefone2Ctrl,
    required this.emailCtrl,
    required this.whatsappCtrl,
    required this.instagramCtrl,
    required this.cnpjCtrl,
    required this.corCtrl,
    required this.onColorChanged,
  });

  final TextEditingController nomeCtrl;
  final TextEditingController enderecoCtrl;
  final TextEditingController telefoneCtrl;
  final TextEditingController telefone2Ctrl;
  final TextEditingController emailCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController cnpjCtrl;
  final TextEditingController corCtrl;
  final void Function(String) onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.store_outlined, label: 'Informações básicas'),
        const SizedBox(height: 14),
        _Field(label: 'Nome da oficina *', controller: nomeCtrl,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null),
        const SizedBox(height: 12),
        _Field(label: 'Endereço', controller: enderecoCtrl, hint: 'Rua, número, bairro, cidade'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(label: 'Telefone principal', controller: telefoneCtrl, hint: '(92) 99999-9999', keyboardType: TextInputType.phone)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'Telefone 2', controller: telefone2Ctrl, hint: '(92) 99999-9999', keyboardType: TextInputType.phone)),
        ]),

        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.contact_phone_outlined, label: 'Contato digital'),
        const SizedBox(height: 14),
        _Field(label: 'E-mail', controller: emailCtrl, hint: 'contato@oficina.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(label: 'WhatsApp', controller: whatsappCtrl, hint: '(92) 99999-9999', keyboardType: TextInputType.phone)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'Instagram', controller: instagramCtrl, hint: '@minha_oficina', prefix: '@')),
        ]),

        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.receipt_long_outlined, label: 'Dados fiscais'),
        const SizedBox(height: 14),
        _Field(label: 'CNPJ', controller: cnpjCtrl, hint: '00.000.000/0001-00', keyboardType: TextInputType.number),

        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.palette_outlined, label: 'Personalização'),
        const SizedBox(height: 14),
        _ColorPicker(controller: corCtrl, onChanged: onColorChanged),
      ],
    );
  }
}

// ── Seção header ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ── Campo de texto ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.prefix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ── Seletor de cor ─────────────────────────────────────────────────────────────

const _kPresetColors = [
  '#B83524',
  '#FF7A1A',
  '#1F8A52',
  '#2563EB',
  '#7C3AED',
  '#1A1714',
];

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final void Function(String) onChanged;

  Color? _parse(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      if (h.length != 6) return null;
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cor padrão (usada em orçamentos e documentos)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            ..._kPresetColors.map((hex) {
              final color = _parse(hex)!;
              final selected = controller.text.toUpperCase() == hex.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    controller.text = hex;
                    onChanged(hex);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.textPrimary : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'JetBrains Mono'),
                decoration: InputDecoration(
                  hintText: '#000000',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parse(controller.text) ?? AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
