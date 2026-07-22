import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitcoach_/services/ai_api_key.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  final _supabase = Supabase.instance.client;

  String _selectedGoal = "Build Muscle";
  String _selectedLevel = "Intermediate";
  String _selectedEquipment = "Gym (Full)";
  String _selectedFocus = "Balanced";
  int _daysPerWeek = 4;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  double _bmi = 0.0;

  bool _isGenerating = false;
  bool _isSuccess = false;
  bool _isLoadingProfile = true;

  Timer? _phraseTimer;
  int _currentPhraseIndex = 0;
  final List<String> _loadingPhrases = [
    "Analyzing your profile...",
    "Calculating optimal volume...",
    "Selecting the best exercises...",
    "Tailoring sets and reps...",
    "Finalizing your true AI plan...",
  ];

  final List<String> _goals = [
    "Build Muscle",
    "Lose Weight",
    "Increase Strength",
  ];
  final List<String> _levels = ["Beginner", "Intermediate", "Pro"];
  final List<String> _equipmentOptions = [
    "Gym (Full)",
    "Home (Dumbbells)",
    "Bodyweight Only",
  ];
  final List<String> _focusOptions = [
    "Balanced",
    "Chest",
    "Arms",
    "Back",
    "Legs",
    "Glutes",
    "Shoulders",
  ];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  final Color _neonBlue = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            if (data.containsKey('weight')) {
              _weightController.text = data['weight'].toString();
            }
            if (data.containsKey('height')) {
              _heightController.text = data['height'].toString();
            }
            if (data.containsKey('fitness_level') &&
                _levels.contains(data['fitness_level'])) {
              _selectedLevel = data['fitness_level'];
            }
            if (data.containsKey('primary_goal') &&
                _goals.contains(data['primary_goal'])) {
              _selectedGoal = data['primary_goal'];
            }
            if (data.containsKey('equipment') &&
                _equipmentOptions.contains(data['equipment'])) {
              _selectedEquipment = data['equipment'];
            }
          });
        }
      } catch (e) {
        debugPrint("Profile Sync Error: $e");
      }
    }
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  void _calculateBMI() {
    double w = double.tryParse(_weightController.text) ?? 0;
    double h = double.tryParse(_heightController.text) ?? 0;
    if (w > 0 && h > 0) setState(() => _bmi = w / ((h / 100) * (h / 100)));
  }

  Future<void> _generateAndSavePlan() async {
    setState(() {
      _isGenerating = true;
      _isSuccess = false;
      _currentPhraseIndex = 0;
    });

    _phraseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          if (_currentPhraseIndex < _loadingPhrases.length - 1) {
            _currentPhraseIndex++;
          }
        });
      }
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _phraseTimer?.cancel();
      return;
    }

    try {
      await _supabase
          .from('users')
          .update({
            'weight': double.tryParse(_weightController.text) ?? 0,
            'height': double.tryParse(_heightController.text) ?? 0,
            'fitness_level': _selectedLevel,
            'primary_goal': _selectedGoal,
            'equipment': _selectedEquipment,
            'bmi': double.tryParse(_bmi.toStringAsFixed(1)) ?? 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: AiApiKey.value,
      );
      final prompt =
          '''
        Act as an elite personal trainer. Create a highly effective $_daysPerWeek-day workout split.
        User Profile: Goal: $_selectedGoal | Level: $_selectedLevel | Equipment: $_selectedEquipment | Focus: $_selectedFocus
        Return ONLY a valid JSON ARRAY of objects. No markdown.
        Structure:
        [
          {
            "day": "Day 1",
            "name": "Push Day",
            "exercises": [
              { "name": "Bench Press", "bodyPart": "Chest", "target": "Pectorals", "sets": 4, "reps": "8-12", "rest": 90 }
            ]
          }
        ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) throw "AI failed to generate a plan.";

      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      List<dynamic> aiSchedule = jsonDecode(cleanJson);

      List<Map<String, dynamic>> routinesToInsert = [];

      for (var session in aiSchedule) {
        String dayName = session['day'] ?? "Workout Day";
        String workoutName = session['name'] ?? "Workout";
        List<dynamic> aiExercises = session['exercises'] ?? [];
        List<Map<String, dynamic>> exercisesList = [];

        for (var aiEx in aiExercises) {
          int setsCount = aiEx['sets'] ?? 3;
          String reps = aiEx['reps'].toString();
          List<Map<String, dynamic>> setList = List.generate(
            setsCount,
            (_) => {"weight": "", "reps": reps, "isCompleted": false},
          );

          exercisesList.add({
            "id":
                "ai_gen_${DateTime.now().millisecondsSinceEpoch}_${aiEx['name'].hashCode}",
            "name": aiEx['name'],
            "bodyPart": aiEx['bodyPart'] ?? "Full Body",
            "target": aiEx['target'] ?? "Muscle",
            "sets": setList,
            "restTimeSeconds": aiEx['rest'] ?? 60,
          });
        }

        routinesToInsert.add({
          "user_id": user.id,
          "title": "$dayName: $workoutName",
          "day": dayName,
          "exercises": exercisesList,
          "generated_by_ai": true,
          "goal": _selectedGoal,
          "equipment": _selectedEquipment,
          "level": _selectedLevel,
          "createdAt": DateTime.now().toIso8601String(),
        });
      }

      await _supabase.from('routines').insert(routinesToInsert);

      if (mounted) {
        _phraseTimer?.cancel();
        setState(() => _isSuccess = true);
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✨ True AI Plan Built! Focus: $_selectedFocus"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _phraseTimer?.cancel();
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: _isSuccess
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 100,
                        )
                      : CircularProgressIndicator(
                          color: _neonBlue,
                          strokeWidth: 4,
                        ),
                ),
                if (!_isSuccess)
                  Icon(Icons.auto_awesome, color: _neonBlue, size: 40),
              ],
            ),
            const SizedBox(height: 50),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _isSuccess
                    ? "Plan Ready! Let's go."
                    : _loadingPhrases[_currentPhraseIndex],
                key: ValueKey<String>(
                  _isSuccess ? "Success" : _currentPhraseIndex.toString(),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isSuccess)
              Text(
                "Please don't close this screen",
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: _bgBlack,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
        title: _isGenerating
            ? null
            : Text(
                "AI Coach Pro",
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      body: _isGenerating
          ? _buildLoadingScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("1. Setup"),
                  _buildDropdown(
                    "Equipment",
                    _equipmentOptions,
                    _selectedEquipment,
                    (v) => setState(() => _selectedEquipment = v!),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputCard(
                          "Weight (kg)",
                          _weightController,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInputCard(
                          "Height (cm)",
                          _heightController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("2. Goals & Focus"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Level",
                          _levels,
                          _selectedLevel,
                          (v) => setState(() => _selectedLevel = v!),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDropdown(
                          "Focus Area",
                          _focusOptions,
                          _selectedFocus,
                          (v) => setState(() => _selectedFocus = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    "Primary Goal",
                    _goals,
                    _selectedGoal,
                    (v) => setState(() => _selectedGoal = v!),
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("3. Frequency: $_daysPerWeek Days"),
                  Slider(
                    value: _daysPerWeek.toDouble(),
                    min: 3,
                    max: 6,
                    divisions: 3,
                    activeColor: _neonBlue,
                    inactiveColor: _textGrey.withOpacity(0.3),
                    onChanged: (v) => setState(() => _daysPerWeek = v.toInt()),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _generateAndSavePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _neonBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "GENERATE TRUE AI PLAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Text(
      title,
      style: TextStyle(
        color: _textWhite,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );

  Widget _buildInputCard(String label, TextEditingController c) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(15),
      border: isDark ? null : Border.all(color: Colors.black12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _textGrey, fontSize: 11)),
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _textWhite, fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdown(
    String label,
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(15),
      border: isDark ? null : Border.all(color: Colors.black12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 11)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            dropdownColor: _cardDark,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: _textWhite),
            style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}
