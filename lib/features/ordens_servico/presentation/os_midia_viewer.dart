import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/os_midia.dart';

void showMidiaViewer(
  BuildContext context,
  List<OsMidia> midias,
  int initialIndex,
  String baseUrl, {
  Future<bool> Function(OsMidia)? onDelete,
}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => _MidiaViewerScreen(
      midias: midias,
      initialIndex: initialIndex,
      baseUrl: baseUrl,
      onDelete: onDelete,
    ),
  ));
}

class _MidiaViewerScreen extends StatefulWidget {
  const _MidiaViewerScreen({
    required this.midias,
    required this.initialIndex,
    required this.baseUrl,
    this.onDelete,
  });

  final List<OsMidia> midias;
  final int initialIndex;
  final String baseUrl;
  final Future<bool> Function(OsMidia)? onDelete;

  @override
  State<_MidiaViewerScreen> createState() => _MidiaViewerScreenState();
}

class _MidiaViewerScreenState extends State<_MidiaViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<OsMidia> _midias;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _midias = List.from(widget.midias);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  Future<void> _deleteCurrentItem() async {
    if (widget.onDelete == null) return;
    final midia = _midias[_currentIndex];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Remover mídia',
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Remover esta ${midia.isVideo ? 'vídeo' : 'foto'}?',
          style: const TextStyle(color: AppColors.ink2, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.ink2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await widget.onDelete!(midia);
    if (!success || !mounted) return;

    setState(() {
      _midias.removeAt(_currentIndex);
      if (_midias.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      if (_currentIndex >= _midias.length) {
        _currentIndex = _midias.length - 1;
      }
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_midias.isEmpty) return const SizedBox.shrink();
    final midia = _midias[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Conteúdo principal — ocupa tela toda
            PageView.builder(
              controller: _pageController,
              itemCount: _midias.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                _scheduleHide();
              },
              itemBuilder: (ctx, i) {
                final m = _midias[i];
                if (m.isVideo) {
                  return _VideoPage(
                    url: '${widget.baseUrl}${m.url}',
                    active: i == _currentIndex,
                  );
                }
                return PhotoView(
                  imageProvider: NetworkImage('${widget.baseUrl}${m.url}'),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                  loadingBuilder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  errorBuilder: (ctx2, e, st) => const Center(
                    child:
                        Icon(Icons.broken_image, color: Colors.white24, size: 64),
                  ),
                );
              },
            ),

            // Controles superiores (voltar, índice, tipo)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xBB000000), Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_midias.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: midia.isVideo
                                  ? Colors.white12
                                  : AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              midia.isVideo ? 'VÍDEO' : 'FOTO',
                              style: TextStyle(
                                color: midia.isVideo
                                    ? Colors.white54
                                    : AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Controles inferiores (botão de excluir)
            if (widget.onDelete != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xBB000000), Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 26),
                                tooltip: 'Remover',
                                onPressed: _deleteCurrentItem,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Video page ────────────────────────────────────────────────────────────────

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.url, required this.active});

  final String url;
  final bool active;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final vpc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await vpc.initialize();
      _vpc = vpc;
      _chewie = ChewieController(
        videoPlayerController: vpc,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        placeholder: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void didUpdateWidget(_VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _vpc?.pause();
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: Colors.white24, size: 64),
            SizedBox(height: 12),
            Text('Não foi possível carregar o vídeo.',
                style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    return Center(child: Chewie(controller: _chewie!));
  }
}
