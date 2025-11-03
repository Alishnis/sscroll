class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String mentorId;
  final String mentorName;
  final List<String> memberIds;
  final List<String> videoIds; // Shared videos for the group
  final DateTime createdAt;
  final String category;
  final bool isPrivate;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.mentorId,
    required this.mentorName,
    this.memberIds = const [],
    this.videoIds = const [],
    required this.createdAt,
    required this.category,
    this.isPrivate = false,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      mentorId: json['mentorId'],
      mentorName: json['mentorName'],
      memberIds: List<String>.from(json['memberIds'] ?? []),
      videoIds: List<String>.from(json['videoIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'],
      isPrivate: json['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'memberIds': memberIds,
      'videoIds': videoIds,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'isPrivate': isPrivate,
    };
  }

  int get memberCount => memberIds.length;
}

