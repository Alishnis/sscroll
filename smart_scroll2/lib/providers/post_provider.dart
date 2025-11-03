import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/reddit_service.dart';

class PostProvider with ChangeNotifier {
  final RedditService _redditService = RedditService();
  
  List<PostModel> _posts = [];
  List<PostModel> _educationalPosts = [];
  List<PostModel> _entertainmentPosts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPostIndex = 0;
  
  // Бесконечная лента
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  int _currentPage = 0;
  
  // Поиск по тегам
  String? _currentSearchQuery;
  List<String> _popularTags = [];

  List<PostModel> get posts => _posts;
  List<PostModel> get educationalPosts => _educationalPosts;
  List<PostModel> get entertainmentPosts => _entertainmentPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPostIndex => _currentPostIndex;
  PostModel? get currentPost => 
      _posts.isNotEmpty && _currentPostIndex < _posts.length 
          ? _posts[_currentPostIndex] 
          : null;
  
  // Бесконечная лента
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePosts => _hasMorePosts;
  
  // Поиск по тегам
  String? get currentSearchQuery => _currentSearchQuery;
  List<String> get popularTags => _popularTags;
  bool get isSearching => _currentSearchQuery != null;

  /// Загрузка образовательных постов
  Future<void> loadEducationalPosts({int limit = 25}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final redditPosts = await _redditService.getEducationalPosts(limit: limit);
      _educationalPosts = redditPosts.map((post) => 
          PostModel.fromRedditPost(post, 'educational')).toList();
      
      _posts = List.from(_educationalPosts);
      _currentPostIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки образовательных постов: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузка развлекательных постов
  Future<void> loadEntertainmentPosts({int limit = 25}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Загружаем из развлекательных субреддитов
      final redditPosts = await _redditService.getEntertainmentPosts(limit: limit);
      _entertainmentPosts = redditPosts.map((post) => 
          PostModel.fromRedditPost(post, 'entertainment')).toList();
      
      _posts = List.from(_entertainmentPosts);
      _currentPostIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки развлекательных постов: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузка смешанных постов (образовательные + развлекательные)
  Future<void> loadMixedPosts({int limit = 25}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Загружаем образовательные посты (80%)
      final educationalLimit = (limit * 0.8).round();
      final educationalPosts = await _redditService.getEducationalPosts(limit: educationalLimit);
      _educationalPosts = educationalPosts.map((post) => 
          PostModel.fromRedditPost(post, 'educational')).toList();
      
      // Загружаем развлекательные посты (20%)
      final entertainmentLimit = limit - educationalLimit;
      final entertainmentPosts = await _redditService.getEntertainmentPosts(limit: entertainmentLimit);
      _entertainmentPosts = entertainmentPosts.map((post) => 
          PostModel.fromRedditPost(post, 'entertainment')).toList();
      
      // Смешиваем посты с правильным соотношением
      _posts = _mixPosts(_educationalPosts, _entertainmentPosts);
      _currentPostIndex = 0;
    } catch (e) {
      _error = 'Ошибка загрузки смешанных постов: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Смешивание постов с соотношением 5:1 (образовательные:развлекательные)
  List<PostModel> _mixPosts(List<PostModel> educational, List<PostModel> entertainment) {
    final mixed = <PostModel>[];
    int educationalIndex = 0;
    int entertainmentIndex = 0;
    int educationalCount = 0;

    while (educationalIndex < educational.length || entertainmentIndex < entertainment.length) {
      // Добавляем образовательный пост каждые 5 постов
      if (educationalCount < 5 && educationalIndex < educational.length) {
        mixed.add(educational[educationalIndex]);
        educationalIndex++;
        educationalCount++;
      } else if (entertainmentIndex < entertainment.length) {
        // Добавляем развлекательный пост
        mixed.add(entertainment[entertainmentIndex]);
        entertainmentIndex++;
        educationalCount = 0; // Сбрасываем счетчик
      } else if (educationalIndex < educational.length) {
        // Если развлекательные закончились, добавляем образовательные
        mixed.add(educational[educationalIndex]);
        educationalIndex++;
        educationalCount++;
      }
    }

    return mixed;
  }

  /// Загрузка следующей страницы (бесконечная лента)
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Загружаем больше образовательных постов
      final newEducationalPosts = await _redditService.getEducationalPosts(limit: 10);
      final newEducational = newEducationalPosts.map((post) => 
          PostModel.fromRedditPost(post, 'educational')).toList();
      
      // Загружаем больше развлекательных постов
      final newEntertainmentPosts = await _redditService.getEntertainmentPosts(limit: 2);
      final newEntertainment = newEntertainmentPosts.map((post) => 
          PostModel.fromRedditPost(post, 'entertainment')).toList();

      if (newEducational.isEmpty && newEntertainment.isEmpty) {
        _hasMorePosts = false;
      } else {
        // Добавляем новые посты к существующим
        _educationalPosts.addAll(newEducational);
        _entertainmentPosts.addAll(newEntertainment);
        
        // Смешиваем новые посты
        final newMixed = _mixPosts(newEducational, newEntertainment);
        _posts.addAll(newMixed);
        _currentPage++;
      }
    } catch (e) {
      _error = 'Ошибка загрузки дополнительных постов: $e';
      _hasMorePosts = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setCurrentPostIndex(int index) {
    _currentPostIndex = index;
    notifyListeners();
  }

  void nextPost() {
    if (_currentPostIndex < _posts.length - 1) {
      _currentPostIndex++;
      notifyListeners();
    }
  }

  void previousPost() {
    if (_currentPostIndex > 0) {
      _currentPostIndex--;
      notifyListeners();
    }
  }

  void likePost(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      // В реальном приложении отправляем на сервер
      notifyListeners();
    }
  }

  /// Очистка кэша
  void clearCache() {
    _posts.clear();
    _educationalPosts.clear();
    _entertainmentPosts.clear();
    _currentPage = 0;
    _hasMorePosts = true;
    notifyListeners();
  }

  /// Поиск постов по тегам
  Future<void> searchPostsByTags(String query) async {
    _currentSearchQuery = query;
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMorePosts = true;
    notifyListeners();

    try {
      // Загружаем популярные теги
      await _loadPopularTags();
      
      // Ищем образовательные посты
      final educationalPosts = await _searchEducationalPosts(query);
      
      // Ищем развлекательные посты
      final entertainmentPosts = await _searchEntertainmentPosts(query);
      
      // Смешиваем результаты
      final allPosts = [...educationalPosts, ...entertainmentPosts];
      _posts = allPosts;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка поиска: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Очистка поиска
  void clearSearch() {
    _currentSearchQuery = null;
    _posts.clear();
    _currentPage = 0;
    _hasMorePosts = true;
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

  /// Поиск образовательных постов
  Future<List<PostModel>> _searchEducationalPosts(String query) async {
    try {
      final redditPosts = await _redditService.searchEducationalContent(
        query: query,
        limit: 15,
      );
      
      return redditPosts.map((post) => PostModel.fromRedditPost(post, 'educational')).toList();
    } catch (e) {
      debugPrint('Educational posts search error: $e');
      return [];
    }
  }

  /// Поиск развлекательных постов
  Future<List<PostModel>> _searchEntertainmentPosts(String query) async {
    try {
      final redditPosts = await _redditService.searchEducationalContent(
        query: query,
        subreddit: 'funny',
        limit: 10,
      );
      
      return redditPosts.map((post) => PostModel.fromRedditPost(post, 'entertainment')).toList();
    } catch (e) {
      debugPrint('Entertainment posts search error: $e');
      return [];
    }
  }
}
