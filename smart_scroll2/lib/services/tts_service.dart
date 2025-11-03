import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Сервис для синтеза речи (Text-to-Speech)
class TTSService {
  static const String _baseUrl = 'http://localhost:5001';
  
  /// Проверяет доступность TTS сервера
  static Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['server_running'] == true;
      }
      return false;
    } catch (e) {
      print('TTS Server недоступен: $e');
      return false;
    }
  }
  
  /// Синтезирует речь из текста
  static Future<bool> speak(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/speak'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Ошибка синтеза речи: $e');
      return false;
    }
  }
  
  /// Генерирует аудио файл из текста
  static Future<String?> generateAudio(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-audio'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return '$_baseUrl${data['audio_url']}';
        }
      }
      return null;
    } catch (e) {
      print('Ошибка генерации аудио: $e');
      return null;
    }
  }
  
  /// Получает список доступных голосов
  static Future<List<Map<String, String>>> getVoices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/voices'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, String>>.from(data['voices']);
      }
      return [];
    } catch (e) {
      print('Ошибка получения голосов: $e');
      return [];
    }
  }
  
  /// Альтернативный метод через системный TTS (для мобильных устройств)
  static Future<bool> speakSystemTTS(String text) async {
    try {
      if (Platform.isAndroid) {
        // Для Android можно использовать flutter_tts
        // Пока возвращаем false, так как нужна дополнительная настройка
        return false;
      } else if (Platform.isIOS) {
        // Для iOS можно использовать AVSpeechSynthesizer
        // Пока возвращаем false, так как нужна дополнительная настройка
        return false;
      }
      return false;
    } catch (e) {
      print('Ошибка системного TTS: $e');
      return false;
    }
  }
}
