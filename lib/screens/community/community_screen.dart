import 'package:fitcoach_/screens/community/create_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonGreen = const Color(0xFF00E676);
  final Color _neonBlue = const Color(0xFF2F80ED);

  String get _currentUserId => _supabase.auth.currentUser?.id ?? "";

  String _timeAgo(String? timestampStr) {
    if (timestampStr == null) return "Just now";
    final date = DateTime.parse(timestampStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    if (_currentUserId.isEmpty) return;

    List<String> newLikes = List<String>.from(currentLikes);

    if (newLikes.contains(_currentUserId)) {
      newLikes.remove(_currentUserId);
    } else {
      newLikes.add(_currentUserId);
    }

    try {
      await _supabase
          .from('community_posts')
          .update({'likes': newLikes})
          .eq('id', postId);
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _supabase.from('community_posts').delete().eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Post deleted")));
      }
    } catch (e) {
      debugPrint("Error deleting post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        centerTitle: true,
        title: Text(
          "Community",
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        backgroundColor: _neonBlue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('community_posts')
            .stream(primaryKey: ['id'])
            .order('timestamp', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _neonYellow));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) => _buildPostCard(posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            "It's quiet here...",
            style: TextStyle(
              color: _textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Be the first to share an update!",
            style: TextStyle(color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data) {
    String postId = data['id'].toString();
    String userId = data['user_id'] ?? "";
    List likes = data['likes'] ?? [];
    bool isLiked = likes.contains(_currentUserId);
    int likeCount = likes.length;

    String avatarUrl = data['user_avatar'] ?? "";
    String username = data['username'] ?? "User";
    String content = data['content'] ?? "";
    String? activityType = data['activity_type'];
    String? activityName = data['activity_name'];
    String timeString = _timeAgo(data['timestamp']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: isDark ? Colors.white : Colors.black54,
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        color: _textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeString,
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (userId == _currentUserId)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: _textGrey),
                  color: _cardDark,
                  onSelected: (val) {
                    if (val == 'delete') _deletePost(postId);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        "Delete Post",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: TextStyle(color: _textWhite, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 15),

          if (activityType != null && activityName != null)
            _buildActivityBadge(activityType, activityName),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(postId, likes),
                    child: _buildInteractionBtn(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : _textGrey,
                      label: "$likeCount",
                    ),
                  ),
                  const SizedBox(width: 25),
                  _buildInteractionBtn(
                    icon: Icons.chat_bubble_outline,
                    color: _textGrey,
                    label: "${data['comments_count'] ?? 0}",
                  ),
                ],
              ),
              Icon(Icons.share_outlined, color: _textGrey, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBadge(String type, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getActivityColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getActivityColor(type).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getActivityIcon(type),
            color: _getActivityColor(type),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: _getActivityColor(type),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBtn({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(String type) {
    if (type == "Workout") return _neonGreen;
    if (type == "Meal") return _purpleAccent;
    if (type == "Achievement") return Colors.orangeAccent;
    return _neonBlue;
  }

  IconData _getActivityIcon(String type) {
    if (type == "Workout") return Icons.fitness_center;
    if (type == "Meal") return Icons.restaurant;
    if (type == "Achievement") return Icons.emoji_events;
    return Icons.star;
  }
}
