import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_item_model.dart';
import '../providers/feed_provider.dart';
import '../services/image_proxy_service.dart';
import 'video_player_widget.dart';

class MixedFeedItem extends StatefulWidget {
  final FeedItemModel feedItem;
  final bool isVisible;

  const MixedFeedItem({
    super.key,
    required this.feedItem,
    required this.isVisible,
  });

  @override
  State<MixedFeedItem> createState() => _MixedFeedItemState();
}

class _MixedFeedItemState extends State<MixedFeedItem> {
  bool _isLiked = false;
  bool _showSummary = false;
  String? _summary;
  bool _isLoadingSummary = false;

  Future<void> _openSource() async {
    if (widget.feedItem.sourceUrl.isNotEmpty) {
      final uri = Uri.parse(widget.feedItem.sourceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _loadSummary() async {
    if (!widget.feedItem.isVideo) return;
    
    setState(() {
      _isLoadingSummary = true;
    });

    // В реальном приложении здесь был бы вызов AI сервиса
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _summary = 'Это краткое содержание видео, сгенерированное с помощью AI. '
          'Видео рассказывает о ${widget.feedItem.title.toLowerCase()}.';
      _isLoadingSummary = false;
      _showSummary = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content based on type
        if (widget.feedItem.isVideo)
          _buildVideoContent()
        else
          _buildPostContent(),

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
              // Type and category badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.feedItem.isVideo 
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.blue.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.feedItem.isVideo ? 'Видео' : 'Пост',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.feedItem.category == 'educational' || 
                             widget.feedItem.category == 'Образование'
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.feedItem.category == 'educational' || 
                      widget.feedItem.category == 'Образование'
                          ? 'Образование' 
                          : 'Развлечение',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Title
              Text(
                widget.feedItem.title,
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
                    widget.feedItem.author,
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
                      widget.feedItem.source,
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
                widget.feedItem.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags
              if (widget.feedItem.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: widget.feedItem.tags.take(3).map((tag) {
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
                label: _formatNumber(widget.feedItem.likes),
                color: _isLiked ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                  });
                  context.read<FeedProvider>().likeItem(widget.feedItem.id);
                },
              ),
              const SizedBox(height: 20),
              
              // Summary button (only for videos)
              if (widget.feedItem.isVideo) ...[
                _ActionButton(
                  icon: Icons.summarize,
                  label: 'Краткое',
                  onTap: _loadSummary,
                ),
                const SizedBox(height: 20),
              ],
              
              // Engagement button
              _ActionButton(
                icon: widget.feedItem.isVideo ? Icons.visibility : Icons.comment_outlined,
                label: _formatNumber(widget.feedItem.engagement),
                onTap: () {
                  // Show engagement details
                },
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
            ],
          ),
        ),

        // Summary overlay (only for videos)
        if (_showSummary && widget.feedItem.isVideo)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSummary = false;
                });
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
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showSummary = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoadingSummary
                            ? const CircularProgressIndicator()
                            : Text(
                                _summary ?? '',
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

  Widget _buildVideoContent() {
    return VideoPlayerWidget(
      video: widget.feedItem.video!,
      autoPlay: widget.isVisible,
    );
  }

  Widget _buildPostContent() {
    return Container(
      color: Colors.black,
      child: widget.feedItem.thumbnailUrl != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _showImageFullscreen(context),
                  child: Image.network(
                    _fixRedditImageUrl(widget.feedItem.thumbnailUrl!),
                    fit: BoxFit.cover,
                    headers: {
                      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                      'Referer': 'https://www.reddit.com/',
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Only log 404 errors in debug mode, not all errors
                      if (error.toString().contains('404')) {
                        debugPrint('Image not available (404): ${widget.feedItem.post?.title}');
                      }
                      return _buildFallbackContent();
                    },
                  ),
                ),
                // Добавляем индикатор, что это изображение
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Фото',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _buildFallbackContent(),
    );
  }

  Widget _buildFallbackContent() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.feedItem.isVideo ? Icons.play_circle_outline : Icons.article_outlined,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              widget.feedItem.category == 'educational' ? 'Образование' : 'Развлечение',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fixRedditImageUrl(String url) {
    // Используем прокси сервис для обхода блокировки
    return ImageProxyService.getProxiedImageUrl(url);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showImageFullscreen(BuildContext context) {
    if (widget.feedItem.thumbnailUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Полноэкранное изображение
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  _fixRedditImageUrl(widget.feedItem.thumbnailUrl!),
                  fit: BoxFit.contain,
                  headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    'Referer': 'https://www.reddit.com/',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Не удалось загрузить изображение',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Кнопка закрытия
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Информация о посте
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feedItem.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'r/${widget.feedItem.post?.subreddit ?? 'unknown'} • u/${widget.feedItem.author}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
