import 'video_model.dart';
import 'post_model.dart';

/// Модель элемента ленты (видео или пост)
class FeedItemModel {
  final String id;
  final String type; // 'video' или 'post'
  final VideoModel? video;
  final PostModel? post;
  final DateTime createdAt;

  FeedItemModel({
    required this.id,
    required this.type,
    this.video,
    this.post,
    required this.createdAt,
  });

  factory FeedItemModel.fromVideo(VideoModel video) {
    return FeedItemModel(
      id: 'video_${video.id}',
      type: 'video',
      video: video,
      createdAt: video.uploadDate,
    );
  }

  factory FeedItemModel.fromPost(PostModel post) {
    return FeedItemModel(
      id: 'post_${post.id}',
      type: 'post',
      post: post,
      createdAt: post.created,
    );
  }

  /// Получить заголовок
  String get title {
    return type == 'video' ? video!.title : post!.title;
  }

  /// Получить автора
  String get author {
    return type == 'video' ? video!.author : post!.author;
  }

  /// Получить источник
  String get source {
    return type == 'video' ? video!.source : 'Reddit';
  }

  /// Получить категорию
  String get category {
    return type == 'video' ? video!.category : post!.category;
  }

  /// Получить описание
  String get description {
    return type == 'video' ? video!.description : post!.shortDescription;
  }

  /// Получить URL превью
  String? get thumbnailUrl {
    return type == 'video' ? video!.thumbnailUrl : post!.displayThumbnail;
  }

  /// Получить URL для перехода
  String get sourceUrl {
    return type == 'video' ? video!.sourceUrl : post!.displayUrl;
  }

  /// Получить теги
  List<String> get tags {
    return type == 'video' ? video!.tags : post!.tags;
  }

  /// Получить количество лайков
  int get likes {
    return type == 'video' ? video!.likes : post!.score;
  }

  /// Получить количество просмотров/комментариев
  int get engagement {
    return type == 'video' ? video!.views : post!.numComments;
  }

  /// Получить количество просмотров
  int get views {
    return type == 'video' ? video!.views : post!.score;
  }

  /// Получить длительность (для видео)
  String? get duration {
    return type == 'video' ? _formatDuration(video!.duration) : null;
  }

  /// Форматирование длительности из секунд в строку
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// Проверить, является ли элемент видео
  bool get isVideo => type == 'video';

  /// Проверить, является ли элемент постом
  bool get isPost => type == 'post';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'video': video?.toJson(),
      'post': post?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    return FeedItemModel(
      id: json['id'],
      type: json['type'],
      video: json['video'] != null ? VideoModel.fromJson(json['video']) : null,
      post: json['post'] != null ? PostModel.fromJson(json['post']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
