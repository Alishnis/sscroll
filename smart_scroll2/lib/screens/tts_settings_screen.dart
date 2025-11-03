import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tts_provider.dart';
import '../widgets/tts_button.dart';

class TTSSettingsScreen extends StatefulWidget {
  const TTSSettingsScreen({super.key});

  @override
  State<TTSSettingsScreen> createState() => _TTSSettingsScreenState();
}

class _TTSSettingsScreenState extends State<TTSSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализируем TTS провайдер при загрузке экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TTSProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Настройки озвучки',
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
              // Статус сервера
              _buildServerStatusCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Основные настройки
              _buildMainSettingsCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Настройки озвучки
              _buildSoundSettingsCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Настройки голоса
              _buildVoiceSettingsCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Тестирование
              _buildTestCard(ttsProvider),
              const SizedBox(height: 20),
              
              // Сброс настроек
              _buildResetCard(ttsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServerStatusCard(TTSProvider ttsProvider) {
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
                  ttsProvider.isServerAvailable ? Icons.check_circle : Icons.error,
                  color: ttsProvider.isServerAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Статус TTS сервера',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ttsProvider.isServerAvailable
                  ? '✅ TTS сервер доступен'
                  : '❌ TTS сервер недоступен',
              style: TextStyle(
                color: ttsProvider.isServerAvailable ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
            if (!ttsProvider.isServerAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Убедитесь, что Festival сервер запущен на порту 5001',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TTSButton(
                  text: 'Обновить',
                  icon: Icons.refresh,
                  onPressed: () => ttsProvider.refreshServerStatus(),
                ),
                const SizedBox(width: 8),
                if (!ttsProvider.isServerAvailable)
                  TTSButton(
                    text: 'Помощь',
                    icon: Icons.help,
                    backgroundColor: Colors.grey[200],
                    textColor: Colors.black87,
                    onPressed: () => _showServerHelp(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSettingsCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Основные настройки',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TTSSwitch(
              title: 'Включить озвучку',
              subtitle: 'Общий переключатель для всех звуков',
              value: ttsProvider.isEnabled,
              onChanged: (value) => ttsProvider.toggleTTS(),
              secondary: Icons.volume_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSettingsCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки озвучки',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TTSSwitch(
              title: 'Озвучка кнопок',
              subtitle: 'Озвучивать названия кнопок при нажатии',
              value: ttsProvider.buttonSoundsEnabled,
              onChanged: ttsProvider.isEnabled ? (value) => ttsProvider.toggleButtonSounds() : null,
              secondary: Icons.touch_app,
            ),
            TTSSwitch(
              title: 'Озвучка навигации',
              subtitle: 'Озвучивать переходы между экранами',
              value: ttsProvider.navigationSoundsEnabled,
              onChanged: ttsProvider.isEnabled ? (value) => ttsProvider.toggleNavigationSounds() : null,
              secondary: Icons.navigation,
            ),
            TTSSwitch(
              title: 'Озвучка контента',
              subtitle: 'Озвучивать текст постов и статей',
              value: ttsProvider.contentSoundsEnabled,
              onChanged: ttsProvider.isEnabled ? (value) => ttsProvider.toggleContentSounds() : null,
              secondary: Icons.article,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSettingsCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки голоса',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Скорость речи
            Text(
              'Скорость речи: ${ttsProvider.speechRate.toStringAsFixed(1)}x',
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              value: ttsProvider.speechRate,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: ttsProvider.isEnabled ? (value) => ttsProvider.setSpeechRate(value) : null,
            ),
            
            const SizedBox(height: 16),
            
            // Выбор голоса
            if (ttsProvider.availableVoices.isNotEmpty) ...[
              Text(
                'Выбор голоса:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: ttsProvider.selectedVoice,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ttsProvider.availableVoices.map((voice) {
                  return DropdownMenuItem<String>(
                    value: voice['id'],
                    child: Text('${voice['name']} (${voice['language']})'),
                  );
                }).toList(),
                onChanged: ttsProvider.isEnabled ? (value) {
                  if (value != null) ttsProvider.setSelectedVoice(value);
                } : null,
              ),
            ] else ...[
              Text(
                'Голоса недоступны',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тестирование',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TTSButton(
                  text: 'Тест озвучки',
                  icon: Icons.play_arrow,
                  onPressed: ttsProvider.isEnabled ? () => ttsProvider.speak('Привет! Это тест озвучки.') : null,
                ),
                const SizedBox(width: 8),
                TTSButton(
                  text: 'Тест кнопки',
                  icon: Icons.touch_app,
                  onPressed: ttsProvider.isEnabled ? () => ttsProvider.speakButton('Кнопка нажата') : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetCard(TTSProvider ttsProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сброс настроек',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TTSButton(
              text: 'Сбросить к значениям по умолчанию',
              icon: Icons.restore,
              backgroundColor: Colors.grey[200],
              textColor: Colors.black87,
              onPressed: () => _showResetDialog(ttsProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помощь по настройке TTS сервера'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Для работы озвучки необходимо запустить Festival TTS сервер:'),
              SizedBox(height: 8),
              Text('1. Перейдите в папку #2/festival/'),
              Text('2. Запустите: python3 web_server.py'),
              Text('3. Убедитесь, что сервер работает на порту 5001'),
              SizedBox(height: 8),
              Text('Альтернативно можно использовать системный TTS (ограниченная функциональность).'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(TTSProvider ttsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс настроек'),
        content: const Text('Вы уверены, что хотите сбросить все настройки озвучки к значениям по умолчанию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ttsProvider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки сброшены')),
              );
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
