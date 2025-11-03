import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../services/image_proxy_service.dart';
import '../providers/post_provider.dart';

class PostFeedItem extends StatefulWidget {
  final PostModel post;
  final bool isVisible;

  const PostFeedItem({
    super.key,
    required this.post,
    required this.isVisible,
  });

  @override
  State<PostFeedItem> createState() => _PostFeedItemState();
}

class _PostFeedItemState extends State<PostFeedItem> {
  bool _isLiked = false;
  bool _showFullContent = false;

  Future<void> _openSource() async {
    if (widget.post.displayUrl.isNotEmpty) {
      final uri = Uri.parse(widget.post.displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(
          color: Colors.black,
          child: _buildPostBackground(),
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
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.3, 1.0],
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
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.post.category == 'educational' 
                      ? Colors.blue.withValues(alpha: 0.8)
                      : Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.post.category == 'educational' ? 'Образование' : 'Развлечение',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Title
              Text(
                widget.post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: _showFullContent ? null : 2,
                overflow: _showFullContent ? null : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Author and subreddit
              Row(
                children: [
                  Text(
                    'u/${widget.post.author}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'r/${widget.post.subreddit}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Content
              if (widget.post.content != null && widget.post.content!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullContent = !_showFullContent;
                    });
                  },
                  child: Text(
                    widget.post.content!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    maxLines: _showFullContent ? null : 3,
                    overflow: _showFullContent ? null : TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              
              // Tags
              if (widget.post.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: widget.post.tags.take(3).map((tag) {
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
                label: _formatNumber(widget.post.score),
                color: _isLiked ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                  });
                  context.read<PostProvider>().likePost(widget.post.id);
                },
              ),
              const SizedBox(height: 20),
              
              // Comments button
              _ActionButton(
                icon: Icons.comment_outlined,
                label: _formatNumber(widget.post.numComments),
                onTap: () {
                  // Navigate to comments
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

        // Video indicator
        if (widget.post.hasVideo)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPostBackground() {
    // Проверяем различные источники изображений
    String? imageUrl;
    
    // 1. Пробуем videoThumbnail (лучшее качество)
    if (widget.post.videoThumbnail != null && 
        widget.post.videoThumbnail!.isNotEmpty &&
        widget.post.videoThumbnail != 'self' &&
        widget.post.videoThumbnail != 'default' &&
        widget.post.videoThumbnail != 'nsfw') {
      imageUrl = _fixRedditImageUrl(widget.post.videoThumbnail!);
    }
    // 2. Пробуем thumbnail
    else if (widget.post.thumbnail != null && 
             widget.post.thumbnail!.isNotEmpty &&
             widget.post.thumbnail != 'self' &&
             widget.post.thumbnail != 'default' &&
             widget.post.thumbnail != 'nsfw') {
      imageUrl = _fixRedditImageUrl(widget.post.thumbnail!);
    }
    // 3. Пробуем URL поста (если это изображение)
    else if (widget.post.url != null && 
             widget.post.url!.isNotEmpty &&
             _isImageUrl(widget.post.url!)) {
      imageUrl = _fixRedditImageUrl(widget.post.url!);
    }

    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': 'https://www.reddit.com/',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Логируем только не-404 ошибки для отладки
          if (!error.toString().contains('404')) {
            debugPrint('Image load error for "${widget.post.title}": $error');
            debugPrint('Attempted URL: $imageUrl');
          }
          return _buildDefaultBackground();
        },
      );
    }

    return _buildDefaultBackground();
  }

  String _fixRedditImageUrl(String url) {
    // Используем прокси сервис для обхода блокировки
    return ImageProxyService.getProxiedImageUrl(url);
  }

  Widget _buildDefaultBackground() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.post.isVideo ? Icons.play_circle_outline : Icons.article_outlined,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.category == 'educational' ? 'Образование' : 'Развлечение',
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

  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
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
