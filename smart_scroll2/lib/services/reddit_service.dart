import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import 'reddit_real_image_service.dart';

/// Reddit API Service
/// Получение образовательного контента из Reddit
class RedditService {
  final String _clientId;
  final String _clientSecret;
  final String _userAgent;
  String? _accessToken;

  RedditService({
    String? clientId,
    String? clientSecret,
    String? userAgent,
  }) : _clientId = clientId ?? Secrets.redditClientId,
       _clientSecret = clientSecret ?? Secrets.redditClientSecret,
       _userAgent = userAgent ?? Secrets.redditUserAgent;

  /// Аутентификация в Reddit API
  Future<bool> authenticate() async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      // ignore: avoid_print
      debugPrint('Reddit Auth Error: Client ID or Secret is empty');
      return false;
    }

    // Debug информация
    // ignore: avoid_print
    debugPrint('Reddit Auth Debug:');
    // ignore: avoid_print
    debugPrint('Client ID: $_clientId');
    // ignore: avoid_print
    debugPrint('Client Secret: ${_clientSecret.isNotEmpty ? "SET (${_clientSecret.length} chars)" : "NOT SET"}');
    // ignore: avoid_print
    debugPrint('User Agent: $_userAgent');

    try {
      // Используем альтернативный подход для обхода CORS
      final response = await http.post(
        Uri.parse('https://www.reddit.com/api/v1/access_token'),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: 'grant_type=client_credentials&device_id=smartscroll_app',
      ).timeout(const Duration(seconds: 15));

      // ignore: avoid_print
      debugPrint('Reddit Auth Response: ${response.statusCode}');
      // ignore: avoid_print
      debugPrint('Reddit Auth Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        // ignore: avoid_print
        debugPrint('Reddit Auth Success: Token received');
        return true;
      } else {
        // ignore: avoid_print
        debugPrint('Reddit Auth Failed: ${response.statusCode} - ${response.body}');
        // Попробуем без аутентификации (публичные данные)
        return await _tryPublicAccess();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Reddit authentication error: $e');
      // Попробуем без аутентификации
      return await _tryPublicAccess();
    }
  }

  /// Попытка доступа к публичным данным без аутентификации
  Future<bool> _tryPublicAccess() async {
    try {
      // ignore: avoid_print
      debugPrint('Trying public Reddit access...');
      
      // Используем CORS proxy для обхода ограничений
      final redditUrl = 'https://www.reddit.com/r/learning/hot.json?limit=5';
      final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(redditUrl)}';
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'User-Agent': _userAgent,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // ignore: avoid_print
        debugPrint('Public Reddit access successful via proxy');
        _accessToken = 'public'; // Маркер для публичного доступа
        return true;
      } else {
        // ignore: avoid_print
        debugPrint('First proxy failed, trying alternative proxy...');
        // Try alternative CORS proxy
        try {
          final altProxyUrl = 'https://cors-anywhere.herokuapp.com/${Uri.encodeComponent(redditUrl)}';
          final altResponse = await http.get(
            Uri.parse(altProxyUrl),
            headers: {
              'User-Agent': _userAgent,
              'X-Requested-With': 'XMLHttpRequest',
            },
          ).timeout(const Duration(seconds: 10));
          
          if (altResponse.statusCode == 200) {
            // ignore: avoid_print
            debugPrint('Alternative proxy successful');
            _accessToken = 'public';
            return true;
          }
        } catch (e) {
          // ignore: avoid_print
          debugPrint('Alternative proxy failed: $e');
        }
        
        // Final fallback to direct access
        // ignore: avoid_print
        debugPrint('All proxies failed, trying direct access...');
        final directResponse = await http.get(
          Uri.parse(redditUrl),
          headers: {
            'User-Agent': _userAgent,
          },
        ).timeout(const Duration(seconds: 10));
        
        if (directResponse.statusCode == 200) {
          // ignore: avoid_print
          debugPrint('Direct Reddit access successful');
          _accessToken = 'public';
          return true;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Public Reddit access failed: $e');
    }
    return false;
  }

  /// Получение образовательных постов с РЕАЛЬНЫМИ изображениями
  Future<List<RedditPost>> getEducationalPostsWithRealImages({
    String subreddit = 'learning',
    int limit = 25,
    String sort = 'hot',
  }) async {
    if (_accessToken == null) {
      final authenticated = await authenticate();
      if (!authenticated) {
        return [];
      }
    }

    try {
      String url;
      Map<String, String> headers;
      
      if (_accessToken == 'public') {
        // Используем CORS proxy для публичного доступа
        final redditUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=$limit';
        url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(redditUrl)}';
        headers = {'User-Agent': _userAgent};
      } else {
        // OAuth доступ
        url = 'https://oauth.reddit.com/r/$subreddit/$sort?limit=$limit';
        headers = {
          'User-Agent': _userAgent,
          'Authorization': 'Bearer $_accessToken',
        };
      }

      http.Response response;
      try {
        response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Proxy failed, trying direct access: $e');
        // Fallback to direct access
        if (_accessToken == 'public') {
          final directUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=$limit';
          response = await http.get(
            Uri.parse(directUrl),
            headers: {'User-Agent': _userAgent},
          ).timeout(const Duration(seconds: 10));
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final posts = <RedditPost>[];

        for (var postData in data['data']['children']) {
          final post = postData['data'];
          
          // Фильтруем только образовательный контент
          if (_isEducationalContent(post)) {
            // Извлекаем РЕАЛЬНОЕ изображение
            final realImageInfo = await RedditRealImageService.extractRealImageUrl(post);
            
            if (realImageInfo != null) {
              posts.add(RedditPost.fromJsonWithRealImage(post, realImageInfo));
            } else {
              // Если реальное изображение не найдено, используем обычный метод
              posts.add(RedditPost.fromJson(post));
            }
          }
        }

        return posts;
      }
    } catch (e) {
      debugPrint('Error fetching Reddit posts: $e');
    }

    return [];
  }

  /// Получение образовательных постов из r/learning (старый метод)
  Future<List<RedditPost>> getEducationalPosts({
    String subreddit = 'learning',
    int limit = 25,
    String sort = 'hot',
  }) async {
    if (_accessToken == null) {
      final authenticated = await authenticate();
      if (!authenticated) {
        return [];
      }
    }

    try {
      String url;
      Map<String, String> headers;
      
      if (_accessToken == 'public') {
        // Используем CORS proxy для публичного доступа
        final redditUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=$limit';
        url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(redditUrl)}';
        headers = {'User-Agent': _userAgent};
      } else {
        // OAuth доступ
        url = 'https://oauth.reddit.com/r/$subreddit/$sort?limit=$limit';
        headers = {
          'User-Agent': _userAgent,
          'Authorization': 'Bearer $_accessToken',
        };
      }

      http.Response response;
      try {
        response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Proxy failed, trying direct access: $e');
        // Fallback to direct access
        if (_accessToken == 'public') {
          final directUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=$limit';
          response = await http.get(
            Uri.parse(directUrl),
            headers: {'User-Agent': _userAgent},
          ).timeout(const Duration(seconds: 10));
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final posts = <RedditPost>[];

        for (var postData in data['data']['children']) {
          final post = postData['data'];
          
          // Фильтруем только образовательный контент
          if (_isEducationalContent(post)) {
            posts.add(RedditPost.fromJson(post));
          }
        }

        return posts;
      }
    } catch (e) {
      debugPrint('Error fetching Reddit posts: $e');
    }

    return [];
  }

  /// Поиск образовательного контента
  Future<List<RedditPost>> searchEducationalContent({
    required String query,
    String subreddit = 'learning',
    int limit = 25,
  }) async {
    if (_accessToken == null) {
      final authenticated = await authenticate();
      if (!authenticated) {
        return [];
      }
    }

    try {
      String url;
      Map<String, String> headers;
      
      if (_accessToken == 'public') {
        // Используем CORS proxy для публичного доступа
        final redditUrl = 'https://www.reddit.com/r/$subreddit/search.json?q=$query&limit=$limit&sort=relevance';
        url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(redditUrl)}';
        headers = {'User-Agent': _userAgent};
      } else {
        // OAuth доступ
        url = 'https://oauth.reddit.com/r/$subreddit/search?q=$query&limit=$limit&sort=relevance';
        headers = {
          'User-Agent': _userAgent,
          'Authorization': 'Bearer $_accessToken',
        };
      }

      http.Response response;
      try {
        response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Search proxy failed, trying direct access: $e');
        // Fallback to direct access
        if (_accessToken == 'public') {
          final directUrl = 'https://www.reddit.com/r/$subreddit/search.json?q=$query&limit=$limit&sort=relevance';
          response = await http.get(
            Uri.parse(directUrl),
            headers: {'User-Agent': _userAgent},
          ).timeout(const Duration(seconds: 10));
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        try {
          // Check if response is valid JSON
          if (response.body.trim().startsWith('<')) {
            // ignore: avoid_print
            debugPrint('Received HTML instead of JSON, trying direct access');
            throw FormatException('HTML response received');
          }
          
          final data = jsonDecode(response.body);
          final posts = <RedditPost>[];

          for (var postData in data['data']['children']) {
            final post = postData['data'];
            
            if (_isEducationalContent(post)) {
              posts.add(RedditPost.fromJson(post));
            }
          }

          return posts;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('JSON parsing failed, trying direct access: $e');
          // Try direct access as fallback
          if (_accessToken == 'public') {
            final directUrl = 'https://www.reddit.com/r/$subreddit/search.json?q=$query&limit=$limit&sort=relevance';
            final directResponse = await http.get(
              Uri.parse(directUrl),
              headers: {'User-Agent': _userAgent},
            ).timeout(const Duration(seconds: 10));
            
            if (directResponse.statusCode == 200) {
              final data = jsonDecode(directResponse.body);
              final posts = <RedditPost>[];

              for (var postData in data['data']['children']) {
                final post = postData['data'];
                
                if (_isEducationalContent(post)) {
                  posts.add(RedditPost.fromJson(post));
                }
              }

              return posts;
            }
          }
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error searching Reddit: $e');
    }

    return [];
  }

  /// Проверка, является ли контент образовательным
  bool _isEducationalContent(Map<String, dynamic> post) {
    final title = post['title']?.toString().toLowerCase() ?? '';
    final selftext = post['selftext']?.toString().toLowerCase() ?? '';
    final subreddit = post['subreddit']?.toString().toLowerCase() ?? '';
    
    // Образовательные ключевые слова
    final educationalKeywords = [
      'learn', 'study', 'education', 'tutorial', 'course', 'lesson',
      'explain', 'understand', 'knowledge', 'skill', 'practice',
      'учить', 'изучать', 'обучение', 'курс', 'урок', 'объяснить',
      'понимать', 'знания', 'навык', 'практика'
    ];

    // Образовательные субреддиты
    final educationalSubreddits = [
      'learning', 'education', 'studytips', 'getmotivated',
      'todayilearned', 'explainlikeimfive', 'askscience',
      'math', 'physics', 'chemistry', 'biology', 'programming',
      'languagelearning', 'cooking', 'diy', 'lifeprotips'
    ];

    // Проверяем ключевые слова в заголовке и тексте
    final hasEducationalKeywords = educationalKeywords.any(
      (keyword) => title.contains(keyword) || selftext.contains(keyword)
    );

    // Проверяем образовательные субреддиты
    final isEducationalSubreddit = educationalSubreddits.contains(subreddit);

    // Исключаем NSFW и неподходящий контент
    final isNotNsfw = !post['over_18'] && 
                      !title.contains('nsfw') && 
                      !selftext.contains('nsfw');

    return (hasEducationalKeywords || isEducationalSubreddit) && isNotNsfw;
  }

  /// Получение развлекательных постов
  Future<List<RedditPost>> getEntertainmentPosts({
    int limit = 25,
    String sort = 'hot',
  }) async {
    if (_accessToken == null) {
      final authenticated = await authenticate();
      if (!authenticated) {
        return [];
      }
    }

    try {
      final entertainmentSubreddits = await getEntertainmentSubreddits();
      final allPosts = <RedditPost>[];

      // Загружаем посты из нескольких развлекательных субреддитов
      for (final subreddit in entertainmentSubreddits.take(3)) {
        try {
          String url;
          Map<String, String> headers;
          
          if (_accessToken == 'public') {
            // Используем CORS proxy для публичного доступа
            final redditUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=${(limit / 3).ceil()}';
            url = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(redditUrl)}';
            headers = {'User-Agent': _userAgent};
          } else {
            // OAuth доступ
            url = 'https://oauth.reddit.com/r/$subreddit/$sort?limit=${(limit / 3).ceil()}';
            headers = {
              'User-Agent': _userAgent,
              'Authorization': 'Bearer $_accessToken',
            };
          }

          http.Response response;
          try {
            response = await http.get(
              Uri.parse(url),
              headers: headers,
            ).timeout(const Duration(seconds: 15));
          } catch (e) {
            // ignore: avoid_print
            debugPrint('Entertainment proxy failed for $subreddit, trying direct access: $e');
            // Fallback to direct access
            if (_accessToken == 'public') {
              final directUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=${(limit / 3).ceil()}';
              response = await http.get(
                Uri.parse(directUrl),
                headers: {'User-Agent': _userAgent},
              ).timeout(const Duration(seconds: 10));
            } else {
              rethrow;
            }
          }

          if (response.statusCode == 200) {
            try {
              // Check if response is valid JSON
              if (response.body.trim().startsWith('<')) {
                // ignore: avoid_print
                debugPrint('Received HTML instead of JSON for r/$subreddit, trying direct access');
                throw FormatException('HTML response received');
              }
              
              final data = jsonDecode(response.body);
              final posts = <RedditPost>[];

              for (var postData in data['data']['children']) {
                final post = postData['data'];
                
                // Фильтруем развлекательный контент
                if (_isEntertainmentContent(post)) {
                  posts.add(RedditPost.fromJson(post));
                }
              }

              allPosts.addAll(posts);
            } catch (e) {
              // ignore: avoid_print
              debugPrint('JSON parsing failed for r/$subreddit, trying direct access: $e');
              // Try direct access as fallback
              if (_accessToken == 'public') {
                final directUrl = 'https://www.reddit.com/r/$subreddit/$sort.json?limit=${(limit / 3).ceil()}';
                final directResponse = await http.get(
                  Uri.parse(directUrl),
                  headers: {'User-Agent': _userAgent},
                ).timeout(const Duration(seconds: 10));
                
                if (directResponse.statusCode == 200) {
                  final data = jsonDecode(directResponse.body);
                  final posts = <RedditPost>[];

                  for (var postData in data['data']['children']) {
                    final post = postData['data'];
                    
                    if (_isEntertainmentContent(post)) {
                      posts.add(RedditPost.fromJson(post));
                    }
                  }

                  allPosts.addAll(posts);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching posts from r/$subreddit: $e');
        }
      }

      return allPosts.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching entertainment posts: $e');
    }

    return [];
  }

  /// Проверка, является ли контент развлекательным
  bool _isEntertainmentContent(Map<String, dynamic> post) {
    final title = post['title']?.toString().toLowerCase() ?? '';
    final selftext = post['selftext']?.toString().toLowerCase() ?? '';
    final subreddit = post['subreddit']?.toString().toLowerCase() ?? '';
    
    // Развлекательные ключевые слова
    final entertainmentKeywords = [
      'fun', 'funny', 'joke', 'meme', 'comedy', 'entertainment',
      'interesting', 'cool', 'awesome', 'amazing', 'wow',
      'funny', 'смешно', 'прикол', 'мем', 'комедия', 'развлечение',
      'интересно', 'круто', 'классно', 'удивительно'
    ];

    // Развлекательные субреддиты
    final entertainmentSubreddits = [
      'funny', 'memes', 'jokes', 'comedy', 'entertainment',
      'interestingasfuck', 'nextfuckinglevel', 'mildlyinteresting',
      'oddlysatisfying', 'wholesomememes', 'dankmemes',
      'gifs', 'videos', 'pics', 'aww', 'eyebleach'
    ];

    // Проверяем ключевые слова в заголовке и тексте
    final hasEntertainmentKeywords = entertainmentKeywords.any(
      (keyword) => title.contains(keyword) || selftext.contains(keyword)
    );

    // Проверяем развлекательные субреддиты
    final isEntertainmentSubreddit = entertainmentSubreddits.contains(subreddit);

    // Исключаем NSFW и неподходящий контент
    final isNotNsfw = !post['over_18'] && 
                      !title.contains('nsfw') && 
                      !selftext.contains('nsfw');

    return (hasEntertainmentKeywords || isEntertainmentSubreddit) && isNotNsfw;
  }

  /// Получение популярных образовательных субреддитов
  Future<List<String>> getEducationalSubreddits() async {
    return [
      'learning',
      'education', 
      'studytips',
      'todayilearned',
      'explainlikeimfive',
      'askscience',
      'math',
      'physics',
      'chemistry',
      'biology',
      'programming',
      'languagelearning',
      'cooking',
      'diy',
      'lifeprotips',
      'getmotivated',
      'productivity',
      'selfimprovement',
    ];
  }

  /// Получение популярных развлекательных субреддитов
  Future<List<String>> getEntertainmentSubreddits() async {
    return [
      'funny',
      'memes',
      'jokes',
      'comedy',
      'entertainment',
      'interestingasfuck',
      'nextfuckinglevel',
      'mildlyinteresting',
      'oddlysatisfying',
      'wholesomememes',
      'dankmemes',
      'gifs',
      'videos',
      'pics',
      'aww',
      'eyebleach',
      'MadeMeSmile',
      'Unexpected',
      'PublicFreakout',
      'ContagiousLaughter',
    ];
  }

  /// Проверка доступности API
  Future<bool> isAvailable() async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      return false;
    }

    try {
      return await authenticate();
    } catch (e) {
      return false;
    }
  }

  /// Получение информации о конфигурации
  Map<String, dynamic> getConfigInfo() {
    return {
      'hasClientId': _clientId.isNotEmpty,
      'hasClientSecret': _clientSecret.isNotEmpty,
      'userAgent': _userAgent,
      'isAuthenticated': _accessToken != null,
    };
  }
}

/// Модель поста Reddit
class RedditPost {
  final String id;
  final String title;
  final String author;
  final String subreddit;
  final String? selftext;
  final String? url;
  final String? thumbnail;
  final String? realImageUrl;  // РЕАЛЬНЫЙ URL изображения
  final String? imageType;     // Тип изображения
  final bool imageIsValid;     // Валидность изображения
  final int score;
  final int numComments;
  final DateTime created;
  final bool isVideo;
  final String? videoUrl;
  final String? videoThumbnail;

  RedditPost({
    required this.id,
    required this.title,
    required this.author,
    required this.subreddit,
    this.selftext,
    this.url,
    this.thumbnail,
    this.realImageUrl,
    this.imageType,
    this.imageIsValid = false,
    required this.score,
    required this.numComments,
    required this.created,
    this.isVideo = false,
    this.videoUrl,
    this.videoThumbnail,
  });

  /// Создание поста с реальным изображением
  factory RedditPost.fromJsonWithRealImage(Map<String, dynamic> json, RedditImageInfo imageInfo) {
    // ИСПРАВЛЕНИЕ: Правильная ссылка на пост Reddit
    final redditPostUrl = 'https://www.reddit.com${json['permalink'] ?? ''}';
    
    return RedditPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      subreddit: json['subreddit'] ?? '',
      selftext: json['selftext'],
      url: redditPostUrl, // ИСПРАВЛЕНО: Используем permalink для ссылки на пост
      thumbnail: json['thumbnail'],
      realImageUrl: imageInfo.url,
      imageType: imageInfo.type,
      imageIsValid: imageInfo.isValid,
      score: json['score'] ?? 0,
      numComments: json['num_comments'] ?? 0,
      created: DateTime.fromMillisecondsSinceEpoch(
        (json['created_utc'] ?? 0) * 1000,
      ),
      isVideo: json['is_video'] ?? false,
      videoUrl: json['media']?['reddit_video']?['fallback_url'],
      videoThumbnail: imageInfo.url, // Используем реальное изображение как thumbnail
    );
  }

  factory RedditPost.fromJson(Map<String, dynamic> json) {
    // Извлекаем лучшее превью изображение
    String? bestThumbnail;
    
    // 1. Пробуем preview изображения (лучшее качество)
    if (json['preview']?['images']?[0]?['source']?['url'] != null) {
      bestThumbnail = json['preview']['images'][0]['source']['url']
          .toString()
          .replaceAll('&amp;', '&');
    }
    // 2. Пробуем preview изображения меньшего размера
    else if (json['preview']?['images']?[0]?['resolutions'] != null) {
      final resolutions = json['preview']['images'][0]['resolutions'] as List;
      if (resolutions.isNotEmpty) {
        final largest = resolutions.last;
        if (largest['url'] != null) {
          bestThumbnail = largest['url']
              .toString()
              .replaceAll('&amp;', '&');
        }
      }
    }
    // 3. Пробуем обычный thumbnail
    else if (json['thumbnail'] != null && 
             json['thumbnail'] != 'self' && 
             json['thumbnail'] != 'default' &&
             json['thumbnail'] != 'nsfw') {
      bestThumbnail = json['thumbnail'];
    }
    
    // ИСПРАВЛЕНИЕ: Правильная ссылка на пост Reddit
    final redditPostUrl = 'https://www.reddit.com${json['permalink'] ?? ''}';
    
    return RedditPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      subreddit: json['subreddit'] ?? '',
      selftext: json['selftext'],
      url: redditPostUrl, // ИСПРАВЛЕНО: Используем permalink для ссылки на пост
      thumbnail: json['thumbnail'],
      score: json['score'] ?? 0,
      numComments: json['num_comments'] ?? 0,
      created: DateTime.fromMillisecondsSinceEpoch(
        (json['created_utc'] ?? 0) * 1000,
      ),
      isVideo: json['is_video'] ?? false,
      videoUrl: json['media']?['reddit_video']?['fallback_url'],
      videoThumbnail: bestThumbnail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'subreddit': subreddit,
      'selftext': selftext,
      'url': url,
      'thumbnail': thumbnail,
      'score': score,
      'numComments': numComments,
      'created': created.toIso8601String(),
      'isVideo': isVideo,
      'videoUrl': videoUrl,
      'videoThumbnail': videoThumbnail,
    };
  }

  /// Получить URL для отображения
  String get displayUrl {
    if (isVideo && videoUrl != null) {
      return videoUrl!;
    }
    if (url != null && url!.isNotEmpty) {
      return url!;
    }
    return '';
  }

  /// Получить превью изображение
  String? get displayThumbnail {
    if (videoThumbnail != null) {
      return videoThumbnail;
    }
    if (thumbnail != null && thumbnail != 'self' && thumbnail != 'default') {
      return thumbnail;
    }
    return null;
  }

  /// Проверить, является ли пост видео
  bool get hasVideo => isVideo && videoUrl != null;

  /// Получить краткое описание
  String get shortDescription {
    if (selftext != null && selftext!.isNotEmpty) {
      return selftext!.length > 200 
          ? '${selftext!.substring(0, 200)}...'
          : selftext!;
    }
    return '';
  }

  /// Получить URL для отображения (с прокси если нужно)
  String get displayImageUrl {
    if (realImageUrl != null && imageIsValid) {
      return RedditRealImageService.getProxiedImageUrl(realImageUrl!);
    }
    return '';
  }

  /// Проверить, есть ли реальное изображение
  bool get hasRealImage => realImageUrl != null && imageIsValid;

  /// Получить информацию об изображении
  String get imageInfo {
    if (realImageUrl == null) return 'Нет изображения';
    return '${imageType ?? 'unknown'} (${imageIsValid ? 'валидное' : 'невалидное'})';
  }
}
