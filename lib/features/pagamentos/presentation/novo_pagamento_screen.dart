import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../data/pagamentos_remote_data_source.dart';
import '../../funcionarios/domain/remuneracao.dart';
import '../domain/pagamento.dart';
import 'pagamento_detalhe_screen.dart';
import 'pagamentos_notifier.dart';

class NovoPagamentoScreen extends ConsumerStatefulWidget {
  const NovoPagamentoScreen({super.key, required this.funcionario});
  final FuncionarioAcumulado funcionario;

  @override
  ConsumerState<NovoPagamentoScreen> createState() => _NovoPagamentoScreenState();
}

class _NovoPagamentoScreenState extends ConsumerState<NovoPagamentoScreen> {
  final Set<int> _selecionadas = {};
  bool _gerando = false;

  FuncionarioAcumulado get f => widget.funcionario;

  bool get _ehFixo => f.tipoRemuneracao == 'Fixo';

  double _calcularTotal(List<OsAberta> os) {
    if (_ehFixo) return f.valorAcumulado;
    return os
        .where((o) => _selecionadas.contains(o.ordemServicoId))
        .fold(0.0, (sum, o) => sum + o.valorContribuicao);
  }

  Future<void> _gerar(List<OsAberta> osAbertas) async {
    if (_selecionadas.isEmpty && !_ehFixo) {
      GamaSnackBar.error(context, 'Selecione ao menos uma OS.');
      return;
    }
    setState(() => _gerando = true);
    try {
      final ids = _ehFixo
          ? osAbertas.map((o) => o.ordemServicoId).toList()
          : _selecionadas.toList();

      final id = await ref
          .read(pagamentosRemoteDataSourceProvider)
          .criar(f.funcionarioId, ids);

      ref.invalidate(pagamentosNotifierProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PagamentoDetalheScreen(pagamentoId: id)),
      );
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao gerar pagamento.');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(osAbertasProvider(f.funcionarioId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Pagamento · ${f.nome}'),
        backgroundColor: AppColors.sidebarBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: osAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro ao carregar OS: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (osAbertas) {
          if (osAbertas.isEmpty && !_ehFixo) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text('Nenhuma OS em aberto', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          // Inicializa todas selecionadas na primeira vez
          if (_selecionadas.isEmpty && osAbertas.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selecionadas.addAll(osAbertas.map((o) => o.ordemServicoId)));
            });
          }

          final total = _calcularTotal(osAbertas);

          return Column(
            children: [
              // Header com info do funcionário
              _HeaderFuncionario(funcionario: f),

              // Lista de OS
              Expanded(
                child: _ehFixo
                    ? _ListaOsFixo(osAbertas: osAbertas)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: osAbertas.length,
                        itemBuilder: (_, i) {
                          final os = osAbertas[i];
                          final selecionada = _selecionadas.contains(os.ordemServicoId);
                          return _OsCheckTile(
                            os: os,
                            selecionada: selecionada,
                            tipoRemuneracao: f.tipoRemuneracao,
                            onToggle: (v) => setState(() {
                              if (v) {
                                _selecionadas.add(os.ordemServicoId);
                              } else {
                                _selecionadas.remove(os.ordemServicoId);
                              }
                            }),
                          );
                        },
                      ),
              ),

              // Rodapé com total e botão
              _Rodape(
                total: total,
                selecionadasCount: _ehFixo ? osAbertas.length : _selecionadas.length,
                loading: _gerando,
                onGerar: () => _gerar(osAbertas),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderFuncionario extends StatelessWidget {
  const _HeaderFuncionario({required this.funcionario});
  final FuncionarioAcumulado funcionario;

  String get _tipoLabel => tipoRemuneracaoPagamentoDesc(
        funcionario.tipoRemuneracao,
        porcentagem: funcionario.porcentagem?.toInt(),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: AppColors.sidebarBg,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(_tipoLabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ListaOsFixo extends StatelessWidget {
  const _ListaOsFixo({required this.osAbertas});
  final List<OsAberta> osAbertas;

  @override
  Widget build(BuildContext context) {
    if (osAbertas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nenhuma OS no período.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: osAbertas.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => _OsInfoTile(os: osAbertas[i]),
    );
  }
}

class _OsCheckTile extends StatelessWidget {
  const _OsCheckTile({
    required this.os,
    required this.selecionada,
    required this.tipoRemuneracao,
    required this.onToggle,
  });

  final OsAberta os;
  final bool selecionada;
  final String tipoRemuneracao;
  final ValueChanged<bool> onToggle;

  String get _dataFormatada {
    final d = os.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selecionada,
      onChanged: (v) => onToggle(v ?? false),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        os.clienteNome,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(os.veiculoInfo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(_dataFormatada, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'R\$ ${os.valorContribuicao.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selecionada ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          Text(
            'de R\$ ${os.totalOS.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OsInfoTile extends StatelessWidget {
  const _OsInfoTile({required this.os});
  final OsAberta os;

  String get _dataFormatada {
    final d = os.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        os.clienteNome,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(os.veiculoInfo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(_dataFormatada, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
      trailing: Text(
        'R\$ ${os.totalOS.toStringAsFixed(2).replaceAll('.', ',')}',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.total,
    required this.selecionadasCount,
    required this.loading,
    required this.onGerar,
  });

  final double total;
  final int selecionadasCount;
  final bool loading;
  final VoidCallback onGerar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selecionadasCount OS selecionadas',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: loading ? null : onGerar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Gerar pagamento', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
