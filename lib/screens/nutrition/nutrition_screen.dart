import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/nutrition/ai_chef_screen.dart';
import 'package:fitcoach_/screens/nutrition/food_lens_screen.dart';
import 'package:fitcoach_/screens/nutrition/food_search_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // --- CONFIGURATION ---
  final String _apiKey = 'AIzaSyCXF7tJQT9wjqXMhg2o1ZzONDP4ZxhjblA';

  // Navigation State
  int _selectedIndex = 0; // 0 = Dashboard, 1 = Diary

  // Colors
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _calBlue = const Color(0xFF2F80ED);
  final Color _protPurple = const Color(0xFFBB86FC);
  final Color _fatRed = const Color(0xFFFF5252);
  final Color _carbGreen = const Color(0xFFD0FD3E);
  final Color _neonGreen = const Color(0xFFD0FD3E);

  // Data State
  int _targetCalories = 0;
  int _targetProtein = 0;
  int _targetCarbs = 0;
  int _targetFats = 0;
  String _currentMode = "Loading...";
  bool _isLoadingPlan = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Login Required")));

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. DATA FETCHING WRAPPER
    // We fetch data at the root so both tabs share the same state
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) {
          return Scaffold(
            backgroundColor: _bgBlack,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> userData =
            profileSnapshot.data!.data() as Map<String, dynamic>;

        // Generate Plan if needed (Post Frame to avoid build errors)
        if (_targetCalories == 0 && _isLoadingPlan) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndGenerateAiPlan(userData, user.uid);
          });
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('nutrition_logs')
              .doc(today)
              .collection('meals')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, logSnapshot) {
            // -- Calculate Totals --
            int consumedCals = 0;
            int consumedProt = 0;
            int consumedCarbs = 0;
            int consumedFat = 0;

            var meals = logSnapshot.data?.docs ?? [];
            for (var doc in meals) {
              var data = doc.data() as Map<String, dynamic>;
              consumedCals += (data['calories'] as num).toInt();
              consumedProt += (data['protein'] as num).toInt();
              consumedCarbs += (data['carbs'] as num).toInt();
              consumedFat += (data['fats'] as num).toInt();
            }

            // -- UI STRUCTURE --
            return Scaffold(
              backgroundColor: _bgBlack,
              appBar: _buildAppBar(),

              // --- BODY SWITCHER ---
              body: _selectedIndex == 0
                  ? _buildDashboardView(
                      consumedCals,
                      consumedProt,
                      consumedCarbs,
                      consumedFat,
                    )
                  : _buildDiaryView(meals),

              // --- FAB (ADD BUTTON) ---
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddMenu(context),
                backgroundColor: _calBlue,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),

              // --- BOTTOM BAR ---
              bottomNavigationBar: BottomAppBar(
                color: _cardDark,
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Left: Dashboard
                      IconButton(
                        icon: Icon(
                          Icons.grid_view_rounded,
                          color: _selectedIndex == 0 ? _calBlue : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () => setState(() => _selectedIndex = 0),
                      ),

                      const SizedBox(width: 48), // Spacer for FAB
                      // Right: Diary
                      IconButton(
                        icon: Icon(
                          Icons.book_outlined,
                          color: _selectedIndex == 1 ? _calBlue : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () => setState(() => _selectedIndex = 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 1: DASHBOARD VIEW (Stats & AI) ---
  Widget _buildDashboardView(int cals, int prot, int carbs, int fat) {
    int remaining = _targetCalories - cals;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. AI CHEF BANNER (Noticeable Hero Card)
          _buildAiChefBanner(),
          const SizedBox(height: 25),

          // 2. CALORIE WHEEL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Calories",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Remaining = Goal - Food",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: CircularProgressIndicator(
                              value: _targetCalories > 0
                                  ? (remaining / _targetCalories).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0,
                              backgroundColor: Colors.white10,
                              color: remaining < 0 ? _fatRed : _calBlue,
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$remaining",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                "left",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow(
                            Icons.flag,
                            "Base Goal",
                            "$_targetCalories",
                          ),
                          const SizedBox(height: 15),
                          _buildLegendRow(Icons.restaurant, "Food", "- $cals"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. MACROS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Macros",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroCircle("Carbs", carbs, _targetCarbs, _carbGreen),
                    _buildMacroCircle(
                      "Protein",
                      prot,
                      _targetProtein,
                      _protPurple,
                    ),
                    _buildMacroCircle("Fat", fat, _targetFats, _fatRed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: DIARY VIEW (List) ---
  Widget _buildDiaryView(List<QueryDocumentSnapshot> meals) {
    String displayDate = DateFormat('EEEE, d MMM').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chevron_left, color: Colors.grey),
              const SizedBox(width: 15),
              Text(
                displayDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Logs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentMode,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.no_food_outlined,
                    size: 40,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No food logged yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () => _showAddMenu(context),
                    child: Text(
                      "Start Logging",
                      style: TextStyle(color: _calBlue),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: meals.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10), // Spacing
              itemBuilder: (context, index) {
                var data = meals[index].data() as Map<String, dynamic>;
                return _buildDiaryTile(data, meals[index].reference);
              },
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgBlack,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        _selectedIndex == 0 ? "Nutrition Dashboard" : "Food Diary",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildAiChefBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiChefScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _calBlue.withOpacity(0.9),
              const Color(0xFF9C27B0),
            ], // Blue to Purple
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _calBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "AI Kitchen Coach",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Ingredients to Recipe instantly.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Tap to Generate ✨",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENU SHEET ---
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 25),

            // Row 1: Search & Barcode
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    Icons.search,
                    "Log Food",
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FoodSearchScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildMenuCard(
                    Icons.qr_code_scanner,
                    "Barcode",
                    Colors.redAccent,
                    () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Barcode Scanner coming soon!"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Row 2: Scan & AI Chef
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    Icons.camera_alt,
                    "Meal Scan",
                    Colors.tealAccent,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FoodLensScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildMenuCard(
                    Icons.auto_awesome,
                    "AI Chef",
                    _neonGreen,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiChefScreen()),
                      );
                    },
                    isSpecial: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: isSpecial ? Border.all(color: color.withOpacity(0.5)) : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildLegendRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCircle(String label, int current, int target, Color color) {
    double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    int remaining = target - current;
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: color,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$remaining",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          "${current}/${target}g",
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDiaryTile(Map<String, dynamic> data, DocumentReference ref) {
    return Dismissible(
      key: Key(ref.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: _fatRed.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: _fatRed),
      ),
      onDismissed: (_) => ref.delete(),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['foodName'] ?? "Unknown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${data['protein']}p • ${data['carbs']}c • ${data['fats']}f",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            Text(
              "${data['calories']} kcal",
              style: TextStyle(
                color: _calBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AI LOGIC (Unchanged) ---
  Future<void> _checkAndGenerateAiPlan(
    Map<String, dynamic> userData,
    String uid,
  ) async {
    if (userData.containsKey('ai_target_calories') &&
        userData['ai_target_calories'] > 0) {
      if (mounted)
        setState(() {
          _targetCalories = userData['ai_target_calories'];
          _targetProtein = userData['ai_target_protein'];
          _targetCarbs = userData['ai_target_carbs'];
          _targetFats = userData['ai_target_fats'];
          _currentMode = userData['diet_mode'] ?? "Balanced";
          _isLoadingPlan = false;
        });
      return;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );
      String profile =
          "Weight: ${userData['weight']}kg, Height: ${userData['height']}cm, Age: ${userData['age']}, Gender: ${userData['gender']}, Goal: ${userData['diet_mode'] ?? 'Balanced'}";
      final prompt =
          'Act as an elite sports nutritionist. Create a daily plan for: $profile. Return ONLY valid JSON: { "calories": 0, "protein": 0, "carbs": 0, "fats": 0 }';

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        Map<String, dynamic> aiData = jsonDecode(cleanJson);

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'ai_target_calories': aiData['calories'],
          'ai_target_protein': aiData['protein'],
          'ai_target_carbs': aiData['carbs'],
          'ai_target_fats': aiData['fats'],
          'diet_mode': userData['diet_mode'] ?? "Balanced",
        }, SetOptions(merge: true));

        if (mounted)
          setState(() {
            _targetCalories = aiData['calories'];
            _targetProtein = aiData['protein'];
            _targetCarbs = aiData['carbs'];
            _targetFats = aiData['fats'];
            _currentMode = userData['diet_mode'] ?? "Balanced";
            _isLoadingPlan = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }
}
