import 'package:flutter/material.dart';
import '../services/reddit_service.dart';
import '../widgets/reddit_post_with_real_image.dart';

/// Экран для отображения постов Reddit с реальными изображениями
class RedditRealImagesScreen extends StatefulWidget {
  const RedditRealImagesScreen({Key? key}) : super(key: key);

  @override
  State<RedditRealImagesScreen> createState() => _RedditRealImagesScreenState();
}

class _RedditRealImagesScreenState extends State<RedditRealImagesScreen> {
  final RedditService _redditService = RedditService();
  List<RedditPost> _posts = [];
  bool _isLoading = false;
  String _currentSubreddit = 'learning';
  String _currentSort = 'hot';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    try {
      final posts = await _redditService.getEducationalPostsWithRealImages(
        subreddit: _currentSubreddit,
        limit: 20,
        sort: _currentSort,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки постов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reddit с реальными изображениями'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
            tooltip: 'Обновить',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentSubreddit = value;
              });
              _loadPosts();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'learning',
                child: Text('r/learning'),
              ),
              const PopupMenuItem(
                value: 'programming',
                child: Text('r/programming'),
              ),
              const PopupMenuItem(
                value: 'education',
                child: Text('r/education'),
              ),
              const PopupMenuItem(
                value: 'todayilearned',
                child: Text('r/todayilearned'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Субреддит: r/$_currentSubreddit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Найдено постов с изображениями: ${_posts.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (_posts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatChip('Всего постов', _posts.length),
                      _buildStatChip('С изображениями', _posts.where((p) => p.hasRealImage).length),
                      _buildStatChip('Валидные', _posts.where((p) => p.imageIsValid).length),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Список постов
          Expanded(
            child: RedditPostsListWithRealImages(
              posts: _posts,
              isLoading: _isLoading,
              onRefresh: _loadPosts,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadPosts,
        icon: const Icon(Icons.refresh),
        label: const Text('Обновить'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Экран для тестирования извлечения реальных изображений
class RedditImageTestScreen extends StatefulWidget {
  const RedditImageTestScreen({Key? key}) : super(key: key);

  @override
  State<RedditImageTestScreen> createState() => _RedditImageTestScreenState();
}

class _RedditImageTestScreenState extends State<RedditImageTestScreen> {
  final RedditService _redditService = RedditService();
  List<RedditPost> _posts = [];
  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _runImageTest();
  }

  Future<void> _runImageTest() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Запуск теста извлечения реальных изображений...\n';
    });

    try {
      // Получаем посты
      final posts = await _redditService.getEducationalPostsWithRealImages(
        subreddit: 'learning',
        limit: 10,
        sort: 'hot',
      );

      setState(() {
        _posts = posts;
        _isLoading = false;
      });

      // Анализируем результаты
      String results = 'Результаты теста:\n\n';
      results += 'Всего постов: ${posts.length}\n';
      results += 'С реальными изображениями: ${posts.where((p) => p.hasRealImage).length}\n';
      results += 'Валидные изображения: ${posts.where((p) => p.imageIsValid).length}\n\n';

      // Детальная информация по каждому посту
      for (int i = 0; i < posts.length; i++) {
        final post = posts[i];
        results += 'Пост ${i + 1}: ${post.title}\n';
        results += '  - Реальное изображение: ${post.hasRealImage ? "Да" : "Нет"}\n';
        results += '  - Тип: ${post.imageType ?? "Нет"}\n';
        results += '  - Валидное: ${post.imageIsValid ? "Да" : "Нет"}\n';
        results += '  - URL: ${post.realImageUrl ?? "Нет"}\n\n';
      }

      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResults = 'Ошибка теста: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест реальных изображений'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Результаты теста
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Результаты теста:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Список постов
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return RedditPostWithRealImage(post: _posts[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runImageTest,
        child: const Icon(Icons.play_arrow),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
    );
  }
}
