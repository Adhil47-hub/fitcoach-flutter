import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/workout/active_workout_screen.dart'; // ✅ Imports your exact screen!

class AutoWorkoutGenerator extends StatefulWidget {
  final String routineName;
  const AutoWorkoutGenerator({super.key, required this.routineName});

  @override
  State<AutoWorkoutGenerator> createState() => _AutoWorkoutGeneratorState();
}

class _AutoWorkoutGeneratorState extends State<AutoWorkoutGenerator> {
  @override
  void initState() {
    super.initState();
    _generateAndStartWorkout();
  }

  Future<void> _generateAndStartWorkout() async {
    // 1. Simulate the AI processing time (Later, you will call Gemini/ChatGPT here)
    await Future.delayed(const Duration(seconds: 3));

    // 2. Generate the payload EXACTLY how your existing ActiveWorkoutScreen expects it
    List<Map<String, dynamic>> generatedExercises = [
      {
        "id": "ai_ex_1",
        "name": "Barbell Bench Press",
        "sets": [
          {"weight": "", "reps": "10"},
          {"weight": "", "reps": "10"},
          {"weight": "", "reps": "8"},
          {"weight": "", "reps": "8"},
        ]
      },
      {
        "id": "ai_ex_2",
        "name": "Incline Dumbbell Press",
        "sets": [
          {"weight": "", "reps": "12"},
          {"weight": "", "reps": "10"},
          {"weight": "", "reps": "10"},
        ]
      },
      {
        "id": "ai_ex_3",
        "name": "Overhead Strict Press",
        "sets": [
          {"weight": "", "reps": "10"},
          {"weight": "", "reps": "8"},
          {"weight": "", "reps": "8"},
        ]
      },
      {
        "id": "ai_ex_4",
        "name": "Tricep Pushdowns",
        "sets": [
          {"weight": "", "reps": "15"},
          {"weight": "", "reps": "12"},
          {"weight": "", "reps": "12"},
        ]
      },
    ];

    // 3. Push Replacement straight into YOUR active tracking screen!
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveWorkoutScreen(
            routineTitle: widget.routineName, // Your screen uses routineTitle
            exercises: generatedExercises,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFD0FD3E)),
            const SizedBox(height: 30),
            Text(
              "AI is building '${widget.routineName}'...",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Optimizing sets and reps for your profile...",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}