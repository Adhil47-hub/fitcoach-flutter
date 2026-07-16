import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/services/ai_recommendation_service.dart';
import 'package:fitcoach_/screens/community/community_screen.dart';
import 'package:fitcoach_/screens/notifications_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';
import 'package:fitcoach_/screens/workout/workout_menu_screen.dart';
import 'package:fitcoach_/screens/workout/progress_screen.dart';
import 'package:fitcoach_/screens/nutrition/nutrition_screen.dart';
import 'package:fitcoach_/screens/activity/activity_details_screen.dart';
import 'package:fitcoach_/screens/recommendations_screen.dart';
import 'package:fitcoach_/screens/recommendation_detail_screen.dart';
import 'package:fitcoach_/screens/workout/auto_workout_generator.dart';
import 'package:fitcoach_/screens/article_screen.dart';
import 'package:fitcoach_/screens/article_list_screen.dart';
import 'package:fitcoach_/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitcoach_/services/notification_manager.dart';
import 'package:intl/intl.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final Health health = Health();
  final _supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>? _mealsSubscription;

  bool _isInitialLoad = true;

  List<Map<String, dynamic>> _aiRecommendations = [];
  bool _isLoadingRecommendations = true;

  int _stepCount = 0;
  double _waterIntakeLiters = 0.0;
  int _caloriesEaten = 0;
  bool _isWorkoutDone = false;
  String _todaysWorkout = "Rest Day";
  double _sleepHours = 0.0;
  int _streakDays = 0;

  int _stepGoal = 10000;
  double _waterGoalLiters = 3.0;
  int _caloriesGoal = 2000;
  double _sleepGoal = 8.0;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonGreen = const Color(0xFF00E676);

  User? get _currentUser => _supabase.auth.currentUser;
  String get _userName =>
      _currentUser?.userMetadata?['full_name']?.split(' ')[0] ?? "User";

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initializeDashboard();
    _setupMealsStream();
  }

  @override
  void dispose() {
    _mealsSubscription?.cancel();
    super.dispose();
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

  void _setupMealsStream() {
    if (_currentUser == null) return;

    try {
      _mealsSubscription = _supabase
          .from('meals')
          .stream(primaryKey: ['id'])
          .eq('user_id', _currentUser!.id)
          .listen((allMeals) {
            int totalCals = 0;
            for (var meal in allMeals) {
              if (meal['log_date'] == _todayKey || meal['date'] == _todayKey) {
                totalCals += (meal['calories'] as num?)?.toInt() ?? 0;
              }
            }

            if (mounted) {
              setState(() {
                _caloriesEaten = totalCals;
              });
              _syncRecommendationsWithState();
            }
          });
    } catch (e) {
      debugPrint("Meals Stream Error: $e");
    }
  }

  Future<void> _initializeDashboard() async {
    try {
      await Future.wait([
        _fetchStepData(),
        _loadUserGoals(),
        _loadRealTimeData(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Data Sync Error (Non-Fatal): $e");
    }

    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String cachedRecsStr = prefs.getString('ai_recs_$_todayKey') ?? '';

      if (cachedRecsStr.isNotEmpty) {
        final decodedRecs = List<Map<String, dynamic>>.from(
          json.decode(cachedRecsStr),
        );

        if (decodedRecs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _aiRecommendations = decodedRecs;
              _isLoadingRecommendations = false;
            });
            _syncRecommendationsWithState();
          }
          return;
        }
      }

      final aiRecs = await AiRecommendationService.getDynamicRecommendations(
        userName: _userName,
        goal: "General Fitness",
        currentSteps: _stepCount,
        stepGoal: _stepGoal,
        currentWater: _waterIntakeLiters,
        waterGoal: _waterGoalLiters,
        currentSleep: _sleepHours,
        sleepGoal: _sleepGoal,
      );

      if (aiRecs.isNotEmpty) {
        final safeToSave = aiRecs.map((rec) {
          final safeMap = Map<String, dynamic>.from(rec);
          safeMap.remove('icon');
          safeMap.remove('color');
          return safeMap;
        }).toList();

        await prefs.setString('ai_recs_$_todayKey', json.encode(safeToSave));
      }

      if (mounted) {
        setState(() {
          _aiRecommendations = aiRecs;
          _isLoadingRecommendations = false;
        });
        _syncRecommendationsWithState();
      }
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadUserGoals() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('goals')
          .select()
          .eq('user_id', _currentUser!.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _stepGoal = (response['step_goal'] as num?)?.toInt() ?? 10000;
          _waterGoalLiters =
              (response['water_goal'] as num?)?.toDouble() ?? 3.0;
          _caloriesGoal = (response['calories_goal'] as num?)?.toInt() ?? 2000;
          _sleepGoal = (response['sleep_goal'] as num?)?.toDouble() ?? 8.0;
        });
      }
    } catch (e) {
      debugPrint("Error loading goals: $e");
    }
  }

  Future<void> _loadRealTimeData() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('daily_logs')
          .select()
          .eq('user_id', _currentUser!.id)
          .eq('log_date', _todayKey)
          .order('last_updated', ascending: false)
          .limit(1);

      if (response.isNotEmpty && mounted) {
        final data = response.first;
        setState(() {
          _waterIntakeLiters = (data['water'] as num?)?.toDouble() ?? 0.0;
          _isWorkoutDone = data['workout_done'] == true;
          _todaysWorkout = data['workout_name']?.toString() ?? "Rest Day";
          _sleepHours = (data['sleep'] as num?)?.toDouble() ?? 0.0;
          _streakDays = (data['streak'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading realtime data: $e");
    }
  }

  Future<void> _syncRecommendationsWithState() async {
    if (_aiRecommendations.isEmpty) return;

    bool hasChanges = false;
    for (var i = 0; i < _aiRecommendations.length; i++) {
      final rec = _aiRecommendations[i];
      final title = (rec['title'] ?? '').toString().toLowerCase();
      final tag = (rec['tag'] ?? '').toString().toLowerCase();

      // STRICTER MATCHING RULES:
      if (tag.contains('water') ||
          tag.contains('hydration') ||
          tag.contains('daily goal') ||
          title.contains('hydrat')) {
        _aiRecommendations[i]['metric'] =
            "${_waterIntakeLiters.toStringAsFixed(1)} / ${_waterGoalLiters.toStringAsFixed(1)} L";
        hasChanges = true;
      } else if (tag.contains('step') ||
          tag.contains('activity') ||
          title.contains('step')) {
        _aiRecommendations[i]['metric'] = "$_stepCount / $_stepGoal steps";
        hasChanges = true;
      } else if (tag.contains('sleep') ||
          tag.contains('recovery') ||
          title.contains('bed')) {
        _aiRecommendations[i]['metric'] =
            "${_sleepHours.toStringAsFixed(1)} / ${_sleepGoal.toStringAsFixed(1)} hrs";
        hasChanges = true;
      } else if (tag.contains('fuel') || title.contains('calories')) {
        _aiRecommendations[i]['metric'] =
            "$_caloriesEaten / $_caloriesGoal Kcal";
        hasChanges = true;
      }
      // HIDE THE METRIC FOR MINDSET, NUTRITION, ETC.
      else {
        if (_aiRecommendations[i]['metric'] != "") {
          _aiRecommendations[i]['metric'] = "";
          hasChanges = true;
        }
      }
    }

    if (hasChanges && mounted) {
      setState(() {});

      try {
        final prefs = await SharedPreferences.getInstance();
        final safeToSave = _aiRecommendations.map((rec) {
          final safeMap = Map<String, dynamic>.from(rec);
          safeMap.remove('icon');
          safeMap.remove('color');
          return safeMap;
        }).toList();
        await prefs.setString('ai_recs_$_todayKey', json.encode(safeToSave));
      } catch (e) {
        debugPrint("Error syncing cache: $e");
      }
    }
  }

  Future<void> _addWater(double amount) async {
    if (_currentUser == null) return;

    setState(() => _waterIntakeLiters += amount);
    _syncRecommendationsWithState();

    try {
      final existingLog = await _supabase
          .from('daily_logs')
          .select('id')
          .eq('user_id', _currentUser!.id)
          .eq('log_date', _todayKey)
          .maybeSingle();

      if (existingLog != null) {
        await _supabase
            .from('daily_logs')
            .update({
              'water': _waterIntakeLiters,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', existingLog['id']);
      } else {
        await _supabase.from('daily_logs').insert({
          'user_id': _currentUser!.id,
          'log_date': _todayKey,
          'water': _waterIntakeLiters,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('waterReminders') ?? true) {
        await NotificationManager.instance.checkWaterGoal(
          _waterIntakeLiters,
          _waterGoalLiters,
        );
      }
    } catch (e) {
      debugPrint("Error saving water: $e");
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "💧 ${(amount * 1000).toInt()}ml logged! Total: ${_waterIntakeLiters.toStringAsFixed(2)}L",
          ),
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
              Text(
                "Log Water",
                style: TextStyle(
                  color: _textWhite,
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
            style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
          ),
          Text(sub, style: TextStyle(color: _textGrey, fontSize: 12)),
        ],
      ),
    );
  }

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
              Text(
                "Set Daily Goals",
                style: TextStyle(
                  color: _textWhite,
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
                "Based on your plan",
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
                      setState(() {
                        _stepGoal = int.tryParse(stepCtrl.text) ?? 10000;
                        _waterGoalLiters =
                            double.tryParse(waterCtrl.text) ?? 3.0;
                        _caloriesGoal = int.tryParse(calCtrl.text) ?? 2000;
                        _sleepGoal = double.tryParse(sleepCtrl.text) ?? 8.0;
                      });

                      await _supabase.from('goals').upsert({
                        'user_id': _currentUser!.id,
                        'step_goal': _stepGoal,
                        'water_goal': _waterGoalLiters,
                        'calories_goal': _caloriesGoal,
                        'sleep_goal': _sleepGoal,
                      });
                    }
                    if (mounted) Navigator.pop(context);
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
        style: TextStyle(color: _textWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textGrey),
          helperText: suggestion,
          helperStyle: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
          prefixIcon: Icon(icon, color: color),
          filled: true,
          fillColor: isDark ? Colors.black : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDark ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchStepData() async {
    List<HealthDataType> types = [HealthDataType.STEPS];
    try {
      bool hasPermissions = await health.hasPermissions(types) ?? false;
      if (!hasPermissions) {
        hasPermissions = await health.requestAuthorization(types);
      }
      if (hasPermissions) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);

        int? steps = await health.getTotalStepsInInterval(start, now);

        if (mounted) {
          setState(() {
            _stepCount = steps ?? 0;
          });
          _syncRecommendationsWithState();
        }
      }
    } catch (e) {
      debugPrint("Health Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return Scaffold(
        backgroundColor: _bgBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _neonYellow),
              const SizedBox(height: 20),
              Text(
                "Analyzing your progress...",
                style: TextStyle(color: _textGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgBlack,
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
                        builder: (_) => const WorkoutMenuScreen(),
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
                        builder: (_) => const NutritionScreen(),
                      ),
                    ),
                  ),
                  _buildFeatureBtn(
                    "Progress\nTracking",
                    Icons.bar_chart,
                    _purpleAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    ),
                  ),
                  _buildFeatureBtn(
                    "Community",
                    Icons.people,
                    Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSectionHeader(
                "Today's Activity",
                () async {
                  await Navigator.push(
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
                  await _loadRealTimeData();
                  _syncRecommendationsWithState();
                },
                trailingIcon: Icons.edit_outlined,
                onTrailingTap: _showEditGoalsDialog,
              ),
              const SizedBox(height: 15),
              _buildDailyActivityCards(),
              const SizedBox(height: 30),
              _buildSectionHeader("Recommendations", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationsScreen(
                      recommendations: _aiRecommendations,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              _buildRecommendationList(),
              const SizedBox(height: 30),
              _buildWeeklyChallenge(),
              const SizedBox(height: 30),
              _buildSectionHeader("Articles & Tips", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArticleListScreen()),
                );
              }),
              const SizedBox(height: 15),
              _buildArticleList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              child: Icon(Icons.search, color: _textWhite, size: 26),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Icon(
                Icons.notifications_none,
                color: _textWhite,
                size: 26,
              ),
            ),
            const SizedBox(width: 15),
            _buildProfileAvatar(),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('users')
            .stream(primaryKey: ['id'])
            .eq('id', _currentUser?.id ?? ''),
        builder: (context, snapshot) {
          String? profileImageUrl;
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            profileImageUrl = snapshot.data!.first['user_avatar'];
          }
          profileImageUrl ??= _currentUser?.userMetadata?['avatar_url'];
          return CircleAvatar(
            radius: 18,
            backgroundColor: _cardDark,
            backgroundImage:
                (profileImageUrl != null && profileImageUrl.isNotEmpty)
                ? NetworkImage(profileImageUrl)
                : null,
            child: (profileImageUrl == null || profileImageUrl.isEmpty)
                ? Icon(Icons.person, size: 20, color: _textGrey)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildDailyActivityCards() {
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
                (_stepCount / _stepGoal).clamp(0, 1),
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
                (_waterGoalLiters > 0)
                    ? (_waterIntakeLiters / _waterGoalLiters).clamp(0, 1)
                    : 0.0,
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
                _caloriesGoal > 0
                    ? (_caloriesEaten / _caloriesGoal).clamp(0, 1)
                    : 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NutritionScreen()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildWorkoutStatusCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutStatusCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutMenuScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _isWorkoutDone ? _neonGreen.withOpacity(0.1) : _cardDark,
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
                Text(
                  "Workout",
                  style: TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              _isWorkoutDone ? "Crushed It!" : _todaysWorkout,
              style: TextStyle(
                color: _textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _isWorkoutDone ? "Great job today." : "Not Started",
              style: TextStyle(
                color: _isWorkoutDone ? _neonGreen : _textGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: _isWorkoutDone ? _neonGreen : Colors.black12,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                _isWorkoutDone ? Icons.check : Icons.play_arrow,
                color: _isWorkoutDone ? Colors.black : _textWhite,
                size: 16,
              ),
            ),
          ],
        ),
      ),
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
                      style: TextStyle(
                        color: _textWhite,
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
              style: TextStyle(
                color: _textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subVal, style: TextStyle(color: _textGrey, fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress.isNaN || progress.isInfinite ? 0.0 : progress,
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

  Widget _buildRecommendationList() {
    if (_isLoadingRecommendations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_aiRecommendations.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _aiRecommendations.map((rec) {
          String cleanUrl = (rec["imageUrl"] ?? "")
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();

          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _buildRecommendationCard(
              rec["title"] ?? "",
              rec["tag"] ?? "",
              rec["metric"] ?? "",
              rec["icon"] ?? Icons.lightbulb,
              rec["color"] ?? Colors.grey,
              cleanUrl,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecommendationDetailScreen(
                    title: rec["title"] ?? "",
                    tag: rec["tag"] ?? "",
                    metric: rec["metric"] ?? "",
                    icon: rec["icon"] ?? Icons.lightbulb,
                    color: rec["color"] ?? Colors.grey,
                    imageUrl: cleanUrl,
                    description: rec["description"] ?? "",
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String subtitle,
    String metric,
    IconData icon,
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
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          icon,
                          color: _textGrey.withOpacity(0.5),
                          size: 50,
                        ),
                      )
                    : Icon(icon, color: _textGrey.withOpacity(0.5), size: 50),
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
                // ✅ HIDDEN IF EMPTY
                if (metric.isNotEmpty) ...[
                  const Spacer(),
                  Icon(Icons.timer_outlined, color: _textGrey, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      metric,
                      style: TextStyle(color: _textGrey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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

  Map<String, String> get _currentWeeklyChallenge {
    final List<Map<String, String>> challenges = [
      {
        "title": "Spartan Core",
        "subtitle": "Intense 10-minute ab circuit.",
        "image":
            "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=1470&auto=format&fit=crop",
      },
    ];
    return challenges[0];
  }

  Widget _buildWeeklyChallenge() {
    final challenge = _currentWeeklyChallenge;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AutoWorkoutGenerator(routineName: challenge["title"]!),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(challenge["image"]!),
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
                      "🔥 WEEKLY CHALLENGE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge["title"]!,
                    style: TextStyle(
                      color: _neonYellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge["subtitle"]!,
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

  Widget _buildArticleList() {
    final List<Map<String, dynamic>> articles = [
      {
        "title": "Supplement Guide 101",
        "image":
            "https://images.unsplash.com/photo-1593095948071-474c5cc2989d?q=80&w=1470&auto=format&fit=crop",
        "color": _purpleAccent,
      },
      {
        "title": "Recovery Protocols",
        "image":
            "https://images.unsplash.com/photo-1516481157630-05bc0aeb8b19?q=80&w=1470&auto=format&fit=crop",
        "color": Colors.blueAccent,
      },
      {
        "title": "Nutrition Myths Busted",
        "image":
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1470&auto=format&fit=crop",
        "color": _neonYellow,
      },
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: articles.map((article) {
          String cleanUrl = (article["image"] ?? "")
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _buildArticleCard(
              article["title"],
              cleanUrl,
              article["color"],
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleScreen(
                    title: article["title"],
                    imageUrl: cleanUrl,
                    color: article["color"],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArticleCard(
    String title,
    String imageUrl,
    Color color,
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
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
                color: color,
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
