import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Mock login - в реальном приложении будет интеграция с Firebase/Backend
  void login(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void toggleAccessibility() {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        isAccessibilityEnabled: !_currentUser!.isAccessibilityEnabled,
      );
      notifyListeners();
    }
  }

  void updateInterests(List<String> interests) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(interests: interests);
      notifyListeners();
    }
  }

  /// Обновление интересов с уведомлением VideoProvider
  void updateInterestsWithNotification(List<String> interests) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(interests: interests);
      notifyListeners();
    }
  }

  void joinGroup(String groupId) {
    if (_currentUser != null) {
      final updatedGroups = [..._currentUser!.joinedGroups, groupId];
      _currentUser = _currentUser!.copyWith(joinedGroups: updatedGroups);
      notifyListeners();
    }
  }

  void leaveGroup(String groupId) {
    if (_currentUser != null) {
      final updatedGroups = _currentUser!.joinedGroups
          .where((id) => id != groupId)
          .toList();
      _currentUser = _currentUser!.copyWith(joinedGroups: updatedGroups);
      notifyListeners();
    }
  }

  // Mock user для тестирования
  void setMockUser() {
    _currentUser = UserModel(
      id: 'user1',
      name: 'Иван Петров',
      email: 'ivan@example.com',
      role: UserRole.student,
      interests: ['Физика', 'Программирование', 'История'],
      isAccessibilityEnabled: false,
      joinedGroups: ['g1'],
    );
    notifyListeners();
  }
}

