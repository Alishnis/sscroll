import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/user_provider.dart';

/// Виджет управления рекомендациями
class RecommendationControls extends StatelessWidget {
  const RecommendationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<VideoProvider, UserProvider>(
      builder: (context, videoProvider, userProvider, child) {
        if (userProvider.currentUser == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Кнопка обновления рекомендаций
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _refreshRecommendations(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Обновить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Кнопка разнообразных рекомендаций
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _loadDiverseRecommendations(context),
                  icon: const Icon(Icons.explore, size: 18),
                  label: const Text('Разнообразие'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Кнопка очистки кэша
              IconButton(
                onPressed: () => _clearCache(context),
                icon: const Icon(Icons.clear_all, color: Colors.white),
                tooltip: 'Очистить кэш',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshRecommendations(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final videoProvider = context.read<VideoProvider>();
    
    if (userProvider.currentUser != null) {
      await videoProvider.loadRecommendations(
        userProvider.currentUser!.interests,
        userId: userProvider.currentUser!.id,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Рекомендации обновлены'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadDiverseRecommendations(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final videoProvider = context.read<VideoProvider>();
    
    if (userProvider.currentUser != null) {
      await videoProvider.loadDiverseRecommendations(
        userProvider.currentUser!.id,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Загружены разнообразные рекомендации'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearCache(BuildContext context) {
    final videoProvider = context.read<VideoProvider>();
    videoProvider.clearRecommendationCache();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Кэш очищен'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Виджет статистики кэша (для debug)
class CacheStatsWidget extends StatelessWidget {
  const CacheStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final stats = videoProvider.getCacheStats();
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Статистика кэша',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Пользователей в кэше: ${stats['totalCachedUsers']}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Видео в кэше: ${stats['totalCachedVideos']}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Пользователей с интересами: ${stats['usersWithInterests']}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Виджет трендовых тем
class TrendingTopicsWidget extends StatefulWidget {
  const TrendingTopicsWidget({super.key});

  @override
  State<TrendingTopicsWidget> createState() => _TrendingTopicsWidgetState();
}

class _TrendingTopicsWidgetState extends State<TrendingTopicsWidget> {
  List<String> _trendingTopics = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingTopics();
  }

  Future<void> _loadTrendingTopics() async {
    setState(() {
      _isLoading = true;
    });

    // В реальном приложении это будет API вызов
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _trendingTopics = [
        'AI',
        'Machine Learning',
        'Python',
        'Web Development',
        'Data Science',
        'JavaScript',
        'React',
        'Flutter',
        'Mobile Development',
        'Blockchain',
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Трендовые темы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingTopics.map((topic) {
                return GestureDetector(
                  onTap: () => _onTopicTap(topic),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#$topic',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _onTopicTap(String topic) {
    final userProvider = context.read<UserProvider>();
    final videoProvider = context.read<VideoProvider>();
    
    if (userProvider.currentUser != null) {
      // Добавляем тему к интересам пользователя
      final currentInterests = List<String>.from(userProvider.currentUser!.interests);
      if (!currentInterests.contains(topic)) {
        currentInterests.add(topic);
        userProvider.updateInterests(currentInterests);
        
        // Обновляем рекомендации
        videoProvider.loadRecommendations(
          currentInterests,
          userId: userProvider.currentUser!.id,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлена тема: $topic'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
