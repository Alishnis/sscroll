import 'package:flutter/material.dart';
import '../models/feed_item_model.dart';
import '../models/video_model.dart';
import '../models/post_model.dart';

class ModernFeedItem extends StatefulWidget {
  final FeedItemModel feedItem;
  final bool isVisible;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;

  const ModernFeedItem({
    super.key,
    required this.feedItem,
    required this.isVisible,
    this.onLike,
    this.onShare,
    this.onComment,
  });

  @override
  State<ModernFeedItem> createState() => _ModernFeedItemState();
}

class _ModernFeedItemState extends State<ModernFeedItem>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    if (widget.isVisible) {
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _fadeController.forward();
      _scaleController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fadeController.reverse();
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
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
          child: Stack(
            children: [
              // Background content
              _buildBackgroundContent(),
              
              // Main content
              _buildMainContent(),
              
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundContent() {
    if (widget.feedItem.isVideo) {
      return _buildVideoBackground();
    } else {
      return _buildPostBackground();
    }
  }

  Widget _buildVideoBackground() {
    final video = widget.feedItem.video!;
    return Container(
      decoration: BoxDecoration(
        image: video.thumbnailUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(video.thumbnailUrl),
                fit: BoxFit.cover,
              )
            : null,
        gradient: video.thumbnailUrl.isEmpty
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostBackground() {
    final post = widget.feedItem.post!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(post.category).withOpacity(0.8),
            _getCategoryColor(post.category).withOpacity(0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with source info
            _buildHeader(),
            
            const Spacer(),
            
            // Content
            _buildContent(),
            
            const SizedBox(height: 20),
            
            // Stats and metadata
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.feedItem.isVideo ? Icons.play_circle_filled : Icons.article,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.feedItem.isVideo ? 'YouTube' : 'Reddit',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.feedItem.isVideo 
                    ? widget.feedItem.video!.author
                    : widget.feedItem.post!.author,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor(widget.feedItem.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getCategoryColor(widget.feedItem.category),
              width: 1,
            ),
          ),
          child: Text(
            widget.feedItem.category,
            style: TextStyle(
              color: _getCategoryColor(widget.feedItem.category),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.feedItem.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        if (widget.feedItem.description.isNotEmpty)
          Text(
            widget.feedItem.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 16),
        if (widget.feedItem.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.feedItem.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.visibility_rounded,
          value: _formatNumber(widget.feedItem.views),
          label: 'просмотров',
        ),
        const SizedBox(width: 20),
        _buildStatItem(
          icon: Icons.favorite_rounded,
          value: _formatNumber(widget.feedItem.likes),
          label: 'лайков',
        ),
        const SizedBox(width: 20),
        _buildStatItem(
          icon: Icons.schedule_rounded,
          value: widget.feedItem.duration ?? 'N/A',
          label: widget.feedItem.isVideo ? 'длительность' : 'время',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 20,
      bottom: 100,
      child: Column(
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              widget.onLike?.call();
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.comment_rounded,
            color: Colors.white,
            onTap: widget.onComment,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.share_rounded,
            color: Colors.white,
            onTap: widget.onShare,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: _isSaved ? Colors.yellow : Colors.white,
            onTap: () {
              setState(() {
                _isSaved = !_isSaved;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'программирование':
      case 'programming':
        return const Color(0xFF6366F1);
      case 'наука':
      case 'science':
        return const Color(0xFF10B981);
      case 'искусство':
      case 'art':
        return const Color(0xFFEC4899);
      case 'образование':
      case 'educational':
        return const Color(0xFF8B5CF6);
      case 'развлечение':
      case 'entertainment':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'N/A';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
