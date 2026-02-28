import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcoach_/screens/community/community_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';
import 'package:fitcoach_/screens/workout/workout_menu_screen.dart';
import 'package:fitcoach_/screens/workout/progress_screen.dart'; 
import 'package:fitcoach_/screens/nutrition/nutrition_screen.dart';  
import 'package:fitcoach_/screens/activity/activity_details_screen.dart'; 
import 'package:fitcoach_/screens/recommendations_screen.dart'; 
import 'package:fitcoach_/screens/recommendation_detail_screen.dart'; // ✅ NEW IMPORT
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
  final int _stepGoal = 10000;
  
  double _waterIntakeLiters = 0.0;
  final double _waterGoalLiters = 3.0;

  int _caloriesEaten = 0;
  int _caloriesGoal = 2000; 

  bool _isWorkoutDone = false;
  String _todaysWorkout = "Rest Day";

  double _sleepHours = 0.0;
  final double _sleepGoal = 8.0; 
  
  int _streakDays = 0;

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
    _loadRealTimeData(); 
  }

  void _setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light, systemNavigationBarColor: Colors.transparent, systemNavigationBarIconBrightness: Brightness.light),
    );
  }

  // --- FETCH ALL REAL DATA FROM FIREBASE ---
  Future<void> _loadRealTimeData() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('daily_logs').doc(_todayKey).get();
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

  Future<void> _addWater(double amount) async {
    if (_currentUser == null) return;
    setState(() => _waterIntakeLiters += amount);
    await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('daily_logs').doc(_todayKey).set({'water': _waterIntakeLiters, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    if (mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("💧 ${(amount * 1000).toInt()}ml logged! Total: ${_waterIntakeLiters.toStringAsFixed(2)}L"), duration: const Duration(seconds: 2), backgroundColor: Colors.blueAccent));
    }
  }

  void _showWaterOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Log Water", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center, spacing: 20, runSpacing: 20,
                children: [
                  _buildWaterOptionBtn("Sip", "100ml", Icons.water_drop_outlined, 0.10),
                  _buildWaterOptionBtn("Cup", "150ml", Icons.emoji_food_beverage, 0.15),
                  _buildWaterOptionBtn("Glass", "250ml", Icons.local_drink, 0.25),
                  _buildWaterOptionBtn("Bottle", "500ml", Icons.water_drop, 0.50),
                  _buildWaterOptionBtn("Jug", "1L", Icons.local_cafe, 1.0),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildWaterOptionBtn(String label, String sub, IconData icon, double amount) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Column(
        children: [
          Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.blueAccent, size: 28)),
          const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _fetchStepData() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    bool hasPermissions = await health.hasPermissions(types) ?? false;
    if (!hasPermissions) hasPermissions = await health.requestAuthorization(types);
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
                  _buildFeatureBtn("Workout", Icons.fitness_center, _neonYellow, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutMenuScreen()))),
                  _buildFeatureBtn("Nutrition", Icons.restaurant_menu, Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionScreen()))),
                  _buildFeatureBtn("Progress\nTracking", Icons.bar_chart, _purpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressScreen()))),
                  _buildFeatureBtn("Community", Icons.people, Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()))),
                ],
              ),
              const SizedBox(height: 30),

              // --- DAILY ACTIVITY (2x2 GRID) ---
              _buildSectionHeader("Today's Activity", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsScreen(
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
                )));
              }),
              const SizedBox(height: 15),
              _buildDailyActivityCards(), 
              const SizedBox(height: 30),

              // --- RECOMMENDATIONS (HORIZONTAL SCROLL) ---
              _buildSectionHeader("Recommendations", () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const RecommendationsScreen())
                );
              }),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRecommendationCard(
                      "Heavy Push Day", "WORKOUT", "45 Min", Icons.fitness_center, _neonYellow, 
                      "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop", 
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationDetailScreen(
                          title: "Heavy Push Day", tag: "WORKOUT", metric: "45 Min", icon: Icons.fitness_center, color: _neonYellow,
                          imageUrl: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
                          description: "A high-intensity push routine designed to preserve muscle mass and build strength while you strictly cut down to 60kg. Focus on progressive overload on your bench press and overhead strict press.",
                          buttonText: "Start Routine",
                        )));
                      }
                    ),
                    const SizedBox(width: 15),
                    _buildRecommendationCard(
                      "Upper Body Stretch", "RECOVERY", "10 Min", Icons.self_improvement, Colors.blueAccent, 
                      "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1520&auto=format&fit=crop", 
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationDetailScreen(
                          title: "Upper Body Stretch", tag: "RECOVERY", metric: "10 Min", icon: Icons.self_improvement, color: Colors.blueAccent,
                          imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1520&auto=format&fit=crop",
                          description: "Relieve tension and improve shoulder mobility. Active recovery is absolutely crucial to prevent injury when you are pushing through an intense 6-day split.",
                          buttonText: "Start Stretching",
                        )));
                      }
                    ),
                    const SizedBox(width: 15),
                    _buildRecommendationCard(
                      "High-Protein Dinner", "NUTRITION", "450 Kcal", Icons.restaurant, Colors.redAccent, 
                      "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1453&auto=format&fit=crop", 
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationDetailScreen(
                          title: "High-Protein Dinner", tag: "NUTRITION", metric: "450 Kcal", icon: Icons.restaurant, color: Colors.redAccent,
                          imageUrl: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1453&auto=format&fit=crop",
                          description: "A macro-friendly, Kerala-style high-protein meal to hit your daily goals without sacrificing flavor. Perfect for fueling muscle retention while keeping calories in check.",
                          buttonText: "View Recipe & Log",
                        )));
                      }
                    ),
                    const SizedBox(width: 15),
                    _buildRecommendationCard(
                      "Perfecting Barbell Form", "AI TIP", "3 Min Read", Icons.lightbulb, _purpleAccent, 
                      "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop", 
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationDetailScreen(
                          title: "Perfecting Barbell Form", tag: "AI TIP", metric: "3 Min Read", icon: Icons.lightbulb, color: _purpleAccent,
                          imageUrl: "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=1470&auto=format&fit=crop",
                          description: "Master your barbell mechanics. Proper elbow tracking and lat engagement will prevent shoulder impingements and maximize chest activation during your heavy lifts.",
                          buttonText: "Read Article",
                        )));
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              _buildWeeklyChallenge(),
              const SizedBox(height: 30),
              _buildSectionHeader("Articles & Tips", () {}),
              const SizedBox(height: 15),
              _buildArticleList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyActivityCards() {
    double stepProgress = (_stepCount / _stepGoal).clamp(0.0, 1.0);
    double waterProgress = (_waterIntakeLiters / _waterGoalLiters).clamp(0.0, 1.0);
    double fuelProgress = _caloriesGoal > 0 ? (_caloriesEaten / _caloriesGoal).clamp(0.0, 1.0) : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTrackingCard("Steps", "$_stepCount", "/ $_stepGoal", Icons.directions_walk, _neonYellow, stepProgress, onTap: _fetchStepData)),
            const SizedBox(width: 15),
            Expanded(child: _buildTrackingCard("Water", "${_waterIntakeLiters.toStringAsFixed(1)} L", "/ ${_waterGoalLiters.toStringAsFixed(1)} L", Icons.water_drop, Colors.blueAccent, waterProgress, onTap: _showWaterOptionsDialog, actionIcon: Icons.add_circle)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildTrackingCard("Fuel", "$_caloriesEaten", "/ $_caloriesGoal Kcal", Icons.local_fire_department, Colors.redAccent, fuelProgress, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen())))),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutMenuScreen())),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: _isWorkoutDone ? _neonGreen.withOpacity(0.1) : _cardDark, borderRadius: BorderRadius.circular(20), border: _isWorkoutDone ? Border.all(color: _neonGreen.withOpacity(0.5)) : null),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: _isWorkoutDone ? _neonGreen : _purpleAccent, size: 20), const SizedBox(width: 8),
                          const Text("Workout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(_isWorkoutDone ? "Crushed It!" : _todaysWorkout, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(_isWorkoutDone ? "Great job today." : "Not Started", style: TextStyle(color: _isWorkoutDone ? _neonGreen : Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: _isWorkoutDone ? _neonGreen : Colors.white10, borderRadius: BorderRadius.circular(5)), child: Icon(_isWorkoutDone ? Icons.check : Icons.play_arrow, color: _isWorkoutDone ? Colors.black : Colors.white, size: 16))
                    ],
                  ),
                ),
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingCard(String title, String mainVal, String subVal, IconData icon, Color color, double progress, {VoidCallback? onTap, IconData? actionIcon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                if (actionIcon != null) Icon(actionIcon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            Text(mainVal, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(subVal, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: color, minHeight: 6)),
          ],
        ),
      ),
    );
  }

  // --- NEW RECOMMENDATION CARD (WITH IMAGES) ---
  Widget _buildRecommendationCard(String title, String subtitle, String metric, IconData fallbackIcon, Color color, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220, 
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE SECTION ---
            Container(
              height: 120, 
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(15)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.white24, size: 50),
                      )
                    : Center(child: Icon(fallbackIcon, color: Colors.white24, size: 50)),
              ),
            ),
            // --- TEXT SECTION ---
            const SizedBox(height: 12), 
            Text(title, style: TextStyle(color: _textWhite, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                  child: Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))), color: _bgBlack),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent, elevation: 0, type: BottomNavigationBarType.fixed, selectedItemColor: _purpleAccent, unselectedItemColor: Colors.white54, showSelectedLabels: false, showUnselectedLabels: false, currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0: break;
            case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutMenuScreen())); break;
            case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())); break;
            case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month, size: 28), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined, size: 28), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), label: 'Profile'),
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
            Text("Hi, $_userName", style: TextStyle(color: _purpleAccent, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), Text("It's Time To Challenge Your Limits.", style: TextStyle(color: _textGrey, fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.search, color: _textWhite, size: 26), const SizedBox(width: 15),
            Icon(Icons.notifications_none, color: _textWhite, size: 26), const SizedBox(width: 15),
            InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), child: const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 20, color: Colors.white))),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(height: 60, width: 60, decoration: BoxDecoration(color: _cardDark, shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 10), Text(label, textAlign: TextAlign.center, style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: _textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [Text("See All", style: TextStyle(color: _neonYellow, fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Icon(Icons.arrow_forward_ios, color: _neonYellow, size: 12)],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChallenge() {
    return Container(
      width: double.infinity, height: 130, decoration: BoxDecoration(color: _purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Weekly", style: TextStyle(color: _textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Challenge", style: TextStyle(color: _neonYellow, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5), Text("Plank With Hip Twist", style: TextStyle(color: _textWhite, fontSize: 12)),
              ],
            ),
          ),
          Positioned(right: 10, top: 10, bottom: 0, child: Container(width: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.fitness_center, color: Colors.white24, size: 50))),
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildArticleCard("Supplement Guide"), const SizedBox(width: 15), _buildArticleCard("Daily Routines")]));
  }

  Widget _buildArticleCard(String title) {
    return Container(
      width: 160, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 100, decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(15))),
          const SizedBox(height: 10), Text(title, style: TextStyle(color: _textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}