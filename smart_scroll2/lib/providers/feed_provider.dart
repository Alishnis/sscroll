import 'package:flutter/foundation.dart';
import '../models/feed_item_model.dart';
import '../models/video_model.dart';
import '../models/post_model.dart';
import '../services/youtube_service.dart';
import '../services/reddit_service.dart';

class FeedProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final RedditService _redditService = RedditService();
  
  List<FeedItemModel> _feedItems = [];
  bool _isLoading = false;
  String? _error;
  int _currentItemIndex = 0;
  
  // Бесконечная лента
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  int _currentPage = 0;
  
  // Поиск по тегам
  String? _currentSearchQuery;
  List<String> _popularTags = [];

  List<FeedItemModel> get feedItems => _feedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentItemIndex => _currentItemIndex;
  FeedItemModel? get currentItem => 
      _feedItems.isNotEmpty && _currentItemIndex < _feedItems.length 
          ? _feedItems[_currentItemIndex] 
          : null;
  
  // Бесконечная лента
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreItems => _hasMoreItems;
  
  // Поиск по тегам
  String? get currentSearchQuery => _currentSearchQuery;
  List<String> get popularTags => _popularTags;
  bool get isSearching => _currentSearchQuery != null;

  /// Загрузка смешанной ленты
  Future<void> loadMixedFeed({int limit = 25}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMoreItems = true;
    notifyListeners();

    try {
      // Загружаем видео с YouTube (80% контента)
      final videoLimit = (limit * 0.8).round();
      final videos = await _loadYouTubeVideos(videoLimit);
      
      // Загружаем посты с Reddit (20% контента)
      final postLimit = limit - videoLimit;
      final posts = await _loadRedditPosts(postLimit);
      
      // Смешиваем контент с правильным соотношением
      _feedItems = _mixContent(videos, posts);
      _currentItemIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки ленты: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузка видео с YouTube
  Future<List<VideoModel>> _loadYouTubeVideos(int limit) async {
    if (!_youtubeService.isAvailable) {
      return [];
    }

    try {
      return await _youtubeService.getFullEducationalVideos(maxResults: limit);
    } catch (e) {
      debugPrint('Error loading YouTube videos: $e');
      return [];
    }
  }

  /// Загрузка постов с Reddit
  Future<List<PostModel>> _loadRedditPosts(int limit) async {
    try {
      // Загружаем образовательные посты (80% от постов)
      final educationalLimit = (limit * 0.8).round();
      final educationalPosts = await _redditService.getEducationalPosts(limit: educationalLimit);
      final educational = educationalPosts.map((post) => 
          PostModel.fromRedditPost(post, 'educational')).toList();
      
      // Загружаем развлекательные посты (20% от постов)
      final entertainmentLimit = limit - educationalLimit;
      final entertainmentPosts = await _redditService.getEntertainmentPosts(limit: entertainmentLimit);
      final entertainment = entertainmentPosts.map((post) => 
          PostModel.fromRedditPost(post, 'entertainment')).toList();
      
      return [...educational, ...entertainment];
    } catch (e) {
      debugPrint('Error loading Reddit posts: $e');
      return [];
    }
  }

  /// Смешивание контента с соотношением 5:1 (видео:посты)
  List<FeedItemModel> _mixContent(List<VideoModel> videos, List<PostModel> posts) {
    final mixed = <FeedItemModel>[];
    int videoIndex = 0;
    int postIndex = 0;
    int videoCount = 0;

    while (videoIndex < videos.length || postIndex < posts.length) {
      // Добавляем видео каждые 5 элементов
      if (videoCount < 5 && videoIndex < videos.length) {
        mixed.add(FeedItemModel.fromVideo(videos[videoIndex]));
        videoIndex++;
        videoCount++;
      } else if (postIndex < posts.length) {
        // Добавляем пост
        mixed.add(FeedItemModel.fromPost(posts[postIndex]));
        postIndex++;
        videoCount = 0; // Сбрасываем счетчик
      } else if (videoIndex < videos.length) {
        // Если посты закончились, добавляем видео
        mixed.add(FeedItemModel.fromVideo(videos[videoIndex]));
        videoIndex++;
        videoCount++;
      }
    }

    return mixed;
  }

  /// Загрузка следующей страницы (бесконечная лента)
  Future<void> loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Загружаем больше видео (полные видео)
      final newVideos = await _loadYouTubeVideos(8);
      
      // Загружаем больше постов
      final newPosts = await _loadRedditPosts(2);

      if (newVideos.isEmpty && newPosts.isEmpty) {
        _hasMoreItems = false;
      } else {
        // Смешиваем новые элементы
        final newMixed = _mixContent(newVideos, newPosts);
        _feedItems.addAll(newMixed);
        _currentPage++;
      }
    } catch (e) {
      _error = 'Ошибка загрузки дополнительных элементов: $e';
      _hasMoreItems = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setCurrentItemIndex(int index) {
    _currentItemIndex = index;
    notifyListeners();
  }

  void nextItem() {
    if (_currentItemIndex < _feedItems.length - 1) {
      _currentItemIndex++;
      notifyListeners();
    }
  }

  void previousItem() {
    if (_currentItemIndex > 0) {
      _currentItemIndex--;
      notifyListeners();
    }
  }

  void likeItem(String itemId) {
    final index = _feedItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      // В реальном приложении отправляем на сервер
      notifyListeners();
    }
  }

  /// Очистка кэша
  void clearCache() {
    _feedItems.clear();
    _currentPage = 0;
    _hasMoreItems = true;
    notifyListeners();
  }

  /// Получение статистики ленты
  Map<String, dynamic> getFeedStats() {
    final videoCount = _feedItems.where((item) => item.isVideo).length;
    final postCount = _feedItems.where((item) => item.isPost).length;
    final educationalCount = _feedItems.where((item) => 
        item.category == 'educational' || item.category == 'Образование').length;
    final entertainmentCount = _feedItems.where((item) => 
        item.category == 'entertainment' || item.category == 'Развлечение').length;

    return {
      'totalItems': _feedItems.length,
      'videos': videoCount,
      'posts': postCount,
      'educational': educationalCount,
      'entertainment': entertainmentCount,
      'currentPage': _currentPage,
      'hasMore': _hasMoreItems,
    };
  }

  /// Поиск по тегам
  Future<void> searchByTags(String query) async {
    _currentSearchQuery = query;
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMoreItems = true;
    notifyListeners();

    try {
      // Загружаем популярные теги
      await _loadPopularTags();
      
      // Ищем видео на YouTube по тегам
      final videos = await _searchYouTubeVideos(query);
      
      // Ищем посты на Reddit по тегам
      final posts = await _searchRedditPosts(query);
      
      // Смешиваем результаты
      final mixedItems = _mixFeedItems(videos, posts);
      _feedItems = mixedItems;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка поиска: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Смешивание видео и постов в единую ленту
  List<FeedItemModel> _mixFeedItems(List<VideoModel> videos, List<PostModel> posts) {
    final List<FeedItemModel> mixedItems = [];
    
    // Добавляем видео (80% контента)
    for (final video in videos) {
      mixedItems.add(FeedItemModel.fromVideo(video));
    }
    
    // Добавляем посты (20% контента)
    for (final post in posts) {
      mixedItems.add(FeedItemModel.fromPost(post));
    }
    
    // Перемешиваем элементы
    mixedItems.shuffle();
    
    return mixedItems;
  }

  /// Очистка поиска
  void clearSearch() {
    _currentSearchQuery = null;
    _feedItems.clear();
    _currentPage = 0;
    _hasMoreItems = true;
    notifyListeners();
  }

  /// Загрузка популярных тегов
  Future<void> _loadPopularTags() async {
    _popularTags = [
      'programming', 'coding', 'tutorial', 'learn', 'study',
      'funny', 'meme', 'comedy', 'gaming', 'music',
      'cooking', 'diy', 'fitness', 'travel', 'art',
      'science', 'math', 'history', 'language', 'business'
    ];
  }

  /// Поиск видео на YouTube
  Future<List<VideoModel>> _searchYouTubeVideos(String query) async {
    try {
      return await _youtubeService.searchVideos(
        query: query,
        maxResults: 15,
      );
    } catch (e) {
      debugPrint('YouTube search error: $e');
      return [];
    }
  }

  /// Поиск постов на Reddit
  Future<List<PostModel>> _searchRedditPosts(String query) async {
    try {
      final redditPosts = await _redditService.searchEducationalContent(
        query: query,
        limit: 10,
      );
      
      return redditPosts.map((post) => PostModel.fromRedditPost(post, 'educational')).toList();
    } catch (e) {
      debugPrint('Reddit search error: $e');
      return [];
    }
  }
}
