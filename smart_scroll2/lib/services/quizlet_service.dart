// Quizlet Service
// SmartScroll v1 - Quizlet Integration
// Last modified: 2024-12-19 08:20:00 UTC

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quizlet_card.dart';

class QuizletService {
  static const String _baseUrl = 'http://localhost:1712';
  
  // Загружает набор Quizlet по ID
  static Future<Map<String, dynamic>> loadSet(String setId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load set: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet set: $e');
    }
  }
  
  // Получает все карточки набора
  static Future<List<QuizletCard>> getCards(String setId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/cards'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cards = (data['cards'] as List<dynamic>)
            .map((card) => QuizletCard.fromJson(card))
            .toList();
        return cards;
      } else {
        throw Exception('Failed to load cards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet cards: $e');
    }
  }
  
  // Получает конкретную карточку
  static Future<QuizletCard> getCard(String setId, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/card/$index'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuizletCard.fromJson(data['card']);
      } else {
        throw Exception('Failed to load card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet card: $e');
    }
  }
  
  // Получает тексты карточки
  static Future<List<String>> getCardTexts(String setId, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/card/$index/texts'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['texts']);
      } else {
        throw Exception('Failed to load card texts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet card texts: $e');
    }
  }
  
  // Получает языки карточки
  static Future<List<String>> getCardLanguages(String setId, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/card/$index/languages'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['languages']);
      } else {
        throw Exception('Failed to load card languages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet card languages: $e');
    }
  }
  
  // Получает TTS URLs для карточки
  static Future<List<String>> getCardTTS(String setId, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/card/$index/tts'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['tts']);
      } else {
        throw Exception('Failed to load card TTS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet card TTS: $e');
    }
  }
  
  // Получает ID создателя
  static Future<String> getCreatorId(String setId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/creatorid'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['creatorid'];
      } else {
        throw Exception('Failed to load creator ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet creator ID: $e');
    }
  }
  
  // Получает общее количество карточек
  static Future<int> getTotalCards(String setId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$setId/totalcards'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalcards'];
      } else {
        throw Exception('Failed to load total cards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet total cards: $e');
    }
  }
  
  // Получает информацию об API
  static Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load API info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Quizlet API info: $e');
    }
  }
}
