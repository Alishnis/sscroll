import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/modern_feed_item.dart';
import '../widgets/modern_search_bar.dart';
import '../widgets/trending_tags_widget.dart';

class MixedFeedScreen extends StatefulWidget {
  const MixedFeedScreen({super.key});

  @override
  State<MixedFeedScreen> createState() => _MixedFeedScreenState();
}

class _MixedFeedScreenState extends State<MixedFeedScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSearch = false;
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
      _loadInitialFeed();
    });
  }

  Future<void> _loadInitialFeed() async {
    final feedProvider = context.read<FeedProvider>();
    await feedProvider.loadMixedFeed();
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
      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, child) {
          return Column(
            children: [
              // Modern search section
              if (_showSearch) _buildSearchSection(feedProvider),
              
              // Main content
              Expanded(
                child: _buildMainContent(feedProvider),
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
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'SmartFeed',
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
          icon: Icons.trending_up_rounded,
          onPressed: () => _showTrendingDialog(),
        ),
        _buildActionButton(
          icon: Icons.refresh_rounded,
          onPressed: () => _loadInitialFeed(),
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

  Widget _buildSearchSection(FeedProvider feedProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ModernSearchBar(
              onSearch: (query) {
                feedProvider.searchByTags(query);
              },
              onClear: () {
                feedProvider.clearSearch();
                _loadInitialFeed();
              },
              currentSearch: feedProvider.currentSearchQuery,
            ),
            const SizedBox(height: 16),
            TrendingTagsWidget(
              tags: feedProvider.popularTags,
              onTagTap: (tag) {
                feedProvider.searchByTags(tag);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(FeedProvider feedProvider) {
    if (feedProvider.isLoading) {
      return _buildLoadingState();
    }

    if (feedProvider.error != null) {
      return _buildErrorState(feedProvider.error!);
    }

    if (feedProvider.feedItems.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: feedProvider.feedItems.length + (feedProvider.hasMoreItems ? 1 : 0),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        feedProvider.setCurrentItemIndex(index);
        
        // Auto-load more content
        if (index >= feedProvider.feedItems.length - 3 && 
            feedProvider.hasMoreItems && 
            !feedProvider.isLoadingMore &&
            feedProvider.feedItems.isNotEmpty) {
          _loadMoreItems();
        }
      },
      itemBuilder: (context, index) {
        if (index >= feedProvider.feedItems.length) {
          return _buildLoadingIndicator();
        }
        
        return ModernFeedItem(
          feedItem: feedProvider.feedItems[index],
          isVisible: index == _currentPage,
          onLike: () => _handleLike(feedProvider.feedItems[index].id),
          onShare: () => _handleShare(feedProvider.feedItems[index]),
          onComment: () => _handleComment(feedProvider.feedItems[index]),
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
              color: Color(0xFF6366F1),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Загружаем контент...',
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
              Text(
                'Ошибка загрузки',
                style: const TextStyle(
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
                onPressed: () => _loadInitialFeed(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.feed_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Нет доступного контента',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Попробуйте обновить ленту или изменить поисковый запрос',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadInitialFeed(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Обновить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
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
              color: Color(0xFF6366F1),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
          Text(
              'Загружаем больше контента...',
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

  Future<void> _loadMoreItems() async {
    final feedProvider = context.read<FeedProvider>();
    
    if (feedProvider.feedItems.isNotEmpty && 
        feedProvider.hasMoreItems && 
        !feedProvider.isLoadingMore) {
      await feedProvider.loadMoreItems();
    }
  }

  void _handleLike(String itemId) {
    // TODO: Implement like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Лайк добавлен!'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _handleShare(dynamic item) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована!'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _handleComment(dynamic item) {
    // TODO: Implement comment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Комментарии скоро будут доступны!'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showTrendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Трендовые темы',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            children: [
              _TrendingItem(
                title: 'Программирование',
                subtitle: '1.2M просмотров',
                icon: Icons.code_rounded,
                color: Color(0xFF6366F1),
              ),
              _TrendingItem(
                title: 'Искусственный интеллект',
                subtitle: '856K просмотров',
                icon: Icons.psychology_rounded,
                color: Color(0xFF8B5CF6),
              ),
              _TrendingItem(
                title: 'Дизайн',
                subtitle: '643K просмотров',
                icon: Icons.palette_rounded,
                color: Color(0xFFEC4899),
              ),
              _TrendingItem(
                title: 'Наука',
                subtitle: '421K просмотров',
                icon: Icons.science_rounded,
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TrendingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
          children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}