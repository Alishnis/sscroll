import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import 'video_service.dart';
import 'reddit_service.dart';
import 'youtube_service.dart';

/// Сервис рекомендаций с бесконечной лентой
class RecommendationService {
  final VideoService _videoService = VideoService();
  final RedditService _redditService = RedditService();
  final YouTubeService _youtubeService = YouTubeService();

  // Кэш для пагинации
  final Map<String, List<VideoModel>> _cache = {};
  final Map<String, int> _pageCounters = {};
  final Map<String, List<String>> _userInterests = {};

  /// Получение рекомендаций с пагинацией
  Future<List<VideoModel>> getRecommendations({
    required String userId,
    required List<String> interests,
    int page = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${userId}_${interests.join('_')}';
    
    // Обновляем интересы пользователя
    _userInterests[userId] = interests;

    // Если принудительное обновление, очищаем кэш
    if (forceRefresh) {
      _cache.remove(cacheKey);
      _pageCounters[cacheKey] = 0;
    }

    // Инициализируем кэш если нужно
    if (!_cache.containsKey(cacheKey)) {
      _cache[cacheKey] = [];
      _pageCounters[cacheKey] = 0;
    }

    final cachedVideos = _cache[cacheKey]!;
    final currentPage = _pageCounters[cacheKey]!;

    // Если запрашиваем страницу, которая уже есть в кэше
    if (page <= currentPage && cachedVideos.length >= (page + 1) * limit) {
      final startIndex = page * limit;
      final endIndex = (startIndex + limit).clamp(0, cachedVideos.length);
      
      // Проверяем, что startIndex не выходит за границы
      if (startIndex >= cachedVideos.length) {
        return [];
      }
      
      return cachedVideos.sublist(startIndex, endIndex);
    }

    // Загружаем новые данные
    final newVideos = await _fetchRecommendationsForPage(
      interests: interests,
      page: currentPage + 1,
      limit: limit,
    );

    // Добавляем в кэш
    cachedVideos.addAll(newVideos);
    _pageCounters[cacheKey] = currentPage + 1;

    // Возвращаем запрошенную страницу
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, cachedVideos.length);
    
    // Проверяем, что startIndex не выходит за границы
    if (startIndex >= cachedVideos.length) {
      return [];
    }
    
    return cachedVideos.sublist(startIndex, endIndex);
  }

  /// Загрузка рекомендаций для конкретной страницы
  Future<List<VideoModel>> _fetchRecommendationsForPage({
    required List<String> interests,
    required int page,
    required int limit,
  }) async {
    final allVideos = <VideoModel>[];

    // 1. Основные видео из VideoService
    final mainVideos = await _videoService.fetchVideos();
    allVideos.addAll(mainVideos);

    // 2. YouTube контент (если доступен)
    try {
      if (_youtubeService.isAvailable) {
        final youtubeVideos = await _youtubeService.getShortEducationalVideos(
          query: 'educational tutorial',
          maxResults: 5,
        );
        allVideos.addAll(youtubeVideos);
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('YouTube service error: $e');
    }

    // 3. Reddit контент (если доступен)
    try {
      final redditPosts = await _redditService.getEducationalPosts(
        limit: 3,
      );
      
      final redditVideos = redditPosts.where((post) => post.hasVideo).map((post) {
        return VideoModel(
          id: 'reddit_${post.id}',
          title: post.title,
          description: post.shortDescription,
          videoUrl: post.videoUrl!,
          thumbnailUrl: post.displayThumbnail ?? '',
          source: 'Reddit',
          sourceUrl: 'https://reddit.com/r/${post.subreddit}/comments/${post.id}',
          author: post.author,
          category: _mapSubredditToCategory(post.subreddit),
          duration: 0, // Reddit не предоставляет длительность
          views: post.score,
          likes: post.score,
          uploadDate: post.created,
          tags: [post.subreddit, 'community'],
        );
      }).toList();
      
      allVideos.addAll(redditVideos);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Reddit service error: $e');
    }

    // 3. Фильтрация по интересам
    final filteredVideos = _filterVideosByInterests(allVideos, interests);

    // 4. Сортировка по релевантности
    final sortedVideos = _sortByRelevance(filteredVideos, interests);

    // 5. Пагинация
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, sortedVideos.length);
    
    // Проверяем, что startIndex не выходит за границы
    if (startIndex >= sortedVideos.length) {
      return [];
    }
    
    return sortedVideos.sublist(startIndex, endIndex);
  }

  /// Фильтрация видео по интересам пользователя
  List<VideoModel> _filterVideosByInterests(
    List<VideoModel> videos,
    List<String> interests,
  ) {
    if (interests.isEmpty) return videos;

    return videos.where((video) {
      // Проверяем категорию
      final categoryMatch = interests.any((interest) =>
          video.category.toLowerCase().contains(interest.toLowerCase()));

      // Проверяем теги
      final tagMatch = interests.any((interest) =>
          video.tags.any((tag) =>
              tag.toLowerCase().contains(interest.toLowerCase())));

      // Проверяем название и описание
      final contentMatch = interests.any((interest) =>
          video.title.toLowerCase().contains(interest.toLowerCase()) ||
          video.description.toLowerCase().contains(interest.toLowerCase()));

      return categoryMatch || tagMatch || contentMatch;
    }).toList();
  }

  /// Сортировка по релевантности
  List<VideoModel> _sortByRelevance(
    List<VideoModel> videos,
    List<String> interests,
  ) {
    return videos..sort((a, b) {
      final scoreA = _calculateRelevanceScore(a, interests);
      final scoreB = _calculateRelevanceScore(b, interests);
      return scoreB.compareTo(scoreA);
    });
  }

  /// Расчет релевантности видео
  double _calculateRelevanceScore(VideoModel video, List<String> interests) {
    double score = 0.0;

    // Базовый скор по популярности
    score += (video.likes * 0.1) + (video.views * 0.001);

    // Скор по категории (высокий приоритет)
    for (final interest in interests) {
      if (video.category.toLowerCase().contains(interest.toLowerCase())) {
        score += 100.0;
      }
    }

    // Скор по тегам (средний приоритет)
    for (final interest in interests) {
      for (final tag in video.tags) {
        if (tag.toLowerCase().contains(interest.toLowerCase())) {
          score += 50.0;
        }
      }
    }

    // Скор по содержанию (низкий приоритет)
    for (final interest in interests) {
      if (video.title.toLowerCase().contains(interest.toLowerCase())) {
        score += 25.0;
      }
      if (video.description.toLowerCase().contains(interest.toLowerCase())) {
        score += 10.0;
      }
    }

    // Бонус за свежесть
    final daysSinceUpload = DateTime.now().difference(video.uploadDate).inDays;
    if (daysSinceUpload < 7) {
      score += 20.0; // Неделя
    } else if (daysSinceUpload < 30) {
      score += 10.0; // Месяц
    }

    // Бонус за качественные источники
    switch (video.source.toLowerCase()) {
      case 'youtube':
        score += 15.0;
        break;
      case 'coursera':
        score += 25.0;
        break;
      case 'cambridge':
        score += 30.0;
        break;
      case 'reddit':
        score += 5.0;
        break;
    }

    return score;
  }

  /// Маппинг субреддитов в категории
  String _mapSubredditToCategory(String subreddit) {
    const categoryMap = {
      'learning': 'Образование',
      'education': 'Образование',
      'studytips': 'Образование',
      'programming': 'Программирование',
      'learnprogramming': 'Программирование',
      'webdev': 'Программирование',
      'machinelearning': 'Программирование',
      'math': 'Математика',
      'physics': 'Физика',
      'chemistry': 'Химия',
      'biology': 'Биология',
      'languagelearning': 'Языки',
      'cooking': 'Кулинария',
      'diy': 'Ремесло',
      'lifeprotips': 'Лайфхаки',
    };

    return categoryMap[subreddit.toLowerCase()] ?? 'Другое';
  }

  /// Получение персонализированных рекомендаций
  Future<List<VideoModel>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    final interests = _userInterests[userId] ?? [];
    
    if (interests.isEmpty) {
      // Если нет интересов, возвращаем популярные видео
      return await _getPopularVideos(limit);
    }

    return await getRecommendations(
      userId: userId,
      interests: interests,
      page: 0,
      limit: limit,
    );
  }

  /// Получение популярных видео
  Future<List<VideoModel>> _getPopularVideos(int limit) async {
    final videos = await _videoService.fetchVideos();
    videos.sort((a, b) => b.likes.compareTo(a.likes));
    return videos.take(limit).toList();
  }

  /// Обновление интересов пользователя
  void updateUserInterests(String userId, List<String> interests) {
    _userInterests[userId] = interests;
    
    // Очищаем кэш для этого пользователя
    final keysToRemove = _cache.keys.where((key) => key.startsWith('${userId}_')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _pageCounters.remove(key);
    }
  }

  /// Получение разнообразных рекомендаций
  Future<List<VideoModel>> getDiverseRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    final interests = _userInterests[userId] ?? [];
    final allVideos = <VideoModel>[];

    // Получаем видео по каждому интересу
    for (final interest in interests) {
      final videos = await getRecommendations(
        userId: userId,
        interests: [interest],
        page: 0,
        limit: (limit / interests.length).ceil(),
      );
      allVideos.addAll(videos);
    }

    // Если недостаточно видео, добавляем популярные
    if (allVideos.length < limit) {
      final popularVideos = await _getPopularVideos(limit - allVideos.length);
      allVideos.addAll(popularVideos);
    }

    // Перемешиваем для разнообразия
    allVideos.shuffle(Random());
    return allVideos.take(limit).toList();
  }

  /// Получение трендовых тем
  Future<List<String>> getTrendingTopics() async {
    // В реальном приложении это будет анализ популярных тегов
    return [
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
  }

  /// Очистка кэша
  void clearCache() {
    _cache.clear();
    _pageCounters.clear();
  }

  /// Очистка кэша для конкретного пользователя
  void clearUserCache(String userId) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith('${userId}_')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _pageCounters.remove(key);
    }
    _userInterests.remove(userId);
  }

  /// Получение статистики кэша
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedUsers': _cache.length,
      'totalCachedVideos': _cache.values.fold(0, (sum, videos) => sum + videos.length),
      'usersWithInterests': _userInterests.length,
    };
  }
}
