import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  IconData _getIcon(String? type) {
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'workout':
        return Icons.fitness_center;
      case 'challenge':
        return Icons.local_fire_department;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'water':
        return Colors.blueAccent;
      case 'workout':
      case 'challenge':
        return _neonYellow;
      case 'like':
      case 'comment':
        return _purpleAccent;
      default:
        return Colors.white;
    }
  }

  String _getTimeAgo(String? timestampStr) {
    if (timestampStr == null) return 'Just now';
    final timestamp = DateTime.parse(timestampStr);
    final difference = DateTime.now().difference(timestamp);

    if (difference.inDays > 1) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mins ago';
    return 'Just now';
  }

  Future<void> _markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'isUnread': false})
          .eq('user_id', user.id)
          .eq('isUnread', true);
    } catch (e) {
      debugPrint("Error marking read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              "Mark all read",
              style: TextStyle(color: _neonYellow, fontSize: 12),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text(
                "Please log in.",
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _neonYellow),
                  );
                }

                final List<Map<String, dynamic>> notifications =
                    snapshot.data ?? [];

                notifications.sort(
                  (a, b) => b['timestamp'].compareTo(a['timestamp']),
                );

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      "You're all caught up!",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final noteData = notifications[index];

                    final title = noteData['title'] ?? 'Notification';
                    final body = noteData['body'] ?? '';
                    final type = noteData['type'] ?? 'default';
                    final isUnread = noteData['isUnread'] ?? true;
                    final timeAgo = _getTimeAgo(noteData['timestamp']);

                    final icon = _getIcon(type);
                    final color = _getColor(type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isUnread
                              ? _neonYellow.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isUnread)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        height: 8,
                                        width: 8,
                                        decoration: BoxDecoration(
                                          color: _neonYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
