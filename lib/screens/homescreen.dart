import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/community_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';
import 'package:fitcoach_/screens/workout/workout_menu_screen.dart';
import 'package:fitcoach_/screens/workout/progress_screen.dart'; 
import 'package:fitcoach_/screens/nutrition/nutrition_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _selectedIndex = 0;

  // --- COLORS ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _userName => _currentUser?.displayName?.split(' ')[0] ?? "User";

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
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

              // --- FEATURE ROW ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Aligns all buttons to the top
                children: [
                  // 1. WORKOUT
                  _buildFeatureBtn(
                    "Workout",
                    Icons.fitness_center,
                    _neonYellow,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutMenuScreen(),
                        ),
                      );
                    },
                  ),
                  // 2. NUTRITION 
                  _buildFeatureBtn(
                    "Nutrition",
                    Icons.restaurant_menu, 
                    Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NutritionScreen(),
                        ),
                      );
                    },
                  ),
                  // 3. PROGRESS TRACKING 
                  _buildFeatureBtn(
                    "Progress\nTracking",
                    Icons.bar_chart,
                    _purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressScreen(),
                        ),
                      );
                    },
                  ),
                  // 4. COMMUNITY 
                  _buildFeatureBtn(
                    "Community",
                    Icons.people,
                    Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- DAILY ACTIVITY (STEPS & WATER) ---
              _buildSectionHeader("Today's Activity", () {}),
              const SizedBox(height: 15),
              _buildDailyActivityCards(),
              const SizedBox(height: 30),

              // --- REST OF THE SCREEN ---
              _buildSectionHeader("Recommendations", () {}),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildWorkoutCard(
                      "Squat Exercise",
                      "12 Minutes",
                      "120 Kcal",
                    ),
                    const SizedBox(width: 15),
                    _buildWorkoutCard(
                      "Full Body Stretch",
                      "15 Minutes",
                      "90 Kcal",
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

  // --- WIDGET HELPERS ---

  Widget _buildDailyActivityCards() {
    return Row(
      children: [
        // --- STEPS CARD ---
        Expanded(
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
                  children: [
                    Icon(Icons.directions_walk, color: _neonYellow, size: 20),
                    const SizedBox(width: 8),
                    const Text("Steps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("4,520", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("/ 10,000", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: 0.45, // 45% complete
                    backgroundColor: Colors.white10,
                    color: _neonYellow,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        
        // --- WATER CARD ---
        Expanded(
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
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text("Water", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("1.5 L", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("/ 3.0 L", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: 0.50, // 50% complete
                    backgroundColor: Colors.white10,
                    color: Colors.blueAccent,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          // Handle Navigation
          switch (index) {
            case 0:
              // Already on Home
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

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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

  Widget _buildWorkoutCard(String title, String time, String cals) {
    return Container(
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
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
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
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_filled, color: _purpleAccent, size: 14),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(color: _textGrey, fontSize: 12)),
              const SizedBox(width: 10),
              Icon(Icons.local_fire_department, color: _purpleAccent, size: 14),
              const SizedBox(width: 4),
              Text(cals, style: TextStyle(color: _textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChallenge() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: _purpleAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Weekly",
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Challenge",
                  style: TextStyle(
                    color: _neonYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Plank With Hip Twist",
                  style: TextStyle(color: _textWhite, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            bottom: 0,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white24,
                size: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildArticleCard("Supplement Guide"),
          const SizedBox(width: 15),
          _buildArticleCard("Daily Routines"),
        ],
      ),
    );
  }

  Widget _buildArticleCard(String title) {
    return Container(
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
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: _textWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}