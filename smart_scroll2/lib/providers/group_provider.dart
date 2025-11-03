import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  
  List<GroupModel> _groups = [];
  List<GroupModel> _userGroups = [];
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get userGroups => _userGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _groupService.fetchGroups();
    } catch (e) {
      _error = 'Ошибка загрузки групп: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserGroups(String userId) async {
    try {
      _userGroups = await _groupService.fetchUserGroups(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка загрузки групп пользователя: $e';
      notifyListeners();
    }
  }

  Future<void> createGroup({
    required String name,
    required String description,
    required String mentorId,
    required String mentorName,
    required String category,
    bool isPrivate = false,
  }) async {
    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        mentorId: mentorId,
        mentorName: mentorName,
        category: category,
        isPrivate: isPrivate,
      );
      
      _groups.add(group);
      _userGroups.add(group);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка создания группы: $e';
      notifyListeners();
    }
  }

  Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _groupService.joinGroup(groupId, userId);
      
      final groupIndex = _groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        _userGroups.add(_groups[groupIndex]);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Ошибка при вступлении в группу: $e';
      notifyListeners();
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _groupService.leaveGroup(groupId, userId);
      
      _userGroups.removeWhere((g) => g.id == groupId);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка при выходе из группы: $e';
      notifyListeners();
    }
  }
}

