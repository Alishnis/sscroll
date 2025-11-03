import 'package:flutter/material.dart';

class CategoryFilterWidget extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends State<CategoryFilterWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCategoryChip('all', 'Все', Icons.grid_view_rounded),
            _buildCategoryChip('educational', 'Образование', Icons.school_rounded),
            _buildCategoryChip('entertainment', 'Развлечения', Icons.celebration_rounded),
            _buildCategoryChip('tech', 'Технологии', Icons.computer_rounded),
            _buildCategoryChip('science', 'Наука', Icons.science_rounded),
            _buildCategoryChip('art', 'Искусство', Icons.palette_rounded),
            _buildCategoryChip('sports', 'Спорт', Icons.sports_rounded),
            _buildCategoryChip('music', 'Музыка', Icons.music_note_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = widget.selectedCategory == value;
    final colors = _getCategoryColors(value);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          widget.onCategoryChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent
                  : colors[0].withOpacity(0.3),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : colors[0],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(String category) {
    switch (category) {
      case 'all':
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case 'educational':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'entertainment':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'tech':
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
      case 'science':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'art':
        return [const Color(0xFFEC4899), const Color(0xFFBE185D)];
      case 'sports':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'music':
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }
}
