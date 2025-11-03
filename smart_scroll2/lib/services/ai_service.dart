import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

/// AI Service для суммаризации видео
/// Поддерживает OpenAI, Claude, Gemini
class AiService {
  final String _provider;
  final String _apiKey;

  AiService({String? provider, String? apiKey})
      : _provider = provider ?? Secrets.aiProvider,
        _apiKey = apiKey ?? Secrets.activeAiApiKey;

  /// Генерация краткого содержания видео
  Future<String> generateSummary({
    required String title,
    required String description,
    String? transcript,
  }) async {
    // Если нет реального API ключа, используем mock
    if (_apiKey.isEmpty || _provider == 'mock') {
      return _generateMockSummary(title, description);
    }

    switch (_provider) {
      case 'openai':
        return await _generateWithOpenAI(title, description, transcript);
      case 'claude':
        return await _generateWithClaude(title, description, transcript);
      case 'gemini':
        return await _generateWithGemini(title, description, transcript);
      default:
        return _generateMockSummary(title, description);
    }
  }

  /// OpenAI GPT суммаризация
  Future<String> _generateWithOpenAI(
    String title,
    String description,
    String? transcript,
  ) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final prompt = _buildPrompt(title, description, transcript);

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Ты помощник, который создает краткие и понятные саммари образовательных видео на русском языке.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling OpenAI: $e');
      return _generateMockSummary(title, description);
    }
  }

  /// Claude (Anthropic) суммаризация
  Future<String> _generateWithClaude(
    String title,
    String description,
    String? transcript,
  ) async {
    const endpoint = 'https://api.anthropic.com/v1/messages';

    final prompt = _buildPrompt(title, description, transcript);

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 200,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'].toString().trim();
      } else {
        throw Exception('Claude API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling Claude: $e');
      return _generateMockSummary(title, description);
    }
  }

  /// Google Gemini суммаризация
  Future<String> _generateWithGemini(
    String title,
    String description,
    String? transcript,
  ) async {
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey';

    final prompt = _buildPrompt(title, description, transcript);

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text']
            .toString()
            .trim();
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling Gemini: $e');
      return _generateMockSummary(title, description);
    }
  }

  /// Построение промпта для AI
  String _buildPrompt(String title, String description, String? transcript) {
    final buffer = StringBuffer();
    buffer.writeln('Создай краткое содержание образовательного видео:');
    buffer.writeln();
    buffer.writeln('Название: $title');
    buffer.writeln('Описание: $description');

    if (transcript != null && transcript.isNotEmpty) {
      buffer.writeln('Транскрипт: $transcript');
    }

    buffer.writeln();
    buffer.writeln(
        'Требования: Краткое содержание на русском языке, не более 3-4 предложений, '
        'выделяющее ключевые образовательные моменты.');

    return buffer.toString();
  }

  /// Mock суммаризация (fallback)
  String _generateMockSummary(String title, String description) {
    return 'Краткое содержание: $title. '
        '${description.length > 100 ? description.substring(0, 100) : description}... '
        'Это образовательное видео охватывает ключевые концепции темы. '
        'Основные моменты включают теоретические основы, практические примеры '
        'и рекомендации для дальнейшего изучения.';
  }

  /// Проверка доступности AI сервиса
  Future<bool> isAvailable() async {
    if (_provider == 'mock' || _apiKey.isEmpty) {
      return false;
    }

    try {
      // Простой health check
      switch (_provider) {
        case 'openai':
          final response = await http.get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $_apiKey'},
          );
          return response.statusCode == 200;

        case 'claude':
          // Claude не имеет simple health check endpoint
          return true;

        case 'gemini':
          return true;

        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Получить информацию о текущем провайдере
  Map<String, dynamic> getProviderInfo() {
    return {
      'provider': _provider,
      'hasApiKey': _apiKey.isNotEmpty,
      'isConfigured': Secrets.isConfigured,
    };
  }
}

