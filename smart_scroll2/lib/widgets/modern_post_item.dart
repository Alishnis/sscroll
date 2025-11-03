import 'package:flutter/material.dart';
import '../models/post_model.dart';

class ModernPostItem extends StatefulWidget {
  final PostModel post;
  final bool isVisible;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final VoidCallback? onSave;

  const ModernPostItem({
    super.key,
    required this.post,
    required this.isVisible,
    this.onLike,
    this.onShare,
    this.onComment,
    this.onSave,
  });

  @override
  State<ModernPostItem> createState() => _ModernPostItemState();
}

class _ModernPostItemState extends State<ModernPostItem>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    if (widget.isVisible) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernPostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _fadeController.forward();
      _slideController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fadeController.reverse();
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(widget.post.category).withOpacity(0.1),
                _getCategoryColor(widget.post.category).withOpacity(0.05),
                const Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Content
                  _buildContent(),
                  
                  const SizedBox(height: 20),
                  
                  // Image if available
                  if (widget.post.displayThumbnail != null && widget.post.displayThumbnail!.isNotEmpty) _buildImage(),
                  
                  const SizedBox(height: 20),
                  
                  // Tags
                  if (widget.post.tags.isNotEmpty) _buildTags(),
                  
                  const SizedBox(height: 20),
                  
                  // Stats and actions
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getCategoryColor(widget.post.category),
                _getCategoryColor(widget.post.category).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              widget.post.author.isNotEmpty 
                  ? widget.post.author[0].toUpperCase()
                  : 'R',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Author info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.author,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'r/${widget.post.subreddit}',
                    style: TextStyle(
                      color: _getCategoryColor(widget.post.category),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(widget.post.created),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor(widget.post.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getCategoryColor(widget.post.category),
              width: 1,
            ),
          ),
          child: Text(
            widget.post.category,
            style: TextStyle(
              color: _getCategoryColor(widget.post.category),
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
          widget.post.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.post.content != null && widget.post.content!.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.post.content!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                maxLines: _isExpanded ? null : 4,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
            ),
          ),
        if (widget.post.content != null && widget.post.content!.length > 200)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _isExpanded ? 'Свернуть' : 'Читать далее',
              style: TextStyle(
                color: _getCategoryColor(widget.post.category),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(widget.post.displayThumbnail!),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.post.tags.take(5).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
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
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Like button
        _buildActionButton(
          icon: _isLiked ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_up_outlined,
          color: _isLiked ? Colors.orange : Colors.white70,
          label: _formatNumber(widget.post.upvotes),
          onTap: () {
            setState(() {
              _isLiked = !_isLiked;
            });
            widget.onLike?.call();
          },
        ),
        
        const SizedBox(width: 20),
        
        // Comment button
        _buildActionButton(
          icon: Icons.comment_rounded,
          color: Colors.white70,
          label: _formatNumber(widget.post.comments),
          onTap: widget.onComment,
        ),
        
        const SizedBox(width: 20),
        
        // Share button
        _buildActionButton(
          icon: Icons.share_rounded,
          color: Colors.white70,
          label: 'Поделиться',
          onTap: widget.onShare,
        ),
        
        const Spacer(),
        
        // Save button
        GestureDetector(
          onTap: () {
            setState(() {
              _isSaved = !_isSaved;
            });
            widget.onSave?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSaved 
                  ? Colors.yellow.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? Colors.yellow : Colors.white70,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'программирование':
      case 'programming':
      case 'tech':
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
        return const Color(0xFFEC4899);
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}
