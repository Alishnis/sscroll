class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String source; // YouTube, Coursera, Reddit, etc.
  final String sourceUrl; // Original source link
  final String author;
  final String category;
  final int duration; // in seconds
  final int views;
  final int likes;
  final DateTime uploadDate;
  final List<String> tags;
  final String? summary; // AI-generated summary
  final List<Subtitle>? subtitles;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.source,
    required this.sourceUrl,
    required this.author,
    required this.category,
    required this.duration,
    this.views = 0,
    this.likes = 0,
    required this.uploadDate,
    this.tags = const [],
    this.summary,
    this.subtitles,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      source: json['source'],
      sourceUrl: json['sourceUrl'],
      author: json['author'],
      category: json['category'],
      duration: json['duration'],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      uploadDate: DateTime.parse(json['uploadDate']),
      tags: List<String>.from(json['tags'] ?? []),
      summary: json['summary'],
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List)
              .map((s) => Subtitle.fromJson(s))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'source': source,
      'sourceUrl': sourceUrl,
      'author': author,
      'category': category,
      'duration': duration,
      'views': views,
      'likes': likes,
      'uploadDate': uploadDate.toIso8601String(),
      'tags': tags,
      'summary': summary,
      'subtitles': subtitles?.map((s) => s.toJson()).toList(),
    };
  }
}

class Subtitle {
  final String text;
  final int startTime; // in milliseconds
  final int endTime; // in milliseconds

  Subtitle({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      text: json['text'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

