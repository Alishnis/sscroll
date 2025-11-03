/// Модель поста Reddit
class PostModel {
  final String id;
  final String title;
  final String author;
  final String subreddit;
  final String? content;
  final String? url;
  final String? thumbnail;
  final String? imageUrl;
  final int score;
  final int numComments;
  final int upvotes;
  final int comments;
  final DateTime created;
  final DateTime createdAt;
  final bool isVideo;
  final String? videoUrl;
  final String? videoThumbnail;
  final String category; // 'educational' или 'entertainment'
  final List<String> tags;

  PostModel({
    required this.id,
    required this.title,
    required this.author,
    required this.subreddit,
    this.content,
    this.url,
    this.thumbnail,
    this.imageUrl,
    required this.score,
    required this.numComments,
    required this.upvotes,
    required this.comments,
    required this.created,
    required this.createdAt,
    this.isVideo = false,
    this.videoUrl,
    this.videoThumbnail,
    required this.category,
    this.tags = const [],
  });

  factory PostModel.fromRedditPost(dynamic redditPost, String category) {
    // ИСПРАВЛЕНИЕ: Используем реальное изображение если доступно
    String? thumbnail;
    if (redditPost.hasRealImage && redditPost.realImageUrl != null) {
      thumbnail = redditPost.realImageUrl;
    } else if (redditPost.displayThumbnail != null) {
      thumbnail = redditPost.displayThumbnail;
    }
    
    return PostModel(
      id: redditPost.id ?? '',
      title: redditPost.title ?? '',
      author: redditPost.author ?? '',
      subreddit: redditPost.subreddit ?? '',
      content: redditPost.selftext,
      url: redditPost.url, // Теперь это правильная ссылка на пост Reddit
      thumbnail: thumbnail, // ИСПРАВЛЕНО: Используем реальное изображение
      imageUrl: thumbnail, // Use thumbnail as imageUrl
      score: redditPost.score ?? 0,
      numComments: redditPost.numComments ?? 0,
      upvotes: redditPost.score ?? 0, // Use score as upvotes
      comments: redditPost.numComments ?? 0, // Use numComments as comments
      created: redditPost.created,
      createdAt: redditPost.created, // Use created as createdAt
      isVideo: redditPost.isVideo ?? false,
      videoUrl: redditPost.videoUrl,
      videoThumbnail: redditPost.videoThumbnail,
      category: category,
      tags: _extractTags(redditPost.title, redditPost.selftext),
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      subreddit: json['subreddit'],
      content: json['content'],
      url: json['url'],
      thumbnail: json['thumbnail'],
      imageUrl: json['imageUrl'],
      score: json['score'],
      numComments: json['numComments'],
      upvotes: json['upvotes'] ?? json['score'] ?? 0,
      comments: json['comments'] ?? json['numComments'] ?? 0,
      created: DateTime.parse(json['created']),
      createdAt: DateTime.parse(json['createdAt'] ?? json['created']),
      isVideo: json['isVideo'] ?? false,
      videoUrl: json['videoUrl'],
      videoThumbnail: json['videoThumbnail'],
      category: json['category'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'subreddit': subreddit,
      'content': content,
      'url': url,
      'thumbnail': thumbnail,
      'score': score,
      'numComments': numComments,
      'created': created.toIso8601String(),
      'isVideo': isVideo,
      'videoUrl': videoUrl,
      'videoThumbnail': videoThumbnail,
      'category': category,
      'tags': tags,
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
    if (content != null && content!.isNotEmpty) {
      return content!.length > 200 
          ? '${content!.substring(0, 200)}...'
          : content!;
    }
    return '';
  }

  /// Извлечение тегов из заголовка и контента
  static List<String> _extractTags(String? title, String? content) {
    final text = '${title ?? ''} ${content ?? ''}'.toLowerCase();
    final tags = <String>[];
    
    // Образовательные теги
    final educationalKeywords = [
      'learn', 'study', 'education', 'tutorial', 'course', 'lesson',
      'explain', 'understand', 'knowledge', 'skill', 'practice',
      'programming', 'coding', 'development', 'math', 'science',
      'physics', 'chemistry', 'biology', 'history', 'language'
    ];
    
    for (final keyword in educationalKeywords) {
      if (text.contains(keyword)) {
        tags.add(keyword);
      }
    }
    
    return tags.take(5).toList(); // Ограничиваем до 5 тегов
  }
}
