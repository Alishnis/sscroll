import 'package:flutter/material.dart';

class TrendingTagsWidget extends StatefulWidget {
  final List<String> tags;
  final Function(String) onTagTap;

  const TrendingTagsWidget({
    super.key,
    required this.tags,
    required this.onTagTap,
  });

  @override
  State<TrendingTagsWidget> createState() => _TrendingTagsWidgetState();
}

class _TrendingTagsWidgetState extends State<TrendingTagsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;
  int _selectedTagIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animations = widget.tags.asMap().entries.map((entry) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            entry.key * 0.1,
            (entry.key * 0.1) + 0.8,
            curve: Curves.easeOut,
          ),
        ),
      );
    }).toList();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Трендовые теги',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.tags.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animations[index].value,
                    child: Opacity(
                      opacity: _animations[index].value,
                      child: _buildTagChip(widget.tags[index], index),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag, int index) {
    final isSelected = _selectedTagIndex == index;
    final colors = _getTagColors(tag);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTagIndex = index;
          });
          widget.onTagTap(tag);
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
            borderRadius: BorderRadius.circular(20),
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
              if (isSelected) ...[
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '#$tag',
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

  List<Color> _getTagColors(String tag) {
    switch (tag.toLowerCase()) {
      case 'programming':
      case 'coding':
      case 'tech':
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case 'science':
      case 'research':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'art':
      case 'design':
        return [const Color(0xFFEC4899), const Color(0xFFBE185D)];
      case 'education':
      case 'learning':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'funny':
      case 'meme':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'gaming':
      case 'games':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'music':
      case 'songs':
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      case 'cooking':
      case 'food':
        return [const Color(0xFF84CC16), const Color(0xFF65A30D)];
      case 'fitness':
      case 'sports':
        return [const Color(0xFFF97316), const Color(0xFFEA580C)];
      case 'travel':
      case 'adventure':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }
}
