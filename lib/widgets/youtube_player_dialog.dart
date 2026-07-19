import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubePlayerDialog extends StatefulWidget {
  final String exerciseName;
  final String videoUrl;

  const YoutubePlayerDialog({
    super.key,
    required this.exerciseName,
    required this.videoUrl,
  });

  static void show(BuildContext context, String exerciseName, String videoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => YoutubePlayerDialog(
        exerciseName: exerciseName,
        videoUrl: videoUrl,
      ),
    );
  }

  /// Extrait l'ID de la vidéo YouTube depuis différentes formes d'URL
  static String? extractVideoId(String url) {
    return YoutubePlayerController.convertUrlToId(url);
  }

  @override
  State<YoutubePlayerDialog> createState() => _YoutubePlayerDialogState();
}

class _YoutubePlayerDialogState extends State<YoutubePlayerDialog> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayerDialog.extractVideoId(widget.videoUrl);
    if (_videoId != null && _videoId!.isNotEmpty) {
      try {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: _videoId!,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            showVideoAnnotations: false,
          ),
        );
      } catch (e) {
        debugPrint("WebView iframe non disponible sur cette plateforme : $e");
        _controller = null;
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  Future<void> _openInExternalApp() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le lien vidéo.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        color: theme.colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xff1e293b),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Video Player Body
            if (_controller != null)
              YoutubePlayer(
                controller: _controller!,
                aspectRatio: 16 / 9,
              )
            else if (_videoId != null && _videoId!.isNotEmpty)
              InkWell(
                onTap: _openInExternalApp,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 220,
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(Icons.video_library, size: 64, color: Colors.white54),
                        ),
                      ),
                    ),
                    Container(
                      height: 220,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Regarder la vidéo sur YouTube",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.black12,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        "Format de vidéo non reconnu",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.videoUrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openInExternalApp,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text("Ouvrir dans YouTube"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Fermer"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
