import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../widgets/modern_post_item.dart';
import '../widgets/modern_search_bar.dart';
import '../widgets/category_filter_widget.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSearch = false;
  String _selectedCategory = 'all';
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPosts();
    });
  }

  Future<void> _loadInitialPosts() async {
    final postProvider = context.read<PostProvider>();
    await postProvider.loadMixedPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return Column(
            children: [
              // Modern search section
              if (_showSearch) _buildSearchSection(postProvider),
              
              // Category filter
              _buildCategoryFilter(),
              
              // Main content
              Expanded(
                child: _buildMainContent(postProvider),
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
                colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'SmartPosts v1.0',
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
          icon: _showSearch ? Icons.close_rounded : Icons.search_rounded,
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
            });
            if (_showSearch) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }
          },
        ),
        _buildActionButton(
          icon: Icons.filter_list_rounded,
          onPressed: () => _showFilterDialog(),
        ),
        _buildActionButton(
          icon: Icons.refresh_rounded,
          onPressed: () => _loadInitialPosts(),
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

  Widget _buildSearchSection(PostProvider postProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ModernSearchBar(
          onSearch: (query) {
            postProvider.searchPostsByTags(query);
          },
          onClear: () {
            postProvider.clearSearch();
            _loadInitialPosts();
          },
          currentSearch: postProvider.currentSearchQuery,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
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
          ],
        ),
      );
    }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
          _handleCategoryChange(value);
        },
        backgroundColor: Colors.white.withOpacity(0.1),
        selectedColor: const Color(0xFFEC4899),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildMainContent(PostProvider postProvider) {
    if (postProvider.isLoading) {
      return _buildLoadingState();
    }

    if (postProvider.error != null) {
      return _buildErrorState(postProvider.error!);
    }

    if (postProvider.posts.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: postProvider.posts.length + (postProvider.hasMorePosts ? 1 : 0),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        postProvider.setCurrentPostIndex(index);
        
        // Auto-load more content
        if (index >= postProvider.posts.length - 3 && 
            postProvider.hasMorePosts && 
            !postProvider.isLoadingMore &&
            postProvider.posts.isNotEmpty) {
          _loadMorePosts();
        }
      },
      itemBuilder: (context, index) {
        if (index >= postProvider.posts.length) {
          return _buildLoadingIndicator();
        }
        
        return ModernPostItem(
          post: postProvider.posts[index],
          isVisible: index == _currentPage,
          onLike: () => _handleLike(postProvider.posts[index].id),
          onShare: () => _handleShare(postProvider.posts[index]),
          onComment: () => _handleComment(postProvider.posts[index]),
          onSave: () => _handleSave(postProvider.posts[index]),
        );
      },
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
              color: Color(0xFFEC4899),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Загружаем посты...',
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
                onPressed: () => _loadInitialPosts(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
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
                    colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Нет доступных постов',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Попробуйте изменить фильтр или обновить ленту',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadInitialPosts(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Обновить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
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

  Widget _buildLoadingIndicator() {
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
              color: Color(0xFFEC4899),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Загружаем больше постов...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMorePosts() async {
    final postProvider = context.read<PostProvider>();
    
    if (postProvider.posts.isNotEmpty && 
        postProvider.hasMorePosts && 
        !postProvider.isLoadingMore) {
      await postProvider.loadMorePosts();
    }
  }

  void _handleCategoryChange(String category) async {
    final postProvider = context.read<PostProvider>();
    
    switch (category) {
      case 'all':
        await postProvider.loadMixedPosts();
        break;
      case 'educational':
        await postProvider.loadEducationalPosts();
        break;
      case 'entertainment':
        await postProvider.loadEntertainmentPosts();
        break;
      case 'tech':
        await postProvider.searchPostsByTags('technology programming');
        break;
      case 'science':
        await postProvider.searchPostsByTags('science research');
        break;
      case 'art':
        await postProvider.searchPostsByTags('art design creative');
        break;
    }
  }

  void _handleLike(String postId) {
    // TODO: Implement like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Лайк добавлен!'),
        backgroundColor: Color(0xFFEC4899),
      ),
    );
  }

  void _handleShare(dynamic post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована!'),
        backgroundColor: Color(0xFFEC4899),
      ),
    );
  }

  void _handleComment(dynamic post) {
    // TODO: Implement comment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Комментарии скоро будут доступны!'),
        backgroundColor: Color(0xFFEC4899),
      ),
    );
  }

  void _handleSave(dynamic post) {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пост сохранен!'),
        backgroundColor: Color(0xFFEC4899),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Фильтры',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            children: [
              _FilterOption(
                title: 'Сортировка',
                options: ['Популярные', 'Новые', 'Топ'],
                icon: Icons.sort_rounded,
                color: Color(0xFFEC4899),
              ),
              _FilterOption(
                title: 'Источник',
                options: ['Reddit', 'Все'],
                icon: Icons.source_rounded,
                color: Color(0xFF6366F1),
              ),
              _FilterOption(
                title: 'Время',
                options: ['Сегодня', 'Неделя', 'Месяц'],
                icon: Icons.schedule_rounded,
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Применить',
              style: TextStyle(color: Color(0xFFEC4899)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String title;
  final List<String> options;
  final IconData icon;
  final Color color;

  const _FilterOption({
    required this.title,
    required this.options,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
            Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
            ),
          ],
        ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((option) {
              return FilterChip(
                label: Text(
                  option,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                onSelected: (selected) {
                  // TODO: Implement filter selection
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}