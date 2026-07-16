import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityDetailsScreen extends StatefulWidget {
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

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _neonGreen = const Color(0xFF00E676);
  final Color _orangeAccent = Colors.orangeAccent;

  late double _currentSleepHours;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _currentSleepHours = widget.sleepHours;
  }

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _logSleep(double hours) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _currentSleepHours = hours;
    });

    try {
      // ✅ SAFELY FETCH ROW TO PREVENT DATA LOSS
      final existingLog = await _supabase
          .from('daily_logs')
          .select('id')
          .eq('user_id', user.id)
          .eq('log_date', _todayKey)
          .maybeSingle();

      if (existingLog != null) {
        // Update only sleep
        await _supabase
            .from('daily_logs')
            .update({
              'sleep': _currentSleepHours,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', existingLog['id']);
      } else {
        // Insert a new fresh row for today
        await _supabase.from('daily_logs').insert({
          'user_id': user.id,
          'log_date': _todayKey,
          'sleep': _currentSleepHours,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🌙 Logged ${_currentSleepHours.toStringAsFixed(1)} hours of sleep.",
            ),
            backgroundColor: Colors.indigoAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error logging sleep: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save sleep data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSleepDialog() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController _sleepController = TextEditingController(
      text: _currentSleepHours > 0 ? _currentSleepHours.toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Log Sleep",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "How many hours did you sleep last night?",
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _sleepController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "e.g., 7.5",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.black : Colors.white,
                  suffixText: "hrs",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: isDark
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                double? parsedHours = double.tryParse(_sleepController.text);
                if (parsedHours != null &&
                    parsedHours >= 0 &&
                    parsedHours <= 24) {
                  _logSleep(parsedHours);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid number of hours."),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgBlack = Theme.of(context).scaffoldBackgroundColor;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color neonYellow = isDark
        ? const Color(0xFFD0FD3E)
        : const Color(0xFF00A86B);

    double stepProgress = (widget.steps / widget.stepGoal).clamp(0.0, 1.0);
    double waterProgress = (widget.water / widget.waterGoal).clamp(0.0, 1.0);
    double fuelProgress = widget.caloriesGoal > 0
        ? (widget.calories / widget.caloriesGoal).clamp(0.0, 1.0)
        : 0;
    double sleepProgress = (_currentSleepHours / widget.sleepGoal).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Today's Activity",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    "Steps",
                    "${widget.steps}",
                    "/ ${widget.stepGoal}",
                    Icons.directions_walk,
                    neonYellow,
                    stepProgress,
                    null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    context,
                    "Water",
                    "${widget.water.toStringAsFixed(1)}L",
                    "/ ${widget.waterGoal.toStringAsFixed(1)}L",
                    Icons.water_drop,
                    _neonBlue,
                    waterProgress,
                    null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    "Fuel",
                    "${widget.calories}",
                    "/ ${widget.caloriesGoal} Kcal",
                    Icons.local_fire_department,
                    Colors.redAccent,
                    fuelProgress,
                    null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildWorkoutCard(
                    context,
                    "Workout",
                    widget.workoutName,
                    widget.isWorkoutDone ? "Completed" : "Not Started",
                    Icons.fitness_center,
                    _purpleAccent,
                    widget.isWorkoutDone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    "Sleep",
                    "${_currentSleepHours.toStringAsFixed(1)}h",
                    "/ ${widget.sleepGoal.toStringAsFixed(1)}h",
                    Icons.bedtime,
                    Colors.indigoAccent,
                    sleepProgress,
                    _showSleepDialog,
                    actionIcon: Icons.add_circle,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStreakCard(
                    context,
                    "Streak",
                    "${widget.streakDays}",
                    "Weekly Target: 6",
                    Icons.local_fire_department,
                    _orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String mainValue,
    String subValue,
    IconData icon,
    Color color,
    double progress,
    VoidCallback? onTap, {
    IconData? actionIcon,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.grey : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (actionIcon != null)
                  Icon(actionIcon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              mainValue,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subValue, style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    String title,
    String mainValue,
    String subValue,
    IconData icon,
    Color color,
    bool isDone,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.grey : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDone ? _neonGreen.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDone ? Border.all(color: _neonGreen.withOpacity(0.5)) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDone ? _neonGreen : color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            isDone ? "Crushed It!" : mainValue,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subValue,
            style: TextStyle(
              color: isDone ? _neonGreen : subTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isDone
                  ? _neonGreen
                  : (isDark ? Colors.white10 : Colors.black12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.play_arrow,
              color: isDone ? Colors.black : textColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    String title,
    String days,
    String subValue,
    IconData icon,
    Color color,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                days,
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Text("🔥", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          Text(
            subValue,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
