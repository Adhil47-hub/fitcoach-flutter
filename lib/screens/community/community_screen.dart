import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/community/create_post_screen.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _neonGreen = const Color(0xFFD0FD3E);
  final Color _purpleAccent = const Color(0xFFBB86FC);

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  // Helper to format timestamps
  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  // Like Toggle Function
  Future<void> _toggleLike(String postId, List currentLikes) async {
    if (_currentUserId.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(postId);

    if (currentLikes.contains(_currentUserId)) {
      // Unlike
      await docRef.update({
        'likes': FieldValue.arrayRemove([_currentUserId]),
      });
    } else {
      // Like
      await docRef.update({
        'likes': FieldValue.arrayUnion([_currentUserId]),
      });
    }
  }

  // Delete Post Function
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(postId)
        .delete();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Post deleted")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        centerTitle: true,
        title: const Text(
          "Community",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: _neonBlue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade800,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "It's quiet here...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Be the first to share an update!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return _buildPostCard(doc);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String postId = doc.id;
    String userId = data['userId'] ?? "";
    List likes = data['likes'] ?? [];
    bool isLiked = likes.contains(_currentUserId);
    int likeCount = likes.length;

    // Fallback UI data
    String avatarUrl = data['userAvatar'] ?? "";
    String username = data['username'] ?? "User";
    String content = data['content'] ?? "";
    String? activityType = data['activityType'];
    String? activityName = data['activityName'];
    String timeString = _timeAgo(data['timestamp'] as Timestamp?);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeString,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (userId ==
                  _currentUserId) // Only show options if it's the current user's post
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  color: _bgBlack,
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

          // 2. Post Content
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),

          // 3. Activity Badge
          if (activityType != null && activityName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _getActivityColor(activityType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getActivityColor(activityType).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getActivityIcon(activityType),
                    color: _getActivityColor(activityType),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityType.toUpperCase(),
                          style: TextStyle(
                            color: _getActivityColor(activityType),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (activityType != null && activityName != null)
            const SizedBox(height: 15),
          const Divider(color: Colors.white10),

          // 4. Interaction Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(postId, likes),
                    child: _buildInteractionBtn(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : Colors.grey,
                      label: "$likeCount",
                    ),
                  ),
                  const SizedBox(width: 25),
                  _buildInteractionBtn(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.grey,
                    label:
                        "${data['commentsCount'] ?? 0}", // Placeholder for comments
                  ),
                ],
              ),
              const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
            ],
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
    switch (type) {
      case "Workout":
        return _neonGreen;
      case "Meal":
        return _purpleAccent;
      case "Achievement":
        return Colors.orangeAccent;
      default:
        return _neonBlue;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case "Workout":
        return Icons.fitness_center;
      case "Meal":
        return Icons.restaurant;
      case "Achievement":
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }
}
