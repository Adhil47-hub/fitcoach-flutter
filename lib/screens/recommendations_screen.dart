import 'package:flutter/material.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  // --- COLORS ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  int _selectedIndex = 0;
  final List<String> _categories = ["All", "Workouts", "Nutrition", "Recovery", "AI Tips"];

  // Smart AI Suggestions tailored to the user's current goals
  final List<Map<String, dynamic>> _recommendations = [
    {
      "title": "Cardio: The 60kg Cut Protocol",
      "category": "Workouts",
      "tag": "WORKOUT",
      "metric": "30 Min",
      "icon": Icons.fitness_center,
      "color": const Color(0xFFD0FD3E), // _neonYellow
    },
    {
      "title": "High-Protein Meen Curry",
      "category": "Nutrition",
      "tag": "NUTRITION",
      "metric": "320 Kcal",
      "icon": Icons.restaurant,
      "color": Colors.redAccent,
    },
    {
      "title": "Optimizing Pre-Workout Timing",
      "category": "AI Tips",
      "tag": "AI TIP",
      "metric": "3 Min Read",
      "icon": Icons.bolt,
      "color": const Color(0xFFBB86FC), // _purpleAccent
    },
    {
      "title": "Deep Tissue Shoulder Release",
      "category": "Recovery",
      "tag": "RECOVERY",
      "metric": "15 Min",
      "icon": Icons.self_improvement,
      "color": Colors.blueAccent,
    },
    {
      "title": "Heavy Leg Day Prep",
      "category": "Workouts",
      "tag": "WORKOUT",
      "metric": "45 Min",
      "icon": Icons.fitness_center,
      "color": const Color(0xFFD0FD3E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the selected category chip
    List<Map<String, dynamic>> filteredList = _selectedIndex == 0 
        ? _recommendations 
        : _recommendations.where((item) => item["category"] == _categories[_selectedIndex]).toList();

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        elevation: 0,
        title: Text("For You", style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // --- CATEGORY FILTER CHIPS ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _neonYellow : _cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : _textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // --- RECOMMENDATIONS LIST ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _buildFullWidthCard(
                  item["title"],
                  item["tag"],
                  item["metric"],
                  item["icon"],
                  item["color"],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(String title, String tag, String metric, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color.withOpacity(0.8), size: 30),
          ),
          const SizedBox(width: 15),
          
          // Text & Tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(color: _textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: _textGrey, size: 14),
                    const SizedBox(width: 4),
                    Text(metric, style: TextStyle(color: _textGrey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Play/Go Button
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}