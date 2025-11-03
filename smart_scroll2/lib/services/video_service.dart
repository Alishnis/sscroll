import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import 'ai_service.dart';
import 'youtube_service.dart';

class VideoService {
  final AiService _aiService = AiService();
  final YouTubeService _youtubeService = YouTubeService();
  // Загрузка видео с YouTube API
  Future<List<VideoModel>> fetchVideos({String? category, String? groupId}) async {
    final List<VideoModel> allVideos = [];

    // 1. Загружаем видео с YouTube API
    if (_youtubeService.isAvailable) {
      try {
        final youtubeVideos = await _youtubeService.getTrendingEducationalVideos(
          maxResults: 20, // Увеличиваем количество
        );
        allVideos.addAll(youtubeVideos);
        debugPrint('YouTube API: загружено ${youtubeVideos.length} видео');
        
        // Если получили достаточно видео, возвращаем их
        if (youtubeVideos.length >= 5) {
          // Фильтрация по категории
          if (category != null) {
            return allVideos.where((video) => 
              video.category.toLowerCase().contains(category.toLowerCase())
            ).toList();
          }
          return allVideos;
        }
      } catch (e) {
        debugPrint('YouTube API error: $e');
        // Продолжаем выполнение, чтобы попробовать другие методы
      }
    }

    // 2. Если YouTube недоступен или вернул мало видео, пробуем другие запросы
    if (allVideos.length < 5 && _youtubeService.isAvailable) {
      try {
        // Пробуем разные образовательные запросы
        final educationalVideos = await _youtubeService.searchEducationalVideos(
          query: 'programming tutorial',
          maxResults: 10,
        );
        allVideos.addAll(educationalVideos);
        debugPrint('Educational videos: загружено ${educationalVideos.length} видео');
        
        if (allVideos.length < 5) {
          final scienceVideos = await _youtubeService.searchEducationalVideos(
            query: 'science explained',
            maxResults: 10,
          );
          allVideos.addAll(scienceVideos);
          debugPrint('Science videos: загружено ${scienceVideos.length} видео');
        }
      } catch (e) {
        debugPrint('Additional YouTube queries error: $e');
      }
    }

    // 3. Только если YouTube полностью недоступен, используем минимальный fallback
    if (allVideos.isEmpty && !_youtubeService.isAvailable) {
      debugPrint('YouTube API недоступен, используем минимальный fallback');
      // Возвращаем только одно демо видео вместо полного массива
      return [_mockVideos.first];
    }

    // 4. Фильтрация по категории
    if (category != null) {
      return allVideos.where((video) => 
        video.category.toLowerCase().contains(category.toLowerCase())
      ).toList();
    }

    return allVideos;
  }

  Future<String> generateSummary(String videoId) async {
    // Найти видео по ID
    final video = _mockVideos.firstWhere(
      (v) => v.id == videoId,
      orElse: () => _mockVideos.first,
    );
    
    // Если уже есть суммаризация, вернуть её
    if (video.summary != null && video.summary!.isNotEmpty) {
      return video.summary!;
    }
    
    // Генерация через AI сервис
    try {
      final summary = await _aiService.generateSummary(
        title: video.title,
        description: video.description,
      );
      return summary;
    } catch (e) {
      debugPrint('Error generating summary: $e');
      // Fallback на mock
      return "Краткое содержание: Это образовательное видео охватывает ключевые концепции темы. "
          "Основные моменты включают теоретические основы, практические примеры и рекомендации "
          "для дальнейшего изучения. Материал подходит для начинающих и среднего уровня.";
    }
  }

  Future<List<VideoModel>> getRecommendations(List<String> interests) async {
    final List<VideoModel> allVideos = [];

    // 1. Загружаем видео с YouTube по интересам
    if (_youtubeService.isAvailable && interests.isNotEmpty) {
      try {
        final youtubeVideos = await _youtubeService.getVideosByInterests(interests);
        allVideos.addAll(youtubeVideos);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('YouTube recommendations error: $e');
      }
    }

    // 2. Если YouTube недоступен или вернул мало видео, добавляем mock данные
    if (allVideos.length < 5) {
      allVideos.addAll(_mockVideos);
    }

    // 3. Фильтрация по интересам
    if (interests.isNotEmpty) {
      return allVideos.where((video) {
        return interests.any((interest) =>
          video.title.toLowerCase().contains(interest.toLowerCase()) ||
          video.description.toLowerCase().contains(interest.toLowerCase()) ||
          video.category.toLowerCase().contains(interest.toLowerCase()) ||
          video.tags.any((tag) => tag.toLowerCase().contains(interest.toLowerCase()))
        );
      }).toList();
    }

    return allVideos;
  }

  Future<List<VideoModel>> getGroupVideos(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // В реальном приложении фильтруем по groupId
    return _mockVideos.take(3).toList();
  }

  // Mock data
  static final List<VideoModel> _mockVideos = [
    VideoModel(
      id: '1',
      title: 'Введение в квантовую физику',
      description: 'Основы квантовой механики для начинающих. Узнайте о принципе неопределенности, волновой функции и многом другом.',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600?random=1',
      source: 'YouTube',
      sourceUrl: 'https://youtube.com/example1',
      author: 'Проф. Иванов А.С.',
      category: 'Физика',
      duration: 180,
      views: 15420,
      likes: 1230,
      uploadDate: DateTime.now().subtract(const Duration(days: 2)),
      tags: ['физика', 'квантовая механика', 'наука'],
      summary: 'Краткий обзор основ квантовой физики с примерами из реальной жизни.',
      subtitles: [
        Subtitle(text: 'Добро пожаловать в мир квантовой физики', startTime: 0, endTime: 3000),
        Subtitle(text: 'Сегодня мы рассмотрим основные принципы', startTime: 3000, endTime: 6000),
      ],
    ),
    VideoModel(
      id: '2',
      title: 'Основы машинного обучения',
      description: 'Узнайте основы ML, алгоритмы и практическое применение в современном мире.',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600?random=2',
      source: 'Coursera',
      sourceUrl: 'https://coursera.org/example2',
      author: 'Д-р Петрова М.В.',
      category: 'Программирование',
      duration: 240,
      views: 28900,
      likes: 2450,
      uploadDate: DateTime.now().subtract(const Duration(days: 5)),
      tags: ['ML', 'AI', 'программирование', 'данные'],
    ),
    VideoModel(
      id: '3',
      title: 'История Древнего Рима',
      description: 'Погружение в историю великой империи: от основания до падения.',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600?random=3',
      source: 'Cambridge',
      sourceUrl: 'https://cambridge.edu/example3',
      author: 'Проф. Смирнов И.П.',
      category: 'История',
      duration: 300,
      views: 19300,
      likes: 1890,
      uploadDate: DateTime.now().subtract(const Duration(days: 7)),
      tags: ['история', 'Рим', 'древний мир'],
    ),
    VideoModel(
      id: '4',
      title: 'Основы органической химии',
      description: 'Изучаем органические соединения, их свойства и реакции.',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600?random=4',
      source: 'YouTube',
      sourceUrl: 'https://youtube.com/example4',
      author: 'Проф. Волкова Е.А.',
      category: 'Химия',
      duration: 210,
      views: 12100,
      likes: 980,
      uploadDate: DateTime.now().subtract(const Duration(days: 10)),
      tags: ['химия', 'органика', 'наука'],
    ),
    VideoModel(
      id: '5',
      title: 'Английский язык: Present Perfect',
      description: 'Разбираем время Present Perfect с примерами и упражнениями.',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600?random=5',
      source: 'Reddit Learning',
      sourceUrl: 'https://reddit.com/r/learning/example5',
      author: 'Преп. Джонсон М.',
      category: 'Языки',
      duration: 150,
      views: 34200,
      likes: 3120,
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      tags: ['английский', 'грамматика', 'языки'],
    ),
  ];
}

