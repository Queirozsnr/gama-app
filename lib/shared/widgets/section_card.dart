import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Card container usado para tabelas e seções de conteúdo.
/// Aplica border + borderRadius + clipBehavior padronizados.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// Título opcional no topo do card (ex.: "Identidade do veículo").
  final String? title;

  /// Subtítulo abaixo do título.
  final String? subtitle;

  /// Widget de ação no canto superior direito (ex.: botão "Ver todas").
  final Widget? action;

  /// Padding interno aplicado ao [child]. Padrão: zero (tabelas não precisam).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink2,
                          ),
                        ),
                      ],
                    ],
                  ),
                  ?action,
                ],
              ),
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
