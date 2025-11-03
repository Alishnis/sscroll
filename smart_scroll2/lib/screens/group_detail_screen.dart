import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';
import '../providers/video_provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _isJoined = userProvider.currentUser?.joinedGroups
            .contains(widget.group.id) ??
        false;
    
    context.read<VideoProvider>().loadGroupVideos(widget.group.id);
  }

  Future<void> _toggleJoinGroup() async {
    final userProvider = context.read<UserProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (userProvider.currentUser == null) return;

    if (_isJoined) {
      await groupProvider.leaveGroup(
        widget.group.id,
        userProvider.currentUser!.id,
      );
      userProvider.leaveGroup(widget.group.id);
    } else {
      await groupProvider.joinGroup(
        widget.group.id,
        userProvider.currentUser!.id,
      );
      userProvider.joinGroup(widget.group.id);
    }

    setState(() {
      _isJoined = !_isJoined;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.group.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: widget.group.imageUrl != null
                  ? Image.network(
                      widget.group.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue[300],
                          child: const Icon(Icons.group, size: 64, color: Colors.white),
                        );
                      },
                    )
                  : Container(
                      color: Colors.blue[300],
                      child: const Icon(Icons.group, size: 64, color: Colors.white),
                    ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ментор',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.group.mentorName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.group.category,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Описание',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.group.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.people,
                        label: '${widget.group.memberCount} участников',
                      ),
                      const SizedBox(width: 24),
                      _StatItem(
                        icon: Icons.video_library,
                        label: '${widget.group.videoIds.length} видео',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Join/Leave button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleJoinGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined ? Colors.grey : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isJoined ? 'Покинуть группу' : 'Присоединиться',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Group videos
                  Text(
                    'Видео группы',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Video list
          Consumer<VideoProvider>(
            builder: (context, videoProvider, child) {
              if (videoProvider.groupVideos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('В группе пока нет видео'),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = videoProvider.groupVideos[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          video.thumbnailUrl,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.video_library),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        video.author,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Text(
                        '${(video.duration ~/ 60)}:${(video.duration % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onTap: () {
                        // Play video
                      },
                    );
                  },
                  childCount: videoProvider.groupVideos.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

