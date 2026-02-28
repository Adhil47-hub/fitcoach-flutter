import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/workout/stretching_timer_screen.dart'; 
import 'package:fitcoach_/screens/workout/auto_workout_generator.dart'; // ✅ Connects to your ActiveWorkoutScreen
import 'package:fitcoach_/screens/nutrition/ai_chef_screen.dart'; // ✅ Connects to your existing AI Chef

class RecommendationDetailScreen extends StatelessWidget {
  final String title;
  final String tag;
  final String metric;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final String description;
  final String buttonText;

  const RecommendationDetailScreen({
    super.key,
    required this.title,
    required this.tag,
    required this.metric,
    required this.icon,
    required this.color,
    required this.imageUrl,
    required this.description,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // --- EXPANDING IMAGE HEADER ---
          SliverAppBar(
            expandedHeight: 350,
            backgroundColor: Colors.black,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade900,
                      child: Icon(icon, color: Colors.white24, size: 80),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                        stops: const [0.6, 0.9, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // --- CONTENT SECTION ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.grey, size: 18),
                          const SizedBox(width: 5),
                          Text(metric, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Overview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
                  const SizedBox(height: 40),
                  
                  // --- SMART ACTION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        // Dynamic Routing based on the Tag!
                        if (tag == "WORKOUT") {
                          // Bypasses the manual form and auto-generates!
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AutoWorkoutGenerator(routineName: title)));
                        } else if (tag == "RECOVERY") {
                          // Routes to the Stretching Timer
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StretchingTimerScreen(routineName: title)));
                        } else if (tag == "NUTRITION") {
                          // Routes to YOUR existing AI Chef Screen
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChefScreen()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Launching $title..."), backgroundColor: color));
                        }
                      },
                      child: Text(
                        buttonText,
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}