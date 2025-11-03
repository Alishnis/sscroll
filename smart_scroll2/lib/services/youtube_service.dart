import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/secrets.dart';
import '../models/video_model.dart';

/// YouTube API Service
/// Получение образовательных видео с YouTube
class YouTubeService {
  final String _apiKey;

  YouTubeService()
      : _apiKey = ApiConfig.youtubeApiKey.isNotEmpty
            ? ApiConfig.youtubeApiKey
            : Secrets.youtubeApiKey;

  /// Проверка доступности YouTube API
  bool get isAvailable => _apiKey.isNotEmpty;

  /// Публичный метод поиска видео
  Future<List<VideoModel>> searchVideos({
    String query = 'educational',
    int maxResults = 10,
    String order = 'relevance',
    String videoDuration = 'any',
  }) async {
    return await searchEducationalVideos(
      query: query,
      maxResults: maxResults,
      order: order,
      videoDuration: videoDuration,
    );
  }

  /// Поиск образовательных видео на YouTube
  Future<List<VideoModel>> searchEducationalVideos({
    String query = 'educational',
    int maxResults = 10,
    String order = 'relevance',
    String videoDuration = 'any', // short, medium, long, any
  }) async {
    if (!isAvailable) {
      throw Exception('YouTube API key not configured');
    }

    try {
      // Поиск видео
      final searchResponse = await _searchVideos(
        query: query,
        maxResults: maxResults,
        order: order,
        videoDuration: videoDuration,
      );

      if (searchResponse['items'] == null) {
        return [];
      }

      final List<VideoModel> videos = [];

      for (var item in searchResponse['items']) {
        final videoId = item['id']['videoId'];
        final snippet = item['snippet'];

        // Получаем детальную информацию о видео
        final videoDetails = await _getVideoDetails(videoId);
        
        if (videoDetails != null) {
          final video = VideoModel(
            id: videoId,
            title: snippet['title'] ?? 'Без названия',
            description: snippet['description'] ?? '',
            videoUrl: 'https://www.youtube.com/watch?v=$videoId',
            thumbnailUrl: snippet['thumbnails']['high']['url'] ?? '',
            source: 'YouTube',
            sourceUrl: 'https://www.youtube.com/watch?v=$videoId',
            author: snippet['channelTitle'] ?? 'Неизвестный автор',
            category: _mapQueryToCategory(query),
            duration: _parseDuration(videoDetails['contentDetails']['duration']),
            views: int.tryParse(videoDetails['statistics']['viewCount'] ?? '0') ?? 0,
            likes: int.tryParse(videoDetails['statistics']['likeCount'] ?? '0') ?? 0,
            uploadDate: DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
            tags: _extractTags(snippet['tags']),
          );

          videos.add(video);
        }
      }

      return videos;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('YouTube API error: $e');
      throw Exception('Failed to fetch YouTube videos: $e');
    }
  }

  /// Поиск видео по запросу
  Future<Map<String, dynamic>> _searchVideos({
    required String query,
    required int maxResults,
    required String order,
    required String videoDuration,
  }) async {
    final uri = Uri.parse('https://www.googleapis.com/youtube/v3/search').replace(
      queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'order': order,
        'videoDuration': videoDuration,
        'key': _apiKey,
      },
    );

    final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Квота превышена - возвращаем пустой результат
        debugPrint('YouTube API quota exceeded, using fallback');
        return {'items': []};
      } else {
        throw Exception('YouTube API error: ${response.statusCode} ${response.body}');
      }
  }

  /// Получение детальной информации о видео
  Future<Map<String, dynamic>?> _getVideoDetails(String videoId) async {
    try {
      final uri = Uri.parse('https://www.googleapis.com/youtube/v3/videos').replace(
        queryParameters: {
          'part': 'contentDetails,statistics',
          'id': videoId,
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0];
        }
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error fetching video details: $e');
    }
    return null;
  }

  /// Парсинг длительности видео из ISO 8601 формата
  int _parseDuration(String? duration) {
    if (duration == null) return 0;

    // Убираем 'PT' и парсим
    final cleanDuration = duration.replaceAll('PT', '');
    int totalSeconds = 0;

    // Часы
    final hoursMatch = RegExp(r'(\d+)H').firstMatch(cleanDuration);
    if (hoursMatch != null) {
      totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
    }

    // Минуты
    final minutesMatch = RegExp(r'(\d+)M').firstMatch(cleanDuration);
    if (minutesMatch != null) {
      totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
    }

    // Секунды
    final secondsMatch = RegExp(r'(\d+)S').firstMatch(cleanDuration);
    if (secondsMatch != null) {
      totalSeconds += int.parse(secondsMatch.group(1)!);
    }

    return totalSeconds;
  }

  /// Извлечение тегов из snippet
  List<String> _extractTags(List<dynamic>? tags) {
    if (tags == null) return [];
    return tags.cast<String>();
  }

  /// Маппинг поискового запроса в категорию
  String _mapQueryToCategory(String query) {
    const categoryMap = {
      'programming': 'Программирование',
      'python': 'Программирование',
      'javascript': 'Программирование',
      'web development': 'Программирование',
      'machine learning': 'Программирование',
      'data science': 'Программирование',
      'math': 'Математика',
      'mathematics': 'Математика',
      'physics': 'Физика',
      'chemistry': 'Химия',
      'biology': 'Биология',
      'history': 'История',
      'language': 'Языки',
      'language learning': 'Языки',
      'cooking': 'Кулинария',
      'art': 'Искусство',
      'music': 'Музыка',
      'science': 'Наука',
      'educational': 'Образование',
      'tutorial': 'Образование',
      'course': 'Образование',
    };

    final lowerQuery = query.toLowerCase();
    for (final entry in categoryMap.entries) {
      if (lowerQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Образование';
  }

  /// Поиск видео по категории
  Future<List<VideoModel>> getVideosByCategory(String category) async {
    final query = _categoryToQuery(category);
    return await searchEducationalVideos(
      query: query,
      maxResults: 10,
      order: 'relevance',
      videoDuration: 'short',
    );
  }

  /// Маппинг категории в поисковый запрос
  String _categoryToQuery(String category) {
    const queryMap = {
      'Программирование': 'programming tutorial',
      'Математика': 'mathematics lesson',
      'Физика': 'physics explained',
      'Химия': 'chemistry tutorial',
      'Биология': 'biology lesson',
      'История': 'history documentary',
      'Языки': 'language learning',
      'Кулинария': 'cooking tutorial',
      'Искусство': 'art tutorial',
      'Музыка': 'music lesson',
      'Наука': 'science explained',
      'Образование': 'educational video',
    };

    return queryMap[category] ?? 'educational video';
  }

  /// Поиск трендовых образовательных видео
  Future<List<VideoModel>> getTrendingEducationalVideos({
    int maxResults = 10,
  }) async {
    return await searchEducationalVideos(
      query: 'educational trending',
      maxResults: maxResults,
      order: 'viewCount',
      videoDuration: 'any',
    );
  }

  /// Поиск коротких образовательных видео
  Future<List<VideoModel>> getShortEducationalVideos({
    String query = 'educational',
    int maxResults = 10,
  }) async {
    return await searchEducationalVideos(
      query: query,
      maxResults: maxResults,
      order: 'relevance',
      videoDuration: 'short',
    );
  }

  /// Поиск полных образовательных видео (любой длительности)
  Future<List<VideoModel>> getFullEducationalVideos({
    String query = 'educational',
    int maxResults = 10,
  }) async {
    return await searchEducationalVideos(
      query: query,
      maxResults: maxResults,
      order: 'relevance',
      videoDuration: 'any',
    );
  }

  /// Поиск видео по интересам пользователя
  Future<List<VideoModel>> getVideosByInterests(List<String> interests) async {
    if (interests.isEmpty) {
      return await getTrendingEducationalVideos();
    }

    final List<VideoModel> allVideos = [];

    for (final interest in interests.take(3)) { // Ограничиваем до 3 интересов
      try {
        final videos = await searchEducationalVideos(
          query: interest,
          maxResults: 5,
          order: 'relevance',
          videoDuration: 'any',
        );
        allVideos.addAll(videos);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Error fetching videos for interest "$interest": $e');
      }
    }

    // Убираем дубликаты по ID
    final uniqueVideos = <String, VideoModel>{};
    for (final video in allVideos) {
      uniqueVideos[video.id] = video;
    }

    return uniqueVideos.values.toList();
  }
}
