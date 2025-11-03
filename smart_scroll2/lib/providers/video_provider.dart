import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../services/recommendation_service.dart';
import '../services/youtube_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _videoService = VideoService();
  final RecommendationService _recommendationService = RecommendationService();
  final YouTubeService _youtubeService = YouTubeService();
  
  List<VideoModel> _videos = [];
  List<VideoModel> _groupVideos = [];
  bool _isLoading = false;
  String? _error;
  int _currentVideoIndex = 0;
  
  // Бесконечная лента
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;
  int _currentPage = 0;
  String? _currentUserId;

  List<VideoModel> get videos => _videos;
  List<VideoModel> get groupVideos => _groupVideos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentVideoIndex => _currentVideoIndex;
  VideoModel? get currentVideo => 
      _videos.isNotEmpty && _currentVideoIndex < _videos.length 
          ? _videos[_currentVideoIndex] 
          : null;
  
  // Бесконечная лента
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreVideos => _hasMoreVideos;

  Future<void> loadVideos({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _videos = await _videoService.fetchVideos(category: category);
      _currentVideoIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки видео: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupVideos(String groupId) async {
    try {
      _groupVideos = await _videoService.getGroupVideos(groupId);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки видео группы: $e';
      notifyListeners();
    }
  }

  Future<void> loadRecommendations(List<String> interests, {String? userId}) async {
    _isLoading = true;
    _currentUserId = userId;
    _currentPage = 0;
    _hasMoreVideos = true;
    _error = null; // Очищаем предыдущие ошибки
    notifyListeners();

    try {
      // Загружаем видео с YouTube API
      _videos = await _loadYouTubeVideos(interests);
      _currentVideoIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки рекомендаций: $e';
      _videos = []; // Очищаем видео при ошибке
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузка видео с YouTube API
  Future<List<VideoModel>> _loadYouTubeVideos(List<String> interests) async {
    if (!_youtubeService.isAvailable) {
      throw Exception('YouTube API не настроен');
    }

    final List<VideoModel> allVideos = [];

    if (interests.isEmpty) {
      // Загружаем трендовые образовательные видео
      try {
        final trendingVideos = await _youtubeService.getFullEducationalVideos(maxResults: 15);
        allVideos.addAll(trendingVideos);
        debugPrint('Loaded ${trendingVideos.length} trending videos');
      } catch (e) {
        debugPrint('Error loading trending videos: $e');
      }
      
      // Если мало видео, пробуем дополнительные запросы
      if (allVideos.length < 10) {
        try {
          final programmingVideos = await _youtubeService.searchEducationalVideos(
            query: 'programming tutorial',
            maxResults: 10,
            order: 'relevance',
            videoDuration: 'any',
          );
          allVideos.addAll(programmingVideos);
          debugPrint('Loaded ${programmingVideos.length} programming videos');
        } catch (e) {
          debugPrint('Error loading programming videos: $e');
        }
      }
    } else {
      // Загружаем видео по интересам пользователя
      for (final interest in interests.take(3)) {
        try {
          final videos = await _youtubeService.searchEducationalVideos(
            query: interest,
            maxResults: 8, // Увеличиваем количество
            order: 'relevance',
            videoDuration: 'any',
          );
          allVideos.addAll(videos);
          debugPrint('Loaded ${videos.length} videos for interest: $interest');
        } catch (e) {
          debugPrint('Error fetching videos for interest "$interest": $e');
        }
      }
    }

    // Убираем дубликаты по ID
    final uniqueVideos = <String, VideoModel>{};
    for (final video in allVideos) {
      uniqueVideos[video.id] = video;
    }

    final result = uniqueVideos.values.toList();
    debugPrint('Total unique videos loaded: ${result.length}');
    return result;
  }

  /// Загрузка следующей страницы (бесконечная лента)
  Future<void> loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Загружаем больше видео с YouTube API
      final List<VideoModel> newVideos = [];
      
      // Пробуем разные запросы для разнообразия
      final queries = [
        'educational tutorial',
        'programming course',
        'science explained',
        'math tutorial',
        'history documentary',
      ];
      
      final randomQuery = queries[_currentPage % queries.length];
      
      final videos = await _youtubeService.searchEducationalVideos(
        query: randomQuery,
        maxResults: 10,
        order: 'relevance',
        videoDuration: 'any',
      );
      
      newVideos.addAll(videos);
      debugPrint('Loaded ${videos.length} more videos with query: $randomQuery');

      if (newVideos.isEmpty) {
        _hasMoreVideos = false;
      } else {
        // Убираем дубликаты
        final existingIds = _videos.map((v) => v.id).toSet();
        final uniqueNewVideos = newVideos.where((v) => !existingIds.contains(v.id)).toList();
        
        _videos.addAll(uniqueNewVideos);
        _currentPage++;
        debugPrint('Added ${uniqueNewVideos.length} unique videos to feed');
      }
    } catch (e) {
      _error = 'Ошибка загрузки дополнительных видео: $e';
      _hasMoreVideos = false; // Останавливаем загрузку при ошибке
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Обновление интересов пользователя
  void updateUserInterests(String userId, List<String> interests) {
    _recommendationService.updateUserInterests(userId, interests);
  }

  /// Получение разнообразных рекомендаций
  Future<void> loadDiverseRecommendations(String userId) async {
    _isLoading = true;
    _currentUserId = userId;
    _currentPage = 0;
    _hasMoreVideos = true;
    notifyListeners();

    try {
      _videos = await _recommendationService.getDiverseRecommendations(
        userId: userId,
        limit: 10,
      );
      _currentVideoIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки разнообразных рекомендаций: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateSummary(String videoId) async {
    return await _videoService.generateSummary(videoId);
  }

  void setCurrentVideoIndex(int index) {
    _currentVideoIndex = index;
    notifyListeners();
  }

  void nextVideo() {
    if (_currentVideoIndex < _videos.length - 1) {
      _currentVideoIndex++;
      notifyListeners();
    }
  }

  void previousVideo() {
    if (_currentVideoIndex > 0) {
      _currentVideoIndex--;
      notifyListeners();
    }
  }

  void likeVideo(String videoId) {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      // В реальном приложении отправляем на сервер
      notifyListeners();
    }
  }

  /// Очистка кэша рекомендаций
  void clearRecommendationCache() {
    _recommendationService.clearCache();
    _videos.clear();
    _currentPage = 0;
    _hasMoreVideos = true;
    notifyListeners();
  }

  /// Получение статистики кэша
  Map<String, dynamic> getCacheStats() {
    return _recommendationService.getCacheStats();
  }
}

