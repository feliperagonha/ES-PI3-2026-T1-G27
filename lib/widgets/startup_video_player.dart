import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const _purple600 = Color(0xFF6A4CFF);
const _textSecondary = Color(0xFF6B7280);

class StartupVideoPlayer extends StatefulWidget {
  final String videoPath;

  const StartupVideoPlayer({super.key, required this.videoPath});

  @override
  State<StartupVideoPlayer> createState() => _StartupVideoPlayerState();
}

class _StartupVideoPlayerState extends State<StartupVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant StartupVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _controller?.dispose();
      _controller = null;
      _loading = true;
      _errorMessage = null;
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    final source = widget.videoPath.trim();

    if (source.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Video nao informado.';
      });
      return;
    }

    try {
      final url = await _resolveVideoUrl(source);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));

      await controller.initialize();
      controller.addListener(_refreshPlayerState);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Nao foi possivel carregar o video.';
      });
    }
  }

  Future<String> _resolveVideoUrl(String source) async {
    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return source;
    }

    return FirebaseStorage.instance.ref(source).getDownloadURL();
  }

  void _refreshPlayerState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _VideoFrame(
        child: const Center(
          child: CircularProgressIndicator(color: _purple600),
        ),
      );
    }

    if (_errorMessage != null) {
      return _VideoFrame(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return _VideoFrame(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: _purple600,
                bufferedColor: Color(0x99FFFFFF),
                backgroundColor: Color(0x33000000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StartupVideoDialog extends StatelessWidget {
  final String startupName;
  final String videoPath;

  const StartupVideoDialog({
    super.key,
    required this.startupName,
    required this.videoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    startupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StartupVideoPlayer(videoPath: videoPath),
            const SizedBox(height: 8),
            const Text(
              'Video demonstrativo da startup',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoFrame extends StatelessWidget {
  final Widget child;

  const _VideoFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 190),
        color: Colors.black,
        child: AspectRatio(aspectRatio: 16 / 9, child: child),
      ),
    );
  }
}
