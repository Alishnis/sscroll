import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

/// Провайдер для управления настройками TTS
class TTSProvider extends ChangeNotifier {
  bool _isEnabled = false;
  bool _buttonSoundsEnabled = true;
  bool _navigationSoundsEnabled = true;
  bool _contentSoundsEnabled = false;
  double _speechRate = 1.0;
  String _selectedVoice = 'default';
  bool _isServerAvailable = false;
  List<Map<String, String>> _availableVoices = [];

  // Getters
  bool get isEnabled => _isEnabled;
  bool get buttonSoundsEnabled => _buttonSoundsEnabled;
  bool get navigationSoundsEnabled => _navigationSoundsEnabled;
  bool get contentSoundsEnabled => _contentSoundsEnabled;
  double get speechRate => _speechRate;
  String get selectedVoice => _selectedVoice;
  bool get isServerAvailable => _isServerAvailable;
  List<Map<String, String>> get availableVoices => _availableVoices;

  /// Инициализация TTS провайдера
  Future<void> initialize() async {
    await _checkServerAvailability();
    await _loadVoices();
    notifyListeners();
  }

  /// Проверяет доступность TTS сервера
  Future<void> _checkServerAvailability() async {
    _isServerAvailable = await TTSService.isServerAvailable();
  }

  /// Загружает доступные голоса
  Future<void> _loadVoices() async {
    if (_isServerAvailable) {
      _availableVoices = await TTSService.getVoices();
    }
  }

  /// Включает/выключает TTS
  void toggleTTS() {
    _isEnabled = !_isEnabled;
    notifyListeners();
  }

  /// Включает/выключает озвучку кнопок
  void toggleButtonSounds() {
    _buttonSoundsEnabled = !_buttonSoundsEnabled;
    notifyListeners();
  }

  /// Включает/выключает озвучку навигации
  void toggleNavigationSounds() {
    _navigationSoundsEnabled = !_navigationSoundsEnabled;
    notifyListeners();
  }

  /// Включает/выключает озвучку контента
  void toggleContentSounds() {
    _contentSoundsEnabled = !_contentSoundsEnabled;
    notifyListeners();
  }

  /// Устанавливает скорость речи
  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 2.0);
    notifyListeners();
  }

  /// Устанавливает выбранный голос
  void setSelectedVoice(String voiceId) {
    _selectedVoice = voiceId;
    notifyListeners();
  }

  /// Озвучивает текст (если TTS включен)
  Future<void> speak(String text) async {
    if (!_isEnabled) return;

    try {
      if (_isServerAvailable) {
        await TTSService.speak(text);
      } else {
        // Fallback к системному TTS
        await TTSService.speakSystemTTS(text);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка озвучки: $e');
      }
    }
  }

  /// Озвучивает название кнопки (если включены звуки кнопок)
  Future<void> speakButton(String buttonName) async {
    if (!_isEnabled || !_buttonSoundsEnabled) return;
    await speak(buttonName);
  }

  /// Озвучивает навигацию (если включены звуки навигации)
  Future<void> speakNavigation(String navigationText) async {
    if (!_isEnabled || !_navigationSoundsEnabled) return;
    await speak(navigationText);
  }

  /// Озвучивает контент (если включены звуки контента)
  Future<void> speakContent(String content) async {
    if (!_isEnabled || !_contentSoundsEnabled) return;
    await speak(content);
  }

  /// Обновляет статус сервера
  Future<void> refreshServerStatus() async {
    await _checkServerAvailability();
    if (_isServerAvailable) {
      await _loadVoices();
    }
    notifyListeners();
  }

  /// Сбрасывает настройки к значениям по умолчанию
  void resetToDefaults() {
    _isEnabled = false;
    _buttonSoundsEnabled = true;
    _navigationSoundsEnabled = true;
    _contentSoundsEnabled = false;
    _speechRate = 1.0;
    _selectedVoice = 'default';
    notifyListeners();
  }
}
