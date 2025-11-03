import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;
  final bool showControls;
  final bool autoPlay;
  final VoidCallback? onVideoEnd;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    this.showControls = true,
    this.autoPlay = true,
    this.onVideoEnd,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  String? _currentSubtitle;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Для YouTube видео используем YouTube плеер
      if (widget.video.source == 'YouTube') {
        _initializeYouTubePlayer();
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );

      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 10),
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        aspectRatio: 9 / 16,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget('Ошибка воспроизведения видео');
        },
      );

      // Listen to video position for subtitles
      _videoPlayerController!.addListener(_updateSubtitle);
      
      // Listen for video end
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.position >= 
            _videoPlayerController!.value.duration) {
          widget.onVideoEnd?.call();
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video: $e');
      _showThumbnailFallback();
    }
  }

  void _initializeYouTubePlayer() {
    try {
      debugPrint('Initializing YouTube player for: ${widget.video.videoUrl}');
      final videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);
      debugPrint('Extracted video ID: $videoId');
      
      if (videoId != null && videoId.isNotEmpty) {
        // Инициализируем YouTube плеер
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
            showLiveFullscreenButton: false,
          ),
        );
        
        setState(() {
          _isInitialized = true;
        });
        
        debugPrint('YouTube player initialized successfully');
      } else {
        debugPrint('Could not extract video ID, falling back to thumbnail');
        _showThumbnailFallback();
      }
    } catch (e) {
      debugPrint('Error initializing YouTube player: $e');
      _showThumbnailFallback();
    }
  }

  void _showThumbnailFallback() {
    setState(() {
      _isInitialized = true;
    });
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Попробовать открыть в браузере
              _openInBrowser();
            },
            child: const Text('Открыть в браузере'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.video.sourceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch ${widget.video.sourceUrl}');
      }
    } catch (e) {
      debugPrint('Error opening video in browser: $e');
    }
  }

  void _updateSubtitle() {
    if (widget.video.subtitles == null || widget.video.subtitles!.isEmpty || _videoPlayerController == null) {
      return;
    }

    final position = _videoPlayerController!.value.position.inMilliseconds;
    
    for (var subtitle in widget.video.subtitles!) {
      if (position >= subtitle.startTime && position <= subtitle.endTime) {
        if (_currentSubtitle != subtitle.text) {
          setState(() {
            _currentSubtitle = subtitle.text;
          });
        }
        return;
      }
    }

    if (_currentSubtitle != null) {
      setState(() {
        _currentSubtitle = null;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_updateSubtitle);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Для YouTube видео используем YouTube плеер
    if (widget.video.source == 'YouTube') {
      if (_youtubeController != null) {
        return YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          topActions: <Widget>[
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                widget.video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          onReady: () {
            debugPrint('YouTube player is ready');
          },
          onEnded: (data) {
            debugPrint('YouTube video ended');
            widget.onVideoEnd?.call();
          },
        );
      } else {
        return _buildYouTubeThumbnail();
      }
    }

    // Для других видео используем обычный плеер
    if (_chewieController == null) {
      return _buildErrorWidget('Не удалось загрузить видео');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Chewie(controller: _chewieController!),
        
        // Subtitles overlay
        if (_currentSubtitle != null)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentSubtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildYouTubeThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail image with CORS-safe approach
        _buildSafeThumbnail(),
        
        // Play button overlay
        Center(
          child: GestureDetector(
            onTap: _openInBrowser,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
        
        // YouTube badge
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'YouTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeThumbnail() {
    // Используем собственный thumbnail вместо автоматического
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.red,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'YouTube Video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to open in YouTube',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Open in YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

