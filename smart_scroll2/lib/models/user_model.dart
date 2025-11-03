class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final List<String> interests;
  final bool isAccessibilityEnabled;
  final List<String> joinedGroups;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role = UserRole.student,
    this.interests = const [],
    this.isAccessibilityEnabled = false,
    this.joinedGroups = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.student,
      ),
      interests: List<String>.from(json['interests'] ?? []),
      isAccessibilityEnabled: json['isAccessibilityEnabled'] ?? false,
      joinedGroups: List<String>.from(json['joinedGroups'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.toString().split('.').last,
      'interests': interests,
      'isAccessibilityEnabled': isAccessibilityEnabled,
      'joinedGroups': joinedGroups,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserRole? role,
    List<String>? interests,
    bool? isAccessibilityEnabled,
    List<String>? joinedGroups,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      interests: interests ?? this.interests,
      isAccessibilityEnabled: isAccessibilityEnabled ?? this.isAccessibilityEnabled,
      joinedGroups: joinedGroups ?? this.joinedGroups,
    );
  }
}

enum UserRole {
  student,
  mentor,
  teacher,
  admin,
}

