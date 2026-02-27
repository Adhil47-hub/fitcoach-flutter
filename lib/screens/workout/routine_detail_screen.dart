import 'package:fitcoach_/screens/workout/active_workout_screen.dart';
import 'package:flutter/material.dart';

class RoutineDetailScreen extends StatelessWidget {
  final String routineId;
  final String routineTitle;
  final Map<String, dynamic> routineData;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
    required this.routineTitle,
    required this.routineData,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color bgBlack = const Color(0xFF000000);
    final Color cardDark = const Color(0xFF1C1C1E);
    final Color blueAccent = Colors.blueAccent;

    // Extract exercises list safely
    final List<dynamic> exercises = routineData['exercises'] ?? [];

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to Edit Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Edit feature coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show Delete Option
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. HEADER INFO
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 50,
                  color: Colors.white24,
                ),
                const SizedBox(height: 15),
                Text(
                  routineTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  "${exercises.length} Exercises",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),

          // 2. EXERCISE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // Image Placeholder
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex['name'] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${ex['sets']?.length ?? 0} Sets",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. START WORKOUT BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // --- LAUNCH ACTIVE LOGGER ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveWorkoutScreen(
                        routineTitle: routineTitle,
                        exercises: exercises,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Start Workout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
