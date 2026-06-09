import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/assinatura_models.dart';

const _kWhatsappNumber = '5592992790397';

void showMudarPlanoWhatsappModal(
  BuildContext context, {
  required NomePlano plano,
  required double preco,
  required CicloCobranca ciclo,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _MudarPlanoModal(plano: plano, preco: preco, ciclo: ciclo),
  );
}

class _MudarPlanoModal extends StatelessWidget {
  const _MudarPlanoModal({
    required this.plano,
    required this.preco,
    required this.ciclo,
  });

  final NomePlano plano;
  final double preco;
  final CicloCobranca ciclo;

  static const _nomes = {
    NomePlano.solo: 'Solo',
    NomePlano.oficina: 'Oficina',
    NomePlano.rede: 'Rede',
  };

  static const _descricoes = {
    NomePlano.solo: 'Para uma oficina só',
    NomePlano.oficina: 'Operação completa do dia a dia',
    NomePlano.rede: 'Para rede com mais de uma unidade',
  };

  String get _nomePlano => _nomes[plano] ?? plano.name;
  String get _descPlano => _descricoes[plano] ?? '';
  String get _cicloLabel => ciclo == CicloCobranca.mensal ? 'mês' : 'ano';
  String get _precoFmt {
    final parts = preco.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  String get _mensagemWhatsapp =>
      'Olá! Tenho interesse em contratar o plano *$_nomePlano* do GAMA '
      '($_precoFmt/$_cicloLabel). Pode me ajudar com a contratação?';

  void _abrirWhatsApp() {
    final msg = Uri.encodeComponent(_mensagemWhatsapp);
    final uri = Uri.parse('https://wa.me/$_kWhatsappNumber?text=$msg');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              child: Icon(Icons.workspace_premium_outlined,
                  color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPGRADE DE PLANO',
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
                  'Fale com a gente',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ativamos seu plano em minutos via WhatsApp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.sidebarText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F5F0),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card do plano selecionado
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.accent, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.star_outline_rounded,
                        color: AppColors.accentDark, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano $_nomePlano',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _descPlano,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _precoFmt,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '/$_cicloLabel',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Mensagem pré-pronta
          Text(
            'MENSAGEM QUE SERÁ ENVIADA',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEAE4DC)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _mensagemWhatsapp,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botão WhatsApp
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _abrirWhatsApp();
              },
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text(
                'Abrir no WhatsApp',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Copiar mensagem
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _mensagemWhatsapp));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mensagem copiada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_outlined, size: 14),
              label: const Text('Copiar mensagem'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink3,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
