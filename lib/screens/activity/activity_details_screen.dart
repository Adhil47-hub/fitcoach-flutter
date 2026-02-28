import 'package:flutter/material.dart';

class ActivityDetailsScreen extends StatelessWidget {
  // --- REAL DATA REQUIRED FROM BACKEND ---
  final int steps;
  final int stepGoal;
  final double water;
  final double waterGoal;
  final int calories;
  final int caloriesGoal;
  final bool isWorkoutDone;
  final String workoutName;
  final double sleepHours;
  final double sleepGoal;
  final int streakDays;

  const ActivityDetailsScreen({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.water,
    required this.waterGoal,
    required this.calories,
    required this.caloriesGoal,
    required this.isWorkoutDone,
    required this.workoutName,
    required this.sleepHours,
    required this.sleepGoal,
    required this.streakDays,
  });

  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _neonGreen = const Color(0xFF00E676);
  final Color _orangeAccent = Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    // Calculate accurate progress bars
    double stepProgress = (steps / stepGoal).clamp(0.0, 1.0);
    double waterProgress = (water / waterGoal).clamp(0.0, 1.0);
    double fuelProgress = caloriesGoal > 0 ? (calories / caloriesGoal).clamp(0.0, 1.0) : 0;
    double sleepProgress = (sleepHours / sleepGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Today's Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Row 1: Steps & Water
            Row(
              children: [
                Expanded(child: _buildStatCard("Steps", "$steps", "/ $stepGoal", Icons.directions_walk, _neonYellow, stepProgress)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Water", "${water.toStringAsFixed(1)}L", "/ ${waterGoal.toStringAsFixed(1)}L", Icons.water_drop, _neonBlue, waterProgress)),
              ],
            ),
            const SizedBox(height: 15),
            
            // Row 2: Fuel & Workout
            Row(
              children: [
                Expanded(child: _buildStatCard("Fuel", "$calories", "/ $caloriesGoal Kcal", Icons.local_fire_department, Colors.redAccent, fuelProgress)),
                const SizedBox(width: 15),
                Expanded(child: _buildWorkoutCard("Workout", workoutName, isWorkoutDone ? "Completed" : "Not Started", Icons.fitness_center, _purpleAccent, isWorkoutDone)),
              ],
            ),
            const SizedBox(height: 15),

            // Row 3: Sleep & Streak
            Row(
              children: [
                Expanded(child: _buildStatCard("Sleep", "${sleepHours.toStringAsFixed(1)}h", "/ ${sleepGoal.toStringAsFixed(1)}h", Icons.bedtime, Colors.indigoAccent, sleepProgress)),
                const SizedBox(width: 15),
                Expanded(child: _buildStreakCard("Streak", "$streakDays", "Weekly Target: 6", Icons.local_fire_department, _orangeAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String mainValue, String subValue, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text(mainValue, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subValue, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: color, minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(String title, String mainValue, String subValue, IconData icon, Color color, bool isDone) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDone ? _neonGreen.withOpacity(0.1) : _cardDark, 
        borderRadius: BorderRadius.circular(20),
        border: isDone ? Border.all(color: _neonGreen.withOpacity(0.5)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDone ? _neonGreen : color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text(isDone ? "Crushed It!" : mainValue, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(subValue, style: TextStyle(color: isDone ? _neonGreen : Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(color: isDone ? _neonGreen : Colors.white10, borderRadius: BorderRadius.circular(5)),
            child: Icon(isDone ? Icons.check : Icons.play_arrow, color: isDone ? Colors.black : Colors.white, size: 16),
          )
        ],
      ),
    );
  }

  Widget _buildStreakCard(String title, String days, String subValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(days, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Text("🔥", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          Text(subValue, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}