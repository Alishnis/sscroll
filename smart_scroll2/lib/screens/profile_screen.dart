import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'tts_settings_screen.dart';
import '../widgets/tts_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Профиль',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Войдите в аккаунт'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Mock login
                      userProvider.setMockUser();
                    },
                    child: const Text('Войти (Demo)'),
                  ),
                ],
              ),
            );
          }

          final user = userProvider.currentUser!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32, color: Colors.blue),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_getRoleText(user.role)),
                      backgroundColor: _getRoleColor(user.role),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Settings section
              Text(
                'Настройки',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Accessibility toggle
              Card(
                child: TTSSwitch(
                  title: 'Режим доступности',
                  subtitle: 'Озвучивание и улучшенная навигация',
                  value: user.isAccessibilityEnabled,
                  onChanged: (value) {
                    userProvider.toggleAccessibility();
                  },
                  secondary: Icons.accessibility,
                ),
              ),
              const SizedBox(height: 8),
              
              // TTS Settings button
              Card(
                child: TTSListTile(
                  title: 'Настройки озвучки',
                  subtitle: 'Управление TTS и звуками кнопок',
                  leading: Icons.volume_up,
                  trailing: Icons.arrow_forward_ios,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TTSSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Interests section
              Text(
                'Интересы',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.blue[50],
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      final updatedInterests = user.interests
                          .where((i) => i != interest)
                          .toList();
                      userProvider.updateInterests(updatedInterests);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                onPressed: () {
                  _showAddInterestDialog(context, userProvider);
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить интерес'),
              ),
              const SizedBox(height: 24),
              
              // Statistics
              Text(
                'Статистика',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.group,
                      value: user.joinedGroups.length.toString(),
                      label: 'Групп',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatCard(
                      icon: Icons.video_library,
                      value: '42',
                      label: 'Просмотрено',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Logout button
              ElevatedButton.icon(
                onPressed: () {
                  userProvider.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Студент';
      case UserRole.mentor:
        return 'Ментор';
      case UserRole.teacher:
        return 'Преподаватель';
      case UserRole.admin:
        return 'Администратор';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.blue[100]!;
      case UserRole.mentor:
        return Colors.green[100]!;
      case UserRole.teacher:
        return Colors.orange[100]!;
      case UserRole.admin:
        return Colors.purple[100]!;
    }
  }

  void _showAddInterestDialog(BuildContext context, UserProvider userProvider) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить интерес'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Например: Программирование',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final updatedInterests = [
                    ...userProvider.currentUser!.interests,
                    controller.text.trim(),
                  ];
                  userProvider.updateInterests(updatedInterests);
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

