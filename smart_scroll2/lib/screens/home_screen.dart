import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/video_feed_item.dart';
import '../widgets/recommendation_controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVideos();
    });
  }

  Future<void> _loadInitialVideos() async {
    final userProvider = context.read<UserProvider>();
    final videoProvider = context.read<VideoProvider>();
    
    if (userProvider.currentUser != null) {
      await videoProvider.loadRecommendations(
        userProvider.currentUser!.interests,
        userId: userProvider.currentUser!.id,
      );
    } else {
      await videoProvider.loadVideos();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SmartScroll',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              _showRecommendationSettings(context);
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (videoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    videoProvider.error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userProvider = context.read<UserProvider>();
                      if (userProvider.currentUser != null) {
                        videoProvider.loadRecommendations(
                          userProvider.currentUser!.interests,
                        );
                      } else {
                        videoProvider.loadVideos();
                      }
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (videoProvider.videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, 
                    color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет доступных видео',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Попробуйте обновить рекомендации',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _loadInitialVideos(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videoProvider.videos.length + (videoProvider.hasMoreVideos ? 1 : 0),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              videoProvider.setCurrentVideoIndex(index);
              
              // Проверяем, нужно ли загрузить больше видео
              if (index >= videoProvider.videos.length - 3 && 
                  videoProvider.hasMoreVideos && 
                  !videoProvider.isLoadingMore &&
                  videoProvider.videos.isNotEmpty) {
                _loadMoreVideos();
              }
            },
            itemBuilder: (context, index) {
              // Показываем индикатор загрузки в конце списка
              if (index >= videoProvider.videos.length) {
                return _buildLoadingIndicator();
              }
              
              return VideoFeedItem(
                video: videoProvider.videos[index],
                isVisible: index == _currentPage,
              );
            },
          );
        },
      ),
    );
  }

  void _showRecommendationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Настройки рекомендаций',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Элементы управления
            const RecommendationControls(),
            const SizedBox(height: 20),
            
            // Трендовые темы
            const TrendingTopicsWidget(),
            const SizedBox(height: 20),
            
            // Статистика кэша (только в debug режиме)
            if (const bool.fromEnvironment('dart.vm.product') == false)
              const CacheStatsWidget(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMoreVideos() async {
    final videoProvider = context.read<VideoProvider>();
    
    // Проверяем, что есть видео и можно загружать больше
    if (videoProvider.videos.isNotEmpty && 
        videoProvider.hasMoreVideos && 
        !videoProvider.isLoadingMore) {
      await videoProvider.loadMoreVideos();
    }
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Загружаем больше видео...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

