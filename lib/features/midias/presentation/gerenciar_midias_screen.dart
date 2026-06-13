import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_download.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../ordens_servico/domain/os_midia.dart';
import '../../ordens_servico/presentation/os_midia_viewer.dart';
import '../data/midias_remote_data_source.dart';
import '../domain/midia_global.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmtBytes(int bytes) {
  if (bytes == 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

// ── Screen ────────────────────────────────────────────────────────────────────

class GerenciarMidiasScreen extends ConsumerStatefulWidget {
  const GerenciarMidiasScreen({super.key});

  @override
  ConsumerState<GerenciarMidiasScreen> createState() =>
      _GerenciarMidiasScreenState();
}

class _GerenciarMidiasScreenState
    extends ConsumerState<GerenciarMidiasScreen>
    with TopBarSlotMixin<GerenciarMidiasScreen> {
  String? _tipo; // null = todas | 'Imagem' | 'Video'
  final List<MidiaGlobal> _items = [];
  int _total = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _downloading = false;
  int _page = 1;
  final Set<int> _selected = {}; // IDs dos itens selecionados
  final ScrollController _scrollCtrl = ScrollController();

  bool get _selectMode => _selected.isNotEmpty;
  int get _selectedBytes => _items
      .where((m) => _selected.contains(m.id))
      .fold(0, (s, m) => s + m.tamanhoBytes);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTopBar();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _items.clear();
      _selected.clear();
      _page = 1;
    });
    _updateTopBar();
    try {
      final result = await ref
          .read(midiasRemoteDataSourceProvider)
          .listar(tipo: _tipo, page: 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
      });
      _updateTopBar();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      GamaSnackBar.error(context, 'Erro ao carregar mídias.');
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await ref
          .read(midiasRemoteDataSourceProvider)
          .listar(tipo: _tipo, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _total = result.total;
        _hasMore = result.hasMore;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setTipo(String? tipo) {
    if (_tipo == tipo) return;
    setState(() => _tipo = tipo);
    _load();
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    _updateTopBar();
  }

  void _clearSelect() {
    setState(() => _selected.clear());
    _updateTopBar();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected.addAll(_items.map((m) => m.id));
      }
    });
    _updateTopBar();
  }

  void _updateTopBar() {
    if (_selectMode) {
      setTopBarSlot(TopBarSlot(
        pageTitle:
            '${_selected.length} selecionado${_selected.length == 1 ? '' : 's'}',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedBytes > 0)
              Text(
                _fmtBytes(_selectedBytes),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: AppColors.ink2,
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Cancelar seleção',
              onPressed: _clearSelect,
            ),
          ],
        ),
        mobileStyle: MobileTopBarStyle.light,
        mobileAction: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: _clearSelect,
        ),
      ));
    } else {
      setTopBarSlot(TopBarSlot(
        pageTitle: 'Fotos e Vídeos',
        desktopSubtitle:
            _total > 0 ? '$_total arquivo${_total == 1 ? '' : 's'}' : null,
        mobileStyle: MobileTopBarStyle.light,
      ));
    }
  }

  void _openViewer(int startIndex) {
    final midias = _items
        .map((m) => OsMidia(
              id: m.id,
              url: m.url,
              tipo: m.tipo,
              criadoPorNome: m.criadoPorNome,
              criadoEm: m.criadoEm,
            ))
        .toList();

    showMidiaViewer(
      context,
      midias,
      startIndex,
      kBaseUrl,
      onDelete: (midia) async {
        try {
          await ref
              .read(midiasRemoteDataSourceProvider)
              .bulkDelete([midia.id]);
          if (mounted) {
            setState(() {
              _items.removeWhere((m) => m.id == midia.id);
              _total = (_total - 1).clamp(0, _total);
            });
            _updateTopBar();
          }
          return true;
        } catch (_) {
          return false;
        }
      },
    );
  }

  Future<void> _excluirSelecionados() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir mídias',
      message:
          'Excluir $count ${count == 1 ? 'mídia selecionada' : 'mídias selecionadas'}? '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.danger,
    );
    if (!ok || !mounted) return;
    await _excluirIds(_selected.toList());
  }

  Future<void> _excluirIds(List<int> ids) async {
    try {
      await ref.read(midiasRemoteDataSourceProvider).bulkDelete(ids);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((m) => ids.contains(m.id));
        _total = (_total - ids.length).clamp(0, _total);
        _selected.removeAll(ids);
      });
      _updateTopBar();
      GamaSnackBar.success(
          context,
          '${ids.length} '
          '${ids.length == 1 ? 'mídia excluída' : 'mídias excluídas'}.');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao excluir mídias.');
    }
  }

  Future<void> _baixarZip() async {
    if (_selected.isEmpty || _downloading) return;
    setState(() => _downloading = true);
    try {
      final ids = _selected.toList();
      final bytes =
          await ref.read(midiasRemoteDataSourceProvider).baixarZip(ids);

      final filename = 'midias_gama_${DateTime.now().millisecondsSinceEpoch}.zip';
      await downloadAndOpenZip(bytes, filename);

      if (!mounted) return;
      final liberar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          title: const Text('Liberar espaço?',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          content: const Text(
            'O ZIP foi salvo. Deseja excluir essas mídias do servidor para liberar espaço?',
            style: TextStyle(color: AppColors.ink2, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter',
                  style: TextStyle(color: AppColors.ink2)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir do servidor',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (liberar == true && mounted) {
        await _excluirIds(ids);
      }
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao gerar arquivo ZIP.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final cols = isDesktop ? 5 : 2;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FilterStrip(tipo: _tipo, total: _total, onChanged: _setTipo),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent))
                  : _items.isEmpty
                      ? _EmptyState(tipo: _tipo)
                      : GridView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount:
                              _items.length + (_loadingMore ? cols : 0),
                          itemBuilder: (ctx, i) {
                            if (i >= _items.length) {
                              return i == _items.length
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            final m = _items[i];
                            return _MidiaTile(
                              midia: m,
                              selected: _selected.contains(m.id),
                              selectMode: _selectMode,
                              onTap: () => _selectMode
                                  ? _toggleSelect(m.id)
                                  : _openViewer(i),
                              onLongPress: () {
                                if (!_selectMode) _toggleSelect(m.id);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),

        // Barra de ações de seleção
        if (_selectMode)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _SelectionBar(
              count: _selected.length,
              totalBytes: _selectedBytes,
              downloading: _downloading,
              allSelected: _selected.length >= _items.length,
              onToggleAll: _toggleSelectAll,
              onDownload: _baixarZip,
              onDelete: _excluirSelecionados,
            ),
          ),
      ],
    );
  }
}

// ── Filter strip ──────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.tipo,
    required this.total,
    required this.onChanged,
  });

  final String? tipo;
  final int total;
  final void Function(String?) onChanged;

  Widget _chip(String? value, String label, String? current) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.sidebarBg : AppColors.ink2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _chip(null, 'Todas', tipo),
          const SizedBox(width: 8),
          _chip('Imagem', 'Fotos', tipo),
          const SizedBox(width: 8),
          _chip('Video', 'Vídeos', tipo),
          const Spacer(),
          if (total > 0)
            Text(
              '$total arquivo${total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: AppColors.ink3),
            ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _MidiaTile extends StatelessWidget {
  const _MidiaTile({
    required this.midia,
    required this.selected,
    required this.selectMode,
    required this.onTap,
    required this.onLongPress,
  });

  final MidiaGlobal midia;
  final bool selected;
  final bool selectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail / placeholder
            if (!midia.isVideo)
              Image.network(
                '$kBaseUrl${midia.url}',
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const ColoredBox(
                        color: AppColors.surface2,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent),
                          ),
                        ),
                      ),
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surface2,
                  child: Icon(Icons.broken_image,
                      color: AppColors.ink3, size: 28),
                ),
              )
            else
              const ColoredBox(
                color: Color(0xFF131320),
                child: Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white24, size: 38),
                ),
              ),

            // Seleção — tint âmbar
            if (selected)
              ColoredBox(
                  color: AppColors.accent.withValues(alpha: 0.25)),

            // Gradiente inferior com OS + data
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OS #${midia.osId}',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _fmtDate(midia.criadoEm),
                        style: const TextStyle(
                            fontSize: 8.5, color: Color(0x73ffffff)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Badge de vídeo
            if (midia.isVideo)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VID',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 8.5,
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Checkbox de seleção
            if (selectMode)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.accent : Colors.black38,
                    border: Border.all(
                      color:
                          selected ? AppColors.accent : Colors.white54,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          size: 13, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Selection action bar ──────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.totalBytes,
    required this.downloading,
    required this.allSelected,
    required this.onToggleAll,
    required this.onDownload,
    required this.onDelete,
  });

  final int count;
  final int totalBytes;
  final bool downloading;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Row(
        children: [
          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count selecionado${count == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
              ),
              if (totalBytes > 0)
                Text(
                  _fmtBytes(totalBytes),
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onToggleAll,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8)),
            child: Text(
              allSelected ? 'Desmarcar todos' : 'Todos',
              style: const TextStyle(fontSize: 12, color: AppColors.ink2),
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: downloading ? null : onDownload,
            icon: downloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  )
                : const Icon(Icons.download_outlined, size: 16),
            label: const Text('Baixar ZIP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Excluir'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.tipo});
  final String? tipo;

  @override
  Widget build(BuildContext context) {
    final label = tipo == 'Imagem'
        ? 'fotos'
        : tipo == 'Video'
            ? 'vídeos'
            : 'mídias';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.perm_media_outlined,
              size: 52, color: AppColors.ink3),
          const SizedBox(height: 12),
          Text(
            'Nenhuma $label encontrada',
            style: const TextStyle(fontSize: 14, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}
