import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:fitcoach_/services/exercise_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiGenerateScreen extends StatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> {
  // --- CONFIGURATION ---
  // ✅ Verified working Gemini key
  final String _apiKey = 'AIzaSyCXF7tJQT9wjqXMhg2o1ZzONDP4ZxhjblA';

  // --- USER INPUTS ---
  String _selectedGoal = "Build Muscle";
  String _selectedLevel = "Intermediate";
  String _selectedEquipment = "Gym (Full)";
  String _selectedFocus = "Balanced";
  int _daysPerWeek = 4;

  // Body Stats
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  double _bmi = 0.0;

  bool _isGenerating = false;
  bool _isLoadingProfile = true;

  // Options
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

  final Color _bgBlack = const Color(0xFF0F0F10);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              if (data.containsKey('weight'))
                _weightController.text = data['weight'].toString();
              if (data.containsKey('height'))
                _heightController.text = data['height'].toString();
              if (data.containsKey('fitnessLevel') &&
                  _levels.contains(data['fitnessLevel']))
                _selectedLevel = data['fitnessLevel'];
              if (data.containsKey('primaryGoal') &&
                  _goals.contains(data['primaryGoal']))
                _selectedGoal = data['primaryGoal'];
              if (data.containsKey('equipment') &&
                  _equipmentOptions.contains(data['equipment']))
                _selectedEquipment = data['equipment'];
            });
          }
        }
      } catch (e) {
        print("Profile Sync Error: $e");
      }
    }
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  void _calculateBMI() {
    double w = double.tryParse(_weightController.text) ?? 0;
    double h = double.tryParse(_heightController.text) ?? 0;
    if (w > 0 && h > 0) {
      setState(() => _bmi = w / ((h / 100) * (h / 100)));
    }
  }

  // --- TRUE AI WORKOUT GENERATION ---
  Future<void> _generateAndSavePlan() async {
    setState(() => _isGenerating = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Save User Profile Updates
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'weight': double.tryParse(_weightController.text) ?? 0,
        'height': double.tryParse(_heightController.text) ?? 0,
        'fitnessLevel': _selectedLevel,
        'primaryGoal': _selectedGoal,
        'equipment': _selectedEquipment,
        'bmi': double.tryParse(_bmi.toStringAsFixed(1)) ?? 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Fetch all local exercises to match with AI suggestions (for GIFs)
      final allExercises = await ExerciseApiService.fetchExercises(limit: 3000);

      // 3. Ask Gemini to build the plan
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );
      final prompt =
          '''
        Act as an elite personal trainer. Create a highly effective $_daysPerWeek-day workout split.
        User Profile:
        - Goal: $_selectedGoal
        - Level: $_selectedLevel
        - Available Equipment: $_selectedEquipment
        - Primary Focus Area: $_selectedFocus
        
        Use standard, well-known exercise names (e.g. "Bench Press", "Squat", "Bicep Curl").
        Return ONLY a valid JSON ARRAY of objects. No markdown, no explanations. 
        Structure exactly like this:
        [
          {
            "day": "Day 1",
            "name": "Push Day (Chest/Tri/Shoulders)",
            "exercises": [
              { "name": "Barbell Bench Press", "target": "Chest", "sets": 4, "reps": "8-12", "rest": 90 },
              { "name": "Overhead Press", "target": "Shoulders", "sets": 3, "reps": "10-12", "rest": 60 }
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

      // 4. Match AI exercises with our DB and save to Firestore
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var session in aiSchedule) {
        String dayName = session['day'] ?? "Workout Day";
        String workoutName = session['name'] ?? "Workout";
        List<dynamic> aiExercises = session['exercises'] ?? [];
        List<Map<String, dynamic>> finalExercisesToSave = [];

        for (var aiEx in aiExercises) {
          String searchName = aiEx['name'].toString().toLowerCase();

          // Try to find a matching exercise in our local database for the GIF
          Exercise? matchedExercise;
          try {
            matchedExercise = allExercises.firstWhere(
              (e) =>
                  e.name.toLowerCase() == searchName ||
                  e.name.toLowerCase().contains(searchName.split(' ').first),
            ); // Basic matching logic
          } catch (e) {
            matchedExercise = null; // No match found
          }

          // Build sets array based on AI recommendation
          int setsCount = aiEx['sets'] ?? 3;
          String reps = aiEx['reps'].toString();
          List<Map<String, dynamic>> setList = [];
          for (int i = 0; i < setsCount; i++) {
            setList.add({"weight": "", "reps": reps, "isCompleted": false});
          }

          finalExercisesToSave.add({
            "id":
                matchedExercise?.id ??
                DateTime.now().millisecondsSinceEpoch
                    .toString(), // Real ID or dummy
            "name": aiEx['name'], // Keep the AI's exact name
            "bodyPart": matchedExercise?.bodyPart ?? "Full Body",
            "target": matchedExercise?.target ?? aiEx['target'] ?? "Muscle",
            "gifUrl": matchedExercise?.gifUrl ?? "",
            "sets": setList,
            "restTimeSeconds": aiEx['rest'] ?? 60,
            "role": "AI Gen",
          });
        }

        DocumentReference docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('routines')
            .doc();

        batch.set(docRef, {
          "title": "$dayName: $workoutName",
          "day": dayName,
          "createdAt": FieldValue.serverTimestamp(),
          "exercises": finalExercisesToSave,
          "generatedByAi": true,
          "goal": _selectedGoal,
          "equipment": _selectedEquipment,
          "level": _selectedLevel,
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ True AI Plan Built! Focus: $_selectedFocus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
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
        title: const Text(
          "AI Coach Pro",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                  child: _buildInputCard("Weight (kg)", _weightController),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputCard("Height (cm)", _heightController),
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
              onChanged: (v) => setState(() => _daysPerWeek = v.toInt()),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateAndSavePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 15),
                          Text(
                            "AI IS THINKING...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
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

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  );

  Widget _buildInputCard(String label, TextEditingController c) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              dropdownColor: _cardDark,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
}
