// Quizlet Screen
// SmartScroll v1 - Quizlet Integration
// Last modified: 2024-12-19 08:20:00 UTC

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quizlet_provider.dart';
import '../models/quizlet_card.dart';

class QuizletScreen extends StatefulWidget {
  const QuizletScreen({super.key});

  @override
  State<QuizletScreen> createState() => _QuizletScreenState();
}

class _QuizletScreenState extends State<QuizletScreen>
    with TickerProviderStateMixin {
  final TextEditingController _setIdController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    
    // Загружаем демо набор по умолчанию
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemoSet();
    });
  }

  @override
  void dispose() {
    _setIdController.dispose();
    _answerController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _loadDemoSet() {
    // Не загружаем автоматически, показываем выбор темы
    // final provider = context.read<QuizletProvider>();
    // provider.loadSet('81926384'); // Демо набор из mobapp
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Consumer<QuizletProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Поиск набора
              _buildSearchSection(provider),
              
              // Основной контент
              Expanded(
                child: _buildMainContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Colors.transparent,
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Quizlet Study v1.0',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(
          icon: Icons.refresh_rounded,
          onPressed: () => _loadDemoSet(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(QuizletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Theme Selection
          if (provider.cards.isEmpty) _buildThemeSelection(provider),
          
          // Set ID Input (for manual loading)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _setIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Или введите ID набора Quizlet',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _loadSet(provider),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Загрузить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (provider.currentSetId != null) ...[
            const SizedBox(height: 16),
            _buildSetInfo(provider),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSelection(QuizletProvider provider) {
    final themes = [
      {'name': 'Spanish', 'icon': Icons.language, 'color': Colors.green},
      {'name': 'French', 'icon': Icons.language, 'color': Colors.blue},
      {'name': 'Math', 'icon': Icons.calculate, 'color': Colors.orange},
      {'name': 'Science', 'icon': Icons.science, 'color': Colors.purple},
      {'name': 'History', 'icon': Icons.history_edu, 'color': Colors.brown},
      {'name': 'Biology', 'icon': Icons.biotech, 'color': Colors.teal},
      {'name': 'Chemistry', 'icon': Icons.local_fire_department, 'color': Colors.red},
      {'name': 'Geography', 'icon': Icons.public, 'color': Colors.indigo},
      {'name': 'Literature', 'icon': Icons.menu_book, 'color': Colors.pink},
      {'name': 'Art', 'icon': Icons.palette, 'color': Colors.amber},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите тему для изучения:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: themes.map((theme) {
              return GestureDetector(
                onTap: () => _selectTheme(theme['name'] as String, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (theme['color'] as Color).withOpacity(0.8),
                        (theme['color'] as Color).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (theme['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        theme['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        theme['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInfo(QuizletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Набор: ${provider.currentSetId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Создатель: ${provider.creatorId ?? "Неизвестно"}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Карточек: ${provider.totalCards}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.currentCardIndex + 1}/${provider.cards.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(QuizletProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.error != null) {
      return _buildErrorState(provider.error!);
    }

    if (provider.cards.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Прогресс бар
        _buildProgressBar(provider),
        
        // Карточка
        Expanded(
          child: _buildCard(provider),
        ),
        
        // Навигация
        _buildNavigation(provider),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Загружаем карточки...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ошибка загрузки',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadDemoSet(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Нет доступных карточек',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Загрузите набор Quizlet для начала изучения',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadDemoSet(),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Загрузить демо'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(QuizletProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогресс',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                '${(provider.progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: provider.progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(QuizletProvider provider) {
    final card = provider.currentCard;
    if (card == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Study Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Question Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card.side1.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Translate to ${card.side2.language}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Answer Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _answerController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type your answer here...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (value) => _checkAnswer(provider, value),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Check Answer Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _checkAnswer(provider, ''),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Check Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Result Section (if answer was checked)
          if (_showResult) _buildResultSection(provider),
        ],
      ),
    );
  }

  Widget _buildResultSection(QuizletProvider provider) {
    final card = provider.currentCard;
    if (card == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCorrect 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? 'Correct! Well done!' : 'Incorrect. Try again!',
                style: TextStyle(
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'Correct answer: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    card.side2.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(QuizletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: provider.hasPreviousCard ? () => _previousCard(provider) : null,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Назад'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.hasPreviousCard 
                  ? const Color(0xFF6B7280) 
                  : Colors.grey.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _flipCard(),
            icon: const Icon(Icons.flip_rounded),
            label: const Text('Перевернуть'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: provider.hasNextCard ? () => _nextCard(provider) : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Далее'),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.hasNextCard 
                  ? const Color(0xFF10B981) 
                  : Colors.grey.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadSet(QuizletProvider provider) {
    final setId = _setIdController.text.trim();
    if (setId.isNotEmpty) {
      provider.loadSet(setId);
    }
  }

  void _selectTheme(String theme, QuizletProvider provider) {
    // Для демонстрации загружаем разные наборы в зависимости от темы
    String setId;
    switch (theme) {
      case 'Spanish':
        setId = '81926384'; // Демо набор
        break;
      case 'French':
        setId = '234567890';
        break;
      case 'Math':
        setId = '456789012';
        break;
      case 'Science':
        setId = '678901234';
        break;
      case 'History':
        setId = '890123456';
        break;
      case 'Biology':
        setId = '123456789';
        break;
      case 'Chemistry':
        setId = '345678901';
        break;
      case 'Geography':
        setId = '567890123';
        break;
      case 'Literature':
        setId = '789012345';
        break;
      case 'Art':
        setId = '901234567';
        break;
      default:
        setId = '81926384';
    }
    
    provider.loadSet(setId);
    
    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Загружаем набор для темы: $theme'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _flipCard() {
    if (_flipController.isCompleted || _flipController.isDismissed) {
      _flipController.reset();
    }
    _flipController.forward();
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _checkAnswer(QuizletProvider provider, String userAnswer) {
    final card = provider.currentCard;
    if (card == null) return;

    final answer = userAnswer.isEmpty ? _answerController.text.trim() : userAnswer;
    final correctAnswer = card.side2.text.toLowerCase();
    final userAnswerLower = answer.toLowerCase();

    // Simple answer checking (can be improved with fuzzy matching)
    final isCorrect = userAnswerLower == correctAnswer || 
                     correctAnswer.contains(userAnswerLower) || 
                     userAnswerLower.contains(correctAnswer);

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
    });

    // Clear the answer field
    _answerController.clear();

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct! Well done!' : 'Incorrect. Try again!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _nextCard(QuizletProvider provider) {
    setState(() {
      _showResult = false;
      _answerController.clear();
    });
    provider.nextCard();
  }

  void _previousCard(QuizletProvider provider) {
    setState(() {
      _showResult = false;
      _answerController.clear();
    });
    provider.previousCard();
  }
}
