import 'package:flutter/material.dart';

class TagSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function() onClear;
  final List<String> popularTags;
  final String? currentSearch;

  const TagSearchWidget({
    super.key,
    required this.onSearch,
    required this.onClear,
    this.popularTags = const [],
    this.currentSearch,
  });

  @override
  State<TagSearchWidget> createState() => _TagSearchWidgetState();
}

class _TagSearchWidgetState extends State<TagSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentSearch != null) {
      _searchController.text = widget.currentSearch!;
      _isSearching = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      widget.onSearch(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Поиск по тегам...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_isSearching)
                IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear, color: Colors.white),
                ),
              IconButton(
                onPressed: _performSearch,
                icon: const Icon(Icons.search, color: Colors.blue),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Popular tags
          if (widget.popularTags.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Популярные теги:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.popularTags.take(10).map((tag) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = tag;
                    _performSearch();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Search suggestions
          if (_isSearching && _searchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Попробуйте:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _getSearchSuggestions(_searchController.text).map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = suggestion;
                    _performSearch();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getSearchSuggestions(String query) {
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();
    
    // Образовательные теги
    final educationalTags = [
      'programming', 'coding', 'tutorial', 'learn', 'study',
      'math', 'science', 'physics', 'chemistry', 'biology',
      'language', 'english', 'spanish', 'french', 'german',
      'history', 'geography', 'art', 'music', 'design',
      'business', 'finance', 'economics', 'psychology',
      'cooking', 'diy', 'crafts', 'fitness', 'health'
    ];
    
    // Развлекательные теги
    final entertainmentTags = [
      'funny', 'meme', 'comedy', 'joke', 'humor',
      'gaming', 'game', 'play', 'fun', 'entertainment',
      'music', 'song', 'dance', 'movie', 'film',
      'sport', 'football', 'basketball', 'soccer',
      'travel', 'adventure', 'nature', 'animals',
      'food', 'recipe', 'cooking', 'restaurant'
    ];
    
    // Ищем совпадения
    for (final tag in [...educationalTags, ...entertainmentTags]) {
      if (tag.contains(lowerQuery) && !suggestions.contains(tag)) {
        suggestions.add(tag);
      }
    }
    
    return suggestions.take(6).toList();
  }
}
