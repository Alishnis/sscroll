import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../providers/user_provider.dart';
import 'video_player_widget.dart';

class VideoFeedItem extends StatefulWidget {
  final VideoModel video;
  final bool isVisible;

  const VideoFeedItem({
    super.key,
    required this.video,
    required this.isVisible,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  bool _showSummary = false;
  String? _summary;
  bool _isLoadingSummary = false;
  bool _isLiked = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    final videoProvider = context.read<VideoProvider>();
    final summary = await videoProvider.generateSummary(widget.video.id);

    setState(() {
      _summary = summary;
      _isLoadingSummary = false;
      _showSummary = true;
    });
  }

  Future<void> _openSource() async {
    final uri = Uri.parse(widget.video.sourceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isAccessibilityMode = userProvider.currentUser?.isAccessibilityEnabled ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        VideoPlayerWidget(
          video: widget.video,
          autoPlay: widget.isVisible,
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        // Content overlay
        Positioned(
          left: 16,
          right: 80,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Author and source
              Row(
                children: [
                  Text(
                    widget.video.author,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.video.source,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                widget.video.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags
              Wrap(
                spacing: 8,
                children: widget.video.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Action buttons (right side)
        Positioned(
          right: 12,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like button
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: _formatNumber(widget.video.likes),
                color: _isLiked ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                  });
                  context.read<VideoProvider>().likeVideo(widget.video.id);
                },
              ),
              const SizedBox(height: 20),
              
              // Summary button
              _ActionButton(
                icon: Icons.summarize,
                label: 'Краткое',
                onTap: _loadSummary,
              ),
              const SizedBox(height: 20),
              
              // Source link button
              _ActionButton(
                icon: Icons.link,
                label: 'Источник',
                onTap: _openSource,
              ),
              const SizedBox(height: 20),
              
              // Share button
              _ActionButton(
                icon: Icons.share,
                label: 'Поделиться',
                onTap: () {
                  // Share functionality
                },
              ),
              
              // Accessibility button
              if (isAccessibilityMode) ...[
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.record_voice_over,
                  label: 'Озвучить',
                  onTap: () {
                    _speak(
                      '${widget.video.title}. ${widget.video.description}. '
                      'Автор: ${widget.video.author}. Источник: ${widget.video.source}'
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // Summary overlay
        if (_showSummary)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSummary = false;
                });
                _stop();
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.summarize, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Краткое содержание',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (isAccessibilityMode)
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => _speak(_summary ?? ''),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showSummary = false;
                                });
                                _stop();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoadingSummary
                            ? const CircularProgressIndicator()
                            : Text(
                                _summary ?? widget.video.summary ?? '',
                                style: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

