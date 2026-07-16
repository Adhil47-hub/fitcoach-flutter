import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;
  String? _selectedActivityType;
  String? _selectedActivityName;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  final Color _neonBlue = const Color(0xFF2F80ED);

  final List<String> _activityTypes = [
    "None",
    "Workout",
    "Meal",
    "Achievement",
  ];

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('community_posts').insert({
        'user_id': user.id,
        'username':
            user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            "FitCoach User",
        'user_avatar': user.userMetadata?['avatar_url'] ?? "",
        'content': _contentController.text.trim(),
        'activity_type': _selectedActivityType == "None"
            ? null
            : _selectedActivityType,
        'activity_name': _selectedActivityName,
        'likes': [],
        'comments_count': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post created!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        title: const Text(
          "Create Post",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Post",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _cardDark,

                  backgroundImage: (user?.userMetadata?['avatar_url'] != null)
                      ? NetworkImage(user!.userMetadata!['avatar_url'])
                      : null,
                  child: (user?.userMetadata?['avatar_url'] == null)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: 8,
                    minLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "Share your progress, workout, or meal...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Attach Activity (Optional)",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedActivityType ?? "None",
                  dropdownColor: _cardDark,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _activityTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedActivityType = val;
                      if (val == "None") _selectedActivityName = null;
                    });
                  },
                ),
              ),
            ),
            if (_selectedActivityType != null &&
                _selectedActivityType != "None") ...[
              const SizedBox(height: 10),
              TextField(
                onChanged: (val) => _selectedActivityName = val,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _cardDark,
                  hintText: "e.g. 180kg Deadlift, High Protein Bowl...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
