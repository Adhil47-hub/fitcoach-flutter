import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/recommendation_detail_screen.dart';

// --- CENTRALIZED MASTER LIST & RANDOMIZER LOGIC ---
class RecommendationData {
  static final Color neonYellow = const Color(0xFFD0FD3E);
  static final Color purpleAccent = const Color(0xFFBB86FC);

  static final List<Map<String, dynamic>> all = [
    {
      "title": "Heavy Push Day",
      "tag": "WORKOUT",
      "metric": "45 Min",
      "icon": Icons.fitness_center,
      "color": neonYellow,
      "imageUrl":
          "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
      "description":
          "A high-intensity push routine designed to preserve muscle mass and build strength. Focus on progressive overload on your bench press and overhead strict press.",
      "buttonText": "Start Routine",
    },
    {
      "title": "High-Protein Breakfast Bowl",
      "tag": "NUTRITION",
      "metric": "320 Kcal",
      "icon": Icons.restaurant,
      "color": Colors.redAccent,
      "imageUrl":
          "https://images.unsplash.com/photo-1510693206972-df098062cb71?q=80&w=1598&auto=format&fit=crop",
      "description":
          "A macro-friendly, high-protein start to your day. Packed with eggs, spinach, and avocado, it's perfect for fueling muscle recovery while keeping your energy levels stable.",
      "buttonText": "Generate AI Recipe",
    },
    {
      "title": "Upper Body Stretch",
      "tag": "RECOVERY",
      "metric": "10 Min",
      "icon": Icons.self_improvement,
      "color": Colors.blueAccent,
      "imageUrl":
          "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1520&auto=format&fit=crop",
      "description":
          "Relieve tension and improve shoulder mobility. Active recovery is absolutely crucial to prevent injury when you are pushing through an intense training block.",
      "buttonText": "Start Stretching",
    },
    {
      "title": "Grilled Chicken & Quinoa",
      "tag": "NUTRITION",
      "metric": "450 Kcal",
      "icon": Icons.restaurant,
      "color": Colors.redAccent,
      "imageUrl":
          "https://images.unsplash.com/photo-1512058564366-18510be2db19?q=80&w=1472&auto=format&fit=crop",
      "description":
          "Complex carbs from quinoa paired with lean, spice-rubbed grilled chicken breast. An optimal post-workout meal for hitting your macros and replenishing glycogen.",
      "buttonText": "Generate AI Recipe",
    },
    {
      "title": "Hypertrophy Pull Day",
      "tag": "WORKOUT",
      "metric": "50 Min",
      "icon": Icons.fitness_center,
      "color": neonYellow,
      "imageUrl":
          "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=1470&auto=format&fit=crop",
      "description":
          "Build a wider back and bigger biceps. This high-volume pull session is designed to maximize muscle hypertrophy and grip strength.",
      "buttonText": "Start Routine",
    },
    {
      "title": "Perfecting Barbell Form",
      "tag": "AI TIP",
      "metric": "3 Min Read",
      "icon": Icons.lightbulb,
      "color": purpleAccent,
      "imageUrl":
          "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop",
      "description":
          "Master your barbell mechanics. Proper elbow tracking and lat engagement will prevent shoulder impingements and maximize chest activation during heavy lifts.",
      "buttonText": "Read Article",
    },
  ];

  // Retrieves exactly 3 recommendations based on the current day of the year
  static List<Map<String, dynamic>> getDailyRecommendations() {
    final now = DateTime.now();
    int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    List<Map<String, dynamic>> daily = [];
    for (int i = 0; i < 3; i++) {
      daily.add(all[(dayOfYear + i) % all.length]);
    }
    return daily;
  }
}

// --- THE "SEE ALL" SCREEN UI ---
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get today's active ones so we can highlight them
    final dailyRecs = RecommendationData.getDailyRecommendations();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "All Recommendations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: RecommendationData.all.length,
        itemBuilder: (context, index) {
          final rec = RecommendationData.all[index];
          final isToday = dailyRecs.contains(rec);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecommendationDetailScreen(
                    title: rec["title"],
                    tag: rec["tag"],
                    metric: rec["metric"],
                    icon: rec["icon"],
                    color: rec["color"],
                    imageUrl: rec["imageUrl"],
                    description: rec["description"],
                    buttonText: rec["buttonText"],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Header
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(rec["imageUrl"]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: isToday
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: rec["color"],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "⭐ Today's Pick",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: rec["color"].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                rec["tag"],
                                style: TextStyle(
                                  color: rec["color"],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.grey,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rec["metric"],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
