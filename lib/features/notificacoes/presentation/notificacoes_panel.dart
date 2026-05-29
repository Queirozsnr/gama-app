import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/notificacao.dart';
import 'notificacoes_notifier.dart';

// Maps TipoNotificacao string to a GoRouter path (with id substituted)
String? _rotaPara(Notificacao n) {
  final id = n.referenciaId;
  return switch (n.tipo) {
    'PagamentoRegistrado' => id != null ? '/pagamentos' : null,
    'VeiculoAtribuido'    => id != null
        ? AppRoutes.ordensServicoDetalhe.replaceFirst(':id', '$id')
        : null,
    'EstoqueCritico'      => id != null
        ? AppRoutes.estoqueProdutoDetalhe.replaceFirst(':id', '$id')
        : null,
    _                     => null,
  };
}

IconData _icone(String tipo) => switch (tipo) {
      'PagamentoRegistrado' => Icons.payments_outlined,
      'VeiculoAtribuido'    => Icons.directions_car_outlined,
      'EstoqueCritico'      => Icons.warning_amber_rounded,
      _                     => Icons.notifications_outlined,
    };

Color _cor(String tipo) => switch (tipo) {
      'PagamentoRegistrado' => AppColors.ok,
      'VeiculoAtribuido'    => AppColors.accent,
      'EstoqueCritico'      => AppColors.danger,
      _                     => AppColors.ink2,
    };

class NotificacoesPanel extends ConsumerWidget {
  const NotificacoesPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacoesNotifierProvider);
    final notifier = ref.read(notificacoesNotifierProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 800;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMobile) ...[
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              const Text(
                'Notificações',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: () => notifier.marcarTodasLidas(),
                child: const Text('Marcar todas como lidas'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        // List
        Flexible(
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Erro ao carregar notificações.')),
            ),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nenhuma notificação',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: lista.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.line),
                itemBuilder: (ctx, i) => _NotificacaoTile(
                  item: lista[i],
                  onTap: () {
                    notifier.marcarLida(lista[i].id);
                    final rota = _rotaPara(lista[i]);
                    onClose?.call();
                    if (rota != null && ctx.mounted) {
                      ctx.go(rota);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (isMobile)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );

    if (isMobile) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: content,
      );
    }

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _NotificacaoTile extends StatelessWidget {
  const _NotificacaoTile({required this.item, required this.onTap});
  final Notificacao item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = _cor(item.tipo);
    final local = item.criadaEm.toLocal();
    final hora =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.lida ? null : AppColors.accentSoft.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icone(item.tipo), size: 18, color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight:
                                item.lida ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hora,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.corpo,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ink2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!item.lida) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
