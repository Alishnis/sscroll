import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reddit_service.dart';
import '../models/post_model.dart';

class RedditTestScreen extends StatefulWidget {
  const RedditTestScreen({super.key});

  @override
  State<RedditTestScreen> createState() => _RedditTestScreenState();
}

class _RedditTestScreenState extends State<RedditTestScreen> {
  final RedditService _redditService = RedditService();
  List<RedditPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _redditService.getEducationalPostsWithRealImages(
        subreddit: 'learning',
        limit: 10,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reddit Test - Реальные изображения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text('Нет постов'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(RedditPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Автор и субреддит
            Row(
              children: [
                Text('u/${post.author}'),
                const Text(' • '),
                Text('r/${post.subreddit}'),
                const Spacer(),
                Text('${post.score} ⬆️'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Изображение
            if (post.hasRealImage && post.realImageUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.realImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48),
                            const Text('Ошибка загрузки изображения'),
                            Text('URL: ${post.realImageUrl}'),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Информация об изображении
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Реальное изображение: ${post.imageType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (post.displayThumbnail != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.displayThumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48),
                            Text('Ошибка загрузки thumbnail'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 48),
                      Text('Нет изображения'),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Ссылка на источник
            Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Источник: ${post.url}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Кнопки действий
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Открыть ссылку на пост Reddit
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Открыть в Reddit'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Поделиться
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Поделиться'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
