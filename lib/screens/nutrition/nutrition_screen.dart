import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/services/ai_api_key.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitcoach_/screens/nutrition/ai_chef_screen.dart';
import 'package:fitcoach_/screens/nutrition/food_lens_screen.dart';
import 'package:fitcoach_/screens/nutrition/food_search_screen.dart';
import 'package:fitcoach_/screens/profilescreen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _supabase = Supabase.instance.client;

  int _selectedIndex = 0;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white10 : Colors.black12;

  final Color _calBlue = const Color(0xFF2F80ED);
  final Color _protPurple = const Color(0xFFBB86FC);
  final Color _fatRed = const Color(0xFFFF5252);
  final Color _carbGreen = const Color(0xFFD0FD3E);
  final Color _neonGreen = const Color(0xFFD0FD3E);

  final List<String> _dietPhases = [
    "Cutting",
    "Maintenance",
    "Bulking",
    "Body Recomposition",
    "Custom",
  ];

  int _targetCalories = 0;
  int _targetProtein = 0;
  int _targetCarbs = 0;
  int _targetFats = 0;
  String _currentMode = "Maintenance";
  String _coachRationale = "";
  bool _isLoadingPlan = true;
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null &&
          profile['custom_calories'] != null &&
          profile['custom_calories'] > 0) {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _targetCalories = (profile['custom_calories'] as num).toInt();
            _targetProtein =
                (profile['custom_protein'] as num?)?.toInt() ?? 150;
            _targetCarbs = (profile['custom_carbs'] as num?)?.toInt() ?? 200;
            _targetFats = (profile['custom_fats'] as num?)?.toInt() ?? 60;
            _coachRationale =
                prefs.getString('ai_rationale_${user.id}') ??
                "Plan optimized for your current physical profile.";
            _currentMode = profile['diet_mode'] ?? "Maintenance";
            _isLoadingPlan = false;
          });
        }
      } else if (profile != null) {
        await _checkAndGenerateAiPlan(profile, user.id);
      }
    } catch (e) {
      debugPrint("Load error: $e");
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _updateDietPhase(String newPhase) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _currentMode = newPhase;
      _isRecalculating = true;
    });

    try {
      await _supabase
          .from('users')
          .update({'diet_mode': newPhase})
          .eq('id', user.id);
      final profile = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        await _checkAndGenerateAiPlan(profile, user.id, forceRegenerate: true);
      }
    } catch (e) {
      debugPrint("Error updating diet phase: $e");
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  Future<void> _generateManualRationale(
    int cals,
    int prot,
    int carbs,
    int fat,
  ) async {
    setState(() {
      _coachRationale = "Analyzing your custom macro split...";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: AiApiKey.value,
      );
      final prompt =
          '''
        Act as an elite sports nutritionist. I have manually set my daily macro targets to:
        $cals calories, $prot g protein, $carbs g carbs, and $fat g fat.
        Write a concise, 2-sentence encouraging assessment explaining what this specific macro split is good for. 
        Do not use JSON formatting, just return the plain text response.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && mounted) {
        String newRationale = response.text!.trim();
        final prefs = await SharedPreferences.getInstance();
        final user = _supabase.auth.currentUser;

        if (user != null) {
          await prefs.setString('ai_rationale_${user.id}', newRationale);

          final existingGoal = await _supabase
              .from('goals')
              .select('user_id')
              .eq('user_id', user.id)
              .maybeSingle();
          if (existingGoal != null) {
            await _supabase
                .from('goals')
                .update({'coach_rationale': newRationale})
                .eq('user_id', user.id);
          }
        }

        setState(() {
          _coachRationale = newRationale;
        });
      }
    } catch (e) {
      debugPrint("Manual Rationale Error: $e");
      if (mounted) {
        setState(() {
          _coachRationale =
              "Custom targets saved. Keep pushing towards your goals.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("Login Required", style: TextStyle(color: _textWhite)),
        ),
      );
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('meals')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('timestamp'),
      builder: (context, logSnapshot) {
        int consumedCals = 0;
        int consumedProt = 0;
        int consumedCarbs = 0;
        int consumedFat = 0;

        final allMeals = logSnapshot.data ?? [];
        final meals = allMeals.where((m) => m['log_date'] == today).toList();
        meals.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        for (var data in meals) {
          consumedCals += (data['calories'] as num).toInt();
          consumedProt += (data['protein'] as num).toInt();
          consumedCarbs += (data['carbs'] as num).toInt();
          consumedFat += (data['fats'] as num).toInt();
        }

        return Scaffold(
          backgroundColor: _bgBlack,
          appBar: _buildAppBar(),
          body: _isRecalculating || _isLoadingPlan
              ? _buildRecalculatingOverlay()
              : (_selectedIndex == 0
                    ? _buildDashboardView(
                        consumedCals,
                        consumedProt,
                        consumedCarbs,
                        consumedFat,
                      )
                    : _buildDiaryView(meals)),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: _buildAddFab(),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildDashboardView(int cals, int prot, int carbs, int fat) {
    int remaining = _targetCalories - cals;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiChefBanner(),
          const SizedBox(height: 25),

          _buildPhaseSelector(),
          const SizedBox(height: 15),

          if (_coachRationale.isNotEmpty) ...[
            _buildAiRationaleCard(),
            const SizedBox(height: 20),
          ],

          _buildCalorieProgressCard(remaining, cals),
          const SizedBox(height: 20),
          _buildMacroProgressCard(prot, carbs, fat),
        ],
      ),
    );
  }

  Widget _buildPhaseSelector() {
    String displayMode = _dietPhases.contains(_currentMode)
        ? _currentMode
        : "Maintenance";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes, color: _calBlue, size: 20),
              const SizedBox(width: 10),
              Text(
                "Current Phase",
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayMode,
              dropdownColor: _cardDark,
              icon: Icon(Icons.arrow_drop_down, color: _textGrey),
              style: TextStyle(
                color: _calBlue,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              items: _dietPhases.map((phase) {
                return DropdownMenuItem(value: phase, child: Text(phase));
              }).toList(),
              onChanged: (newPhase) {
                if (newPhase != null &&
                    newPhase != _currentMode &&
                    newPhase != "Custom") {
                  _updateDietPhase(newPhase);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryView(List<Map<String, dynamic>> meals) {
    String displayDate = DateFormat('EEEE, d MMM').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, color: _textGrey),
              const SizedBox(width: 15),
              Text(
                displayDate,
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 15),
              Icon(Icons.chevron_right, color: _textGrey),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Logs",
                style: TextStyle(
                  color: _textWhite,
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
                  color: _dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentMode,
                  style: TextStyle(
                    color: _textWhite.withOpacity(0.7),
                    fontSize: 10,
                  ),
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
                border: Border.all(color: _dividerColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.no_food_outlined,
                    size: 40,
                    color: _textGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No food logged yet.",
                    style: TextStyle(color: _textGrey),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: meals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildDiaryTile(meals[index]),
            ),
        ],
      ),
    );
  }

  void _showManualEditSheet() {
    final k = TextEditingController(text: _targetCalories.toString());
    final p = TextEditingController(text: _targetProtein.toString());
    final c = TextEditingController(text: _targetCarbs.toString());
    final f = TextEditingController(text: _targetFats.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: _textWhite),
                const SizedBox(width: 12),
                Text(
                  "Edit Goal Targets",
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _buildInputField("Daily Calories", k, _calBlue),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField("Protein (g)", p, _protPurple),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInputField("Carbs (g)", c, _carbGreen)),
                const SizedBox(width: 15),
                Expanded(child: _buildInputField("Fats (g)", f, _fatRed)),
              ],
            ),
            const SizedBox(height: 20),
            _buildManualSaveButton(k, p, c, f),
            const SizedBox(height: 10),
            _buildResetToAiButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieProgressCard(int remaining, int cals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Calories",
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildProgressCircle(remaining),
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
    );
  }

  Widget _buildProgressCircle(int remaining) {
    double progress = _targetCalories > 0
        ? (remaining / _targetCalories).clamp(0.0, 1.0)
        : 0;
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
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
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("left", style: TextStyle(color: _textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressCard(int p, int c, int f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Macros",
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: _textGrey, size: 20),
                onPressed: _showManualEditSheet,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCircle("Carbs", c, _targetCarbs, _carbGreen),
              _buildMacroCircle("Protein", p, _targetProtein, _protPurple),
              _buildMacroCircle("Fat", f, _targetFats, _fatRed),
            ],
          ),
        ],
      ),
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
                  backgroundColor: isDark
                      ? Colors.white10
                      : Colors.grey.shade200,
                  color: color,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$remaining",
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
        Text(
          "${current}/${target}g",
          style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 10),
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
            colors: [_calBlue.withOpacity(0.9), const Color(0xFF9C27B0)],
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

  Widget _buildAiRationaleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: _protPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                "AI Coach Assessment",
                style: TextStyle(
                  color: _protPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _coachRationale,
            style: TextStyle(color: _textWhite, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRecalculatingOverlay() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _protPurple),
        const SizedBox(height: 20),
        Text(
          "AI is calculating your perfect macros...",
          style: TextStyle(color: _textGrey),
        ),
      ],
    ),
  );

  Widget _buildManualSaveButton(
    TextEditingController k,
    TextEditingController p,
    TextEditingController c,
    TextEditingController f,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _calBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () async {
          final user = _supabase.auth.currentUser;
          if (user != null) {
            final cals = int.tryParse(k.text) ?? 2000;
            final prot = int.tryParse(p.text) ?? 150;
            final carbs = int.tryParse(c.text) ?? 200;
            final fat = int.tryParse(f.text) ?? 60;

            await _supabase
                .from('users')
                .update({
                  'custom_calories': cals,
                  'custom_protein': prot,
                  'custom_carbs': carbs,
                  'custom_fats': fat,
                  'diet_mode': 'Custom',
                })
                .eq('id', user.id);

            try {
              final existingGoal = await _supabase
                  .from('goals')
                  .select('user_id')
                  .eq('user_id', user.id)
                  .maybeSingle();
              if (existingGoal != null) {
                await _supabase
                    .from('goals')
                    .update({
                      'calories_goal': cals,
                      'protein_goal': prot,
                      'carbs_goal': carbs,
                      'fats_goal': fat,
                    })
                    .eq('user_id', user.id);
              } else {
                await _supabase.from('goals').insert({
                  'user_id': user.id,
                  'calories_goal': cals,
                  'protein_goal': prot,
                  'carbs_goal': carbs,
                  'fats_goal': fat,
                });
              }
            } catch (dbError) {
              debugPrint("Error saving to goals table: $dbError");
            }

            setState(() {
              _targetCalories = cals;
              _targetProtein = prot;
              _targetCarbs = carbs;
              _targetFats = fat;
              _currentMode = "Custom";
            });

            _generateManualRationale(cals, prot, carbs, fat);
            Navigator.pop(context);
          }
        },
        child: const Text(
          "SAVE TARGETS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResetToAiButton() {
    return TextButton.icon(
      onPressed: () async {
        Navigator.pop(context);
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final profile = await _supabase
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (profile != null) {
            _checkAndGenerateAiPlan(profile, user.id, forceRegenerate: true);
          }
        }
      },
      icon: Icon(Icons.auto_awesome, color: _protPurple),
      label: Text(
        "Reset to AI Recommendation",
        style: TextStyle(color: _protPurple, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardDark,
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
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
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
              style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String l, TextEditingController c, Color col) =>
      TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: TextStyle(color: _textWhite),
        decoration: InputDecoration(
          labelText: l,
          labelStyle: TextStyle(color: col, fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );

  Widget _buildLegendRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: _textGrey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _textWhite, fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgBlack,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        _selectedIndex == 0 ? "Nutrition Dashboard" : "Food Diary",
        style: TextStyle(
          color: _textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textWhite),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: _textWhite),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: _cardDark,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded,
                color: _selectedIndex == 0 ? _calBlue : _textGrey,
                size: 28,
              ),
              onPressed: () => setState(() => _selectedIndex = 0),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: Icon(
                Icons.book_outlined,
                color: _selectedIndex == 1 ? _calBlue : _textGrey,
                size: 28,
              ),
              onPressed: () => setState(() => _selectedIndex = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFab() {
    return FloatingActionButton(
      onPressed: () => _showAddMenu(context),
      backgroundColor: _calBlue,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }

  Widget _buildDiaryTile(Map<String, dynamic> data) {
    return Dismissible(
      key: Key(data['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: _fatRed.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: _fatRed),
      ),
      onDismissed: (_) async =>
          await _supabase.from('meals').delete().eq('id', data['id']),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['food_name'] ?? "Unknown",
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${data['protein']}p • ${data['carbs']}c • ${data['fats']}f",
                  style: TextStyle(color: _textGrey, fontSize: 12),
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

  Future<void> _checkAndGenerateAiPlan(
    Map<String, dynamic> userData,
    String uid, {
    bool forceRegenerate = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String currentMode = userData['diet_mode'] ?? "Maintenance";

    if (mounted) {
      setState(() {
        _isRecalculating = true;
        _currentMode = currentMode;
      });
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: AiApiKey.value,
      );

      String profile =
          "Weight: ${userData['weight'] ?? 70}kg, Height: ${userData['height'] ?? 175}cm, Age: ${userData['age'] ?? 25}, Goal: $currentMode";

      final prompt =
          'Act as an elite sports nutritionist. Create a daily plan for: $profile. Return ONLY valid JSON exactly like this: { "calories": 2000, "protein": 150, "carbs": 200, "fats": 60, "rationale": "Write 2 sentences explaining why." }';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final int startIndex = cleanJson.indexOf('{');
        final int endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        Map<String, dynamic> aiData = jsonDecode(cleanJson);

        int cals = int.tryParse(aiData['calories'].toString()) ?? 2000;
        int prot = int.tryParse(aiData['protein'].toString()) ?? 150;
        int carbs = int.tryParse(aiData['carbs'].toString()) ?? 200;
        int fat =
            int.tryParse(aiData['fats'].toString()) ??
            (aiData['fat'] != null
                ? int.tryParse(aiData['fat'].toString()) ?? 60
                : 60);
        String generatedRationale =
            aiData['rationale'] ??
            aiData['coach_rationale'] ??
            "Custom plan optimized for your goals.";

        await _supabase
            .from('users')
            .update({
              'custom_calories': cals,
              'custom_protein': prot,
              'custom_carbs': carbs,
              'custom_fats': fat,
            })
            .eq('id', uid);

        try {
          final existingGoal = await _supabase
              .from('goals')
              .select('user_id')
              .eq('user_id', uid)
              .maybeSingle();
          if (existingGoal != null) {
            await _supabase
                .from('goals')
                .update({
                  'calories_goal': cals,
                  'protein_goal': prot,
                  'carbs_goal': carbs,
                  'fats_goal': fat,
                  'coach_rationale': generatedRationale,
                })
                .eq('user_id', uid);
          } else {
            await _supabase.from('goals').insert({
              'user_id': uid,
              'calories_goal': cals,
              'protein_goal': prot,
              'carbs_goal': carbs,
              'fats_goal': fat,
              'coach_rationale': generatedRationale,
            });
          }
        } catch (dbError) {
          debugPrint("Error saving to goals table: $dbError");
        }

        await prefs.setString('ai_rationale_$uid', generatedRationale);

        if (mounted) {
          setState(() {
            _targetCalories = cals;
            _targetProtein = prot;
            _targetCarbs = carbs;
            _targetFats = fat;
            _coachRationale = generatedRationale;
            _currentMode = currentMode;
            _isLoadingPlan = false;
            _isRecalculating = false;
          });
        }
      }
    } catch (e) {
      debugPrint("AI Error: $e");

      if (mounted) {
        setState(() {
          _targetCalories = 2200;
          _targetProtein = 160;
          _targetCarbs = 220;
          _targetFats = 70;
          _coachRationale =
              "Standard fallback plan applied. Please try regenerating later.";
          _isLoadingPlan = false;
          _isRecalculating = false;
        });
      }
    }
  }
}
