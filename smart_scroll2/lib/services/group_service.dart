import '../models/group_model.dart';

class GroupService {
  Future<List<GroupModel>> fetchGroups() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockGroups;
  }

  Future<List<GroupModel>> fetchUserGroups(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // В реальном приложении фильтруем по userId
    return _mockGroups;
  }

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required String mentorId,
    required String mentorName,
    required String category,
    bool isPrivate = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return GroupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      mentorId: mentorId,
      mentorName: mentorName,
      category: category,
      isPrivate: isPrivate,
      createdAt: DateTime.now(),
      memberIds: [mentorId],
    );
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // В реальном приложении обновляем на сервере
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // В реальном приложении обновляем на сервере
  }

  static final List<GroupModel> _mockGroups = [
    GroupModel(
      id: 'g1',
      name: 'Квантовая физика для начинающих',
      description: 'Изучаем основы квантовой механики вместе',
      imageUrl: 'https://picsum.photos/300/200?random=11',
      mentorId: 'm1',
      mentorName: 'Проф. Иванов А.С.',
      memberIds: ['m1', 'u1', 'u2', 'u3', 'u4', 'u5'],
      videoIds: ['1'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      category: 'Физика',
    ),
    GroupModel(
      id: 'g2',
      name: 'ML и AI: От теории к практике',
      description: 'Практический курс по машинному обучению',
      imageUrl: 'https://picsum.photos/300/200?random=12',
      mentorId: 'm2',
      mentorName: 'Д-р Петрова М.В.',
      memberIds: ['m2', 'u6', 'u7', 'u8'],
      videoIds: ['2'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      category: 'Программирование',
    ),
    GroupModel(
      id: 'g3',
      name: 'История Античности',
      description: 'Погружение в мир древних цивилизаций',
      imageUrl: 'https://picsum.photos/300/200?random=13',
      mentorId: 'm3',
      mentorName: 'Проф. Смирнов И.П.',
      memberIds: ['m3', 'u9', 'u10'],
      videoIds: ['3'],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      category: 'История',
      isPrivate: true,
    ),
  ];
}

