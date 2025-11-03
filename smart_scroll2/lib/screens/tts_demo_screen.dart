import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tts_provider.dart';
import '../widgets/tts_button.dart';

/// Демонстрационный экран для показа TTS функционала
class TTSDemoScreen extends StatelessWidget {
  const TTSDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Демо TTS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<TTSProvider>(
        builder: (context, ttsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Статус TTS
              _buildStatusCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Демо кнопок
              _buildButtonsDemoCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Демо навигации
              _buildNavigationDemoCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Демо контента
              _buildContentDemoCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Настройки
              _buildSettingsCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ttsProvider.isEnabled ? Icons.volume_up : Icons.volume_off,
                  color: ttsProvider.isEnabled ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус озвучки',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ttsProvider.isEnabled ? 'Включена' : 'Выключена',
                        style: TextStyle(
                          color: ttsProvider.isEnabled ? Colors.green : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (ttsProvider.isEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusItem('Кнопки', ttsProvider.buttonSoundsEnabled),
                  const SizedBox(width: 16),
                  _buildStatusItem('Навигация', ttsProvider.navigationSoundsEnabled),
                  const SizedBox(width: 16),
                  _buildStatusItem('Контент', ttsProvider.contentSoundsEnabled),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool enabled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          color: enabled ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.green : Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsDemoCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Демо кнопок с TTS',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                TTSButton(
                  text: 'Обычная кнопка',
                  icon: Icons.touch_app,
                  onPressed: () => _showSnackBar(context, 'Обычная кнопка нажата!'),
                ),
                TTSButton(
                  text: 'Кнопка с иконкой',
                  icon: Icons.star,
                  backgroundColor: Colors.orange,
                  onPressed: () => _showSnackBar(context, 'Кнопка с иконкой нажата!'),
                ),
                TTSButton(
                  text: 'Вторичная кнопка',
                  icon: Icons.info,
                  backgroundColor: Colors.grey[200],
                  textColor: Colors.black87,
                  onPressed: () => _showSnackBar(context, 'Вторичная кнопка нажата!'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Иконки с TTS:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TTSIconButton(
                  icon: Icons.home,
                  tooltip: 'Главная',
                  onPressed: () => _showSnackBar(context, 'Навигация: Главная'),
                ),
                TTSIconButton(
                  icon: Icons.settings,
                  tooltip: 'Настройки',
                  onPressed: () => _showSnackBar(context, 'Навигация: Настройки'),
                ),
                TTSIconButton(
                  icon: Icons.favorite,
                  tooltip: 'Избранное',
                  onPressed: () => _showSnackBar(context, 'Навигация: Избранное'),
                ),
                TTSIconButton(
                  icon: Icons.share,
                  tooltip: 'Поделиться',
                  onPressed: () => _showSnackBar(context, 'Действие: Поделиться'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationDemoCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Демо навигации с TTS',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TTSListTile(
              title: 'Главная страница',
              subtitle: 'Переход на главную',
              leading: Icons.home,
              trailing: Icons.arrow_forward_ios,
              onTap: () => _showSnackBar(context, 'Навигация: Главная страница'),
            ),
            TTSListTile(
              title: 'Профиль пользователя',
              subtitle: 'Просмотр профиля',
              leading: Icons.person,
              trailing: Icons.arrow_forward_ios,
              onTap: () => _showSnackBar(context, 'Навигация: Профиль пользователя'),
            ),
            TTSListTile(
              title: 'Настройки приложения',
              subtitle: 'Конфигурация',
              leading: Icons.settings,
              trailing: Icons.arrow_forward_ios,
              onTap: () => _showSnackBar(context, 'Навигация: Настройки приложения'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDemoCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Демо озвучки контента',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пример поста',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Это пример текста поста, который может быть озвучен с помощью TTS. '
                    'Пользователи с нарушениями зрения смогут прослушать содержимое.',
                  ),
                  const SizedBox(height: 12),
                  TTSButton(
                    text: 'Озвучить пост',
                    icon: Icons.volume_up,
                    onPressed: () {
                      ttsProvider.speakContent(
                        'Это пример текста поста, который может быть озвучен с помощью TTS. '
                        'Пользователи с нарушениями зрения смогут прослушать содержимое.'
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки TTS',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TTSListTile(
              title: 'Настройки озвучки',
              subtitle: 'Управление TTS и звуками кнопок',
              leading: Icons.volume_up,
              trailing: Icons.arrow_forward_ios,
              onTap: () {
                Navigator.pushNamed(context, '/tts-settings');
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Для полной настройки TTS перейдите в настройки озвучки.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
