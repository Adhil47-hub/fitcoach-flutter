import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcoach_/screens/community/community_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';
import 'package:fitcoach_/screens/workout/workout_menu_screen.dart';
import 'package:fitcoach_/screens/workout/progress_screen.dart';
import 'package:fitcoach_/screens/nutrition/nutrition_screen.dart';
import 'package:fitcoach_/screens/activity/activity_details_screen.dart';
import 'package:fitcoach_/screens/recommendations_screen.dart';
import 'package:fitcoach_/screens/recommendation_detail_screen.dart';
import 'package:fitcoach_/screens/workout/auto_workout_generator.dart';
import 'package:fitcoach_/screens/article_screen.dart'; // ✅ Added the Article Screen import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _selectedIndex = 0;
  final Health health = Health();

  // --- REAL-TIME TRACKING STATE ---
  int _stepCount = 0;
  double _waterIntakeLiters = 0.0;
  int _caloriesEaten = 0;
  bool _isWorkoutDone = false;
  String _todaysWorkout = "Rest Day";
  double _sleepHours = 0.0;
  int _streakDays = 0;

  // --- USER CONFIGURABLE GOALS (WITH DEFAULTS) ---
  int _stepGoal = 10000;
  double _waterGoalLiters = 3.0;
  int _caloriesGoal = 2000;
  double _sleepGoal = 8.0;

  // --- COLORS ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _neonGreen = const Color(0xFF00E676);
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _userName => _currentUser?.displayName?.split(' ')[0] ?? "User";

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _fetchStepData();
    _loadUserGoals(); // Fetch custom goals first
    _loadRealTimeData();
  }

  void _setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // --- FETCH USER CUSTOM GOALS ---
  Future<void> _loadUserGoals() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('goals')
          .doc('daily')
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _stepGoal = (data['stepGoal'] ?? 10000).toInt();
          _waterGoalLiters = (data['waterGoal'] ?? 3.0).toDouble();
          _caloriesGoal = (data['caloriesGoal'] ?? 2000).toInt();
          _sleepGoal = (data['sleepGoal'] ?? 8.0).toDouble();
        });
      }
    } catch (e) {
      print("Error loading goals: $e");
    }
  }

  // --- FETCH ALL REAL DATA FROM FIREBASE ---
  Future<void> _loadRealTimeData() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('daily_logs')
          .doc(_todayKey)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _waterIntakeLiters = (data['water'] ?? 0.0).toDouble();
          _caloriesEaten = (data['calories'] ?? 0).toInt();
          _isWorkoutDone = data['workoutDone'] ?? false;
          _todaysWorkout = data['workoutName'] ?? "Rest Day";
          _sleepHours = (data['sleep'] ?? 0.0).toDouble();
          _streakDays = (data['streak'] ?? 0).toInt();
        });
      }
    } catch (e) {
      print("Error loading realtime data: $e");
    }
  }

  // --- WATER LOGGING FUNCTIONALITY ---
  Future<void> _addWater(double amount) async {
    if (_currentUser == null) return;
    setState(() => _waterIntakeLiters += amount);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('daily_logs')
        .doc(_todayKey)
        .set({
          'water': _waterIntakeLiters,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "💧 ${(amount * 1000).toInt()}ml logged! Total: ${_waterIntakeLiters.toStringAsFixed(2)}L",
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  void _showWaterOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Log Water",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildWaterOptionBtn(
                    "Sip",
                    "100ml",
                    Icons.water_drop_outlined,
                    0.10,
                  ),
                  _buildWaterOptionBtn(
                    "Cup",
                    "150ml",
                    Icons.emoji_food_beverage,
                    0.15,
                  ),
                  _buildWaterOptionBtn(
                    "Glass",
                    "250ml",
                    Icons.local_drink,
                    0.25,
                  ),
                  _buildWaterOptionBtn(
                    "Bottle",
                    "500ml",
                    Icons.water_drop,
                    0.50,
                  ),
                  _buildWaterOptionBtn("Jug", "1L", Icons.local_cafe, 1.0),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterOptionBtn(
    String label,
    String sub,
    IconData icon,
    double amount,
  ) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // --- GOAL SETTING EDITOR ---
  void _showEditGoalsDialog() {
    final stepCtrl = TextEditingController(text: _stepGoal.toString());
    final waterCtrl = TextEditingController(text: _waterGoalLiters.toString());
    final calCtrl = TextEditingController(text: _caloriesGoal.toString());
    final sleepCtrl = TextEditingController(text: _sleepGoal.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Set Daily Goals",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildGoalInput(
                "Daily Steps",
                "Suggested: 10,000",
                stepCtrl,
                Icons.directions_walk,
                _neonYellow,
              ),
              _buildGoalInput(
                "Water (Liters)",
                "Suggested: 3.0",
                waterCtrl,
                Icons.water_drop,
                Colors.blueAccent,
              ),
              _buildGoalInput(
                "Calories (Kcal)",
                "Based on your cut/bulk plan",
                calCtrl,
                Icons.local_fire_department,
                Colors.redAccent,
              ),
              _buildGoalInput(
                "Sleep (Hours)",
                "Suggested: 8.0",
                sleepCtrl,
                Icons.bedtime,
                _purpleAccent,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    if (_currentUser != null) {
                      final newSteps = int.tryParse(stepCtrl.text) ?? 10000;
                      final newWater = double.tryParse(waterCtrl.text) ?? 3.0;
                      final newCals = int.tryParse(calCtrl.text) ?? 2000;
                      final newSleep = double.tryParse(sleepCtrl.text) ?? 8.0;

                      // Save straight to Firebase!
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_currentUser!.uid)
                          .collection('goals')
                          .doc('daily')
                          .set({
                            'stepGoal': newSteps,
                            'waterGoal': newWater,
                            'caloriesGoal': newCals,
                            'sleepGoal': newSleep,
                          }, SetOptions(merge: true));

                      setState(() {
                        _stepGoal = newSteps;
                        _waterGoalLiters = newWater;
                        _caloriesGoal = newCals;
                        _sleepGoal = newSleep;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save Goals",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalInput(
    String label,
    String suggestion,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          helperText: suggestion,
          helperStyle: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
          prefixIcon: Icon(icon, color: color),
          filled: true,
          fillColor: Colors.black,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- HEALTH CONNECT (STEPS) ---
  Future<void> _fetchStepData() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool hasPermissions = await health.hasPermissions(types) ?? false;
    if (!hasPermissions)
      hasPermissions = await health.requestAuthorization(types);
    if (hasPermissions) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      int? steps = await health.getTotalStepsInInterval(midnight, now);
      if (mounted) setState(() => _stepCount = steps ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureBtn(
                    "Workout",
                    Icons.fitness_center,
                    _neonYellow,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutMenuScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureBtn(
                    "Nutrition",
                    Icons.restaurant_menu,
                    Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NutritionScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureBtn(
                    "Progress\nTracking",
                    Icons.bar_chart,
                    _purpleAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureBtn(
                    "Community",
                    Icons.people,
                    Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunityScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- DAILY ACTIVITY ---
              _buildSectionHeader(
                "Today's Activity",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityDetailsScreen(
                        steps: _stepCount,
                        stepGoal: _stepGoal,
                        water: _waterIntakeLiters,
                        waterGoal: _waterGoalLiters,
                        calories: _caloriesEaten,
                        caloriesGoal: _caloriesGoal,
                        isWorkoutDone: _isWorkoutDone,
                        workoutName: _todaysWorkout,
                        sleepHours: _sleepHours,
                        sleepGoal: _sleepGoal,
                        streakDays: _streakDays,
                      ),
                    ),
                  );
                },
                trailingIcon: Icons.edit_outlined,
                onTrailingTap: _showEditGoalsDialog,
              ),
              const SizedBox(height: 15),
              _buildDailyActivityCards(),
              const SizedBox(height: 30),

              // --- RECOMMENDATIONS (DYNAMICALLY PULLED FROM MASTER LIST) ---
              _buildSectionHeader("Recommendations", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecommendationsScreen(),
                  ),
                );
              }),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: RecommendationData.getDailyRecommendations().map((
                    rec,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: _buildRecommendationCard(
                        rec["title"],
                        rec["tag"],
                        rec["metric"],
                        rec["icon"],
                        rec["color"],
                        rec["imageUrl"],
                        () {
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
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),

              _buildWeeklyChallenge(),
              const SizedBox(height: 30),
              _buildSectionHeader("Articles & Tips", () {}),
              const SizedBox(height: 15),
              _buildArticleList(), // ✅ Updated List
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildDailyActivityCards() {
    double stepProgress = (_stepCount / _stepGoal).clamp(0.0, 1.0);
    double waterProgress = (_waterIntakeLiters / _waterGoalLiters).clamp(
      0.0,
      1.0,
    );
    double fuelProgress = _caloriesGoal > 0
        ? (_caloriesEaten / _caloriesGoal).clamp(0.0, 1.0)
        : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTrackingCard(
                "Steps",
                "$_stepCount",
                "/ $_stepGoal",
                Icons.directions_walk,
                _neonYellow,
                stepProgress,
                onTap: _fetchStepData,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTrackingCard(
                "Water",
                "${_waterIntakeLiters.toStringAsFixed(1)} L",
                "/ ${_waterGoalLiters.toStringAsFixed(1)} L",
                Icons.water_drop,
                Colors.blueAccent,
                waterProgress,
                onTap: _showWaterOptionsDialog,
                actionIcon: Icons.add_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTrackingCard(
                "Fuel",
                "$_caloriesEaten",
                "/ $_caloriesGoal Kcal",
                Icons.local_fire_department,
                Colors.redAccent,
                fuelProgress,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NutritionScreen()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutMenuScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _isWorkoutDone
                        ? _neonGreen.withOpacity(0.1)
                        : _cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: _isWorkoutDone
                        ? Border.all(color: _neonGreen.withOpacity(0.5))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: _isWorkoutDone ? _neonGreen : _purpleAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Workout",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _isWorkoutDone ? "Crushed It!" : _todaysWorkout,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isWorkoutDone ? "Great job today." : "Not Started",
                        style: TextStyle(
                          color: _isWorkoutDone ? _neonGreen : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: _isWorkoutDone ? _neonGreen : Colors.white10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          _isWorkoutDone ? Icons.check : Icons.play_arrow,
                          color: _isWorkoutDone ? Colors.black : Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingCard(
    String title,
    String mainVal,
    String subVal,
    IconData icon,
    Color color,
    double progress, {
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
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
                      style: const TextStyle(
                        color: Colors.white,
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
              mainVal,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subVal,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String subtitle,
    String metric,
    IconData fallbackIcon,
    Color color,
    String imageUrl,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(fallbackIcon, color: Colors.white24, size: 50),
                      )
                    : Center(
                        child: Icon(
                          fallbackIcon,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: _textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.timer_outlined, color: _textGrey, size: 14),
                const SizedBox(width: 4),
                Text(metric, style: TextStyle(color: _textGrey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        color: _bgBlack,
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _purpleAccent,
        unselectedItemColor: Colors.white54,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutMenuScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, size: 28),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: 28),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, $_userName",
              style: TextStyle(
                color: _purpleAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "It's Time To Challenge Your Limits.",
              style: TextStyle(color: _textGrey, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.search, color: _textWhite, size: 26),
            const SizedBox(width: 15),
            Icon(Icons.notifications_none, color: _textWhite, size: 26),
            const SizedBox(width: 15),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBtn(
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(color: _cardDark, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    VoidCallback onTap, {
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: _textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onTrailingTap,
                child: Icon(trailingIcon, color: _textGrey, size: 20),
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                "See All",
                style: TextStyle(
                  color: _neonYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.arrow_forward_ios, color: _neonYellow, size: 12),
            ],
          ),
        ),
      ],
    );
  }

  // --- DYNAMIC AI WEEKLY CHALLENGE BANNER ---
  Widget _buildWeeklyChallenge() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final weekOfYear = ((now.difference(startOfYear).inDays) / 7).ceil();

    final List<Map<String, String>> aiChallenges = [
      {
        "title": "100-Rep Leg Crusher",
        "desc": "High volume squats and lunges.",
      },
      {"title": "Spartan Core", "desc": "Intense 10-minute ab circuit."},
      {
        "title": "Upper Body Blast",
        "desc": "Pushups, pullups, and shoulder scorchers.",
      },
      {
        "title": "Plyometric Burn",
        "desc": "Explosive jumps and cardio intensive.",
      },
      {
        "title": "Goliath Back Day",
        "desc": "Heavy rows and deadlift variations.",
      },
    ];

    final currentChallenge = aiChallenges[weekOfYear % aiChallenges.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AutoWorkoutGenerator(routineName: currentChallenge["title"]!),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: const NetworkImage(
              "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=1470&auto=format&fit=crop",
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "🔥 WEEKLY AI CHALLENGE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentChallenge["title"]!,
                    style: TextStyle(
                      color: _neonYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentChallenge["desc"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: _neonYellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _neonYellow.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DYNAMIC ARTICLES & TIPS LIST ---
  Widget _buildArticleList() {
    final List<Map<String, dynamic>> articles = [
      {
        "title": "Supplement Guide 101",
        "image":
            "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?q=80&w=1470&auto=format&fit=crop",
        "color": _purpleAccent,
      },
      {
        "title": "Optimal Recovery Protocols",
        "image":
            "https://images.unsplash.com/photo-1516481157630-05bc0aeb8b19?q=80&w=1470&auto=format&fit=crop",
        "color": Colors.blueAccent,
      },
      {
        "title": "Macro Tracking Basics",
        "image":
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1453&auto=format&fit=crop",
        "color": Colors.redAccent,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: articles
            .map(
              (article) => Padding(
                padding: const EdgeInsets.only(right: 15),
                child: _buildArticleCard(
                  article["title"],
                  article["image"],
                  article["color"],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleScreen(
                          title: article["title"],
                          imageUrl: article["image"],
                          color: article["color"],
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // --- UPGRADED ARTICLE CARD WIDGET ---
  Widget _buildArticleCard(
    String title,
    String imageUrl,
    Color tagColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: _textWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              "Read Now",
              style: TextStyle(
                color: tagColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
