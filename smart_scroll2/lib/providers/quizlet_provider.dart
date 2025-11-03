// Quizlet Provider
// SmartScroll v1 - Quizlet Integration
// Last modified: 2024-12-19 08:20:00 UTC

import 'package:flutter/material.dart';
import '../models/quizlet_card.dart';
import '../services/quizlet_service.dart';

class QuizletProvider with ChangeNotifier {
  List<QuizletCard> _cards = [];
  String? _currentSetId;
  String? _creatorId;
  int _totalCards = 0;
  bool _isLoading = false;
  String? _error;
  int _currentCardIndex = 0;

  // Getters
  List<QuizletCard> get cards => _cards;
  String? get currentSetId => _currentSetId;
  String? get creatorId => _creatorId;
  int get totalCards => _totalCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentCardIndex => _currentCardIndex;
  QuizletCard? get currentCard => 
      _cards.isNotEmpty && _currentCardIndex < _cards.length 
          ? _cards[_currentCardIndex] 
          : null;

  // Загружает набор Quizlet
  Future<void> loadSet(String setId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Загружаем информацию о наборе
      await QuizletService.loadSet(setId);
      
      // Загружаем карточки
      final cards = await QuizletService.getCards(setId);
      _cards = cards;
      
      // Загружаем метаданные
      _creatorId = await QuizletService.getCreatorId(setId);
      _totalCards = await QuizletService.getTotalCards(setId);
      
      _currentSetId = setId;
      _currentCardIndex = 0;
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки набора: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Переходит к следующей карточке
  void nextCard() {
    if (_cards.isNotEmpty && _currentCardIndex < _cards.length - 1) {
      _currentCardIndex++;
      notifyListeners();
    }
  }

  // Переходит к предыдущей карточке
  void previousCard() {
    if (_currentCardIndex > 0) {
      _currentCardIndex--;
      notifyListeners();
    }
  }

  // Переходит к конкретной карточке
  void goToCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _currentCardIndex = index;
      notifyListeners();
    }
  }

  // Переворачивает карточку (показывает другую сторону)
  void flipCard() {
    notifyListeners();
  }

  // Очищает данные
  void clearData() {
    _cards = [];
    _currentSetId = null;
    _creatorId = null;
    _totalCards = 0;
    _currentCardIndex = 0;
    _clearError();
    notifyListeners();
  }

  // Получает тексты текущей карточки
  Future<List<String>> getCurrentCardTexts() async {
    if (_currentSetId == null || _currentCardIndex >= _cards.length) {
      return [];
    }
    
    try {
      return await QuizletService.getCardTexts(_currentSetId!, _currentCardIndex);
    } catch (e) {
      _setError('Ошибка получения текстов: $e');
      return [];
    }
  }

  // Получает языки текущей карточки
  Future<List<String>> getCurrentCardLanguages() async {
    if (_currentSetId == null || _currentCardIndex >= _cards.length) {
      return [];
    }
    
    try {
      return await QuizletService.getCardLanguages(_currentSetId!, _currentCardIndex);
    } catch (e) {
      _setError('Ошибка получения языков: $e');
      return [];
    }
  }

  // Получает TTS URLs для текущей карточки
  Future<List<String>> getCurrentCardTTS() async {
    if (_currentSetId == null || _currentCardIndex >= _cards.length) {
      return [];
    }
    
    try {
      return await QuizletService.getCardTTS(_currentSetId!, _currentCardIndex);
    } catch (e) {
      _setError('Ошибка получения TTS: $e');
      return [];
    }
  }

  // Проверяет, есть ли следующая карточка
  bool get hasNextCard => _currentCardIndex < _cards.length - 1;

  // Проверяет, есть ли предыдущая карточка
  bool get hasPreviousCard => _currentCardIndex > 0;

  // Получает прогресс изучения
  double get progress => _cards.isNotEmpty ? (_currentCardIndex + 1) / _cards.length : 0.0;

  // Приватные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
