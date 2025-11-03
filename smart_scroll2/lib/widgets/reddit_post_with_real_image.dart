import 'package:flutter/material.dart';
import '../services/reddit_service.dart';
import '../services/reddit_real_image_service.dart';

/// Виджет для отображения поста Reddit с реальным изображением
class RedditPostWithRealImage extends StatefulWidget {
  final RedditPost post;

  const RedditPostWithRealImage({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<RedditPostWithRealImage> createState() => _RedditPostWithRealImageState();
}

class _RedditPostWithRealImageState extends State<RedditPostWithRealImage> {
  String? _finalImageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageWithFallback();
  }

  Future<void> _loadImageWithFallback() async {
    if (widget.post.realImageUrl == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      // Получаем изображение с fallback через прокси
      final imageUrl = await RedditRealImageService.getImageUrlWithFallback(
        widget.post.realImageUrl!,
      );

      setState(() {
        _finalImageUrl = imageUrl;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Изображение
          if (widget.post.hasRealImage)
            _buildImageWidget()
          else
            _buildNoImageWidget(),
          
          // Метаданные
          _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_isLoading) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Загрузка изображения...'),
            ],
          ),
        ),
      );
    }

    if (_hasError || _finalImageUrl == null) {
      return _buildErrorWidget();
    }

    return Image.network(
      _finalImageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://www.reddit.com/',
        'Accept': 'image/*',
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Изображение недоступно',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImageWidget() {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Нет изображения',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Основная информация
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.post.author,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.group, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'r/${widget.post.subreddit}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.arrow_upward, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.post.score.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Информация об изображении
          Row(
            children: [
              Icon(Icons.image, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                widget.post.imageInfo,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (widget.post.imageType != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getImageTypeColor(widget.post.imageType!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.post.imageType!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Кнопка обновления изображения
          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _loadImageWithFallback();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Повторить загрузку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[100],
                  foregroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getImageTypeColor(String imageType) {
    switch (imageType) {
      case 'preview_source':
        return Colors.green;
      case 'preview_resolution':
        return Colors.blue;
      case 'thumbnail':
        return Colors.orange;
      case 'direct_url':
        return Colors.purple;
      case 'gallery':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Виджет для отображения списка постов с реальными изображениями
class RedditPostsListWithRealImages extends StatelessWidget {
  final List<RedditPost> posts;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const RedditPostsListWithRealImages({
    Key? key,
    required this.posts,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка постов с реальными изображениями...'),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет постов с изображениями',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте обновить или изменить запрос',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return RedditPostWithRealImage(post: posts[index]);
        },
      ),
    );
  }
}
