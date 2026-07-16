import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/workout/active_workout_screen.dart';

class AutoWorkoutGenerator extends StatefulWidget {
  final String routineName;
  const AutoWorkoutGenerator({super.key, required this.routineName});

  @override
  State<AutoWorkoutGenerator> createState() => _AutoWorkoutGeneratorState();
}

class _AutoWorkoutGeneratorState extends State<AutoWorkoutGenerator> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  @override
  void initState() {
    super.initState();
    _loadHardcodedWorkout();
  }

  Future<void> _loadHardcodedWorkout() async {
    await Future.delayed(const Duration(seconds: 1));

    final workout = _get20HardcodedWorkouts(widget.routineName);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveWorkoutScreen(
            routineTitle: widget.routineName,
            exercises: workout,
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _get20HardcodedWorkouts(String name) {
    List<Map<String, dynamic>> standardSets(String reps) => [
      {"weight": "", "reps": reps},
      {"weight": "", "reps": reps},
      {"weight": "", "reps": reps},
    ];

    switch (name) {
      case "Spartan Core":
        return [
          {"id": "1", "name": "Crunches", "sets": standardSets("20")},
          {"id": "2", "name": "Plank", "sets": standardSets("60s")},
          {"id": "3", "name": "Russian Twists", "sets": standardSets("20")},
          {"id": "4", "name": "Leg Raises", "sets": standardSets("15")},
        ];
      case "Leg Day Burner":
        return [
          {"id": "1", "name": "Barbell Squats", "sets": standardSets("12")},
          {"id": "2", "name": "Dumbbell Lunges", "sets": standardSets("12")},
          {"id": "3", "name": "Leg Press", "sets": standardSets("10")},
          {"id": "4", "name": "Calf Raises", "sets": standardSets("15")},
        ];
      case "Upper Body Forge":
        return [
          {"id": "1", "name": "Bench Press", "sets": standardSets("10")},
          {"id": "2", "name": "Overhead Press", "sets": standardSets("10")},
          {"id": "3", "name": "Barbell Rows", "sets": standardSets("12")},
          {"id": "4", "name": "Bicep Curls", "sets": standardSets("15")},
        ];
      case "Full Body HIIT":
        return [
          {"id": "1", "name": "Burpees", "sets": standardSets("15")},
          {"id": "2", "name": "Jump Squats", "sets": standardSets("20")},
          {"id": "3", "name": "Pushups", "sets": standardSets("15")},
          {"id": "4", "name": "Mountain Climbers", "sets": standardSets("30")},
        ];
      case "Push Day Power":
        return [
          {
            "id": "1",
            "name": "Incline Dumbbell Press",
            "sets": standardSets("10"),
          },
          {
            "id": "2",
            "name": "Seated Shoulder Press",
            "sets": standardSets("10"),
          },
          {"id": "3", "name": "Lateral Raises", "sets": standardSets("15")},
          {"id": "4", "name": "Tricep Pushdowns", "sets": standardSets("15")},
        ];
      case "Pull Day Chisel":
        return [
          {"id": "1", "name": "Pull-ups", "sets": standardSets("8")},
          {"id": "2", "name": "Lat Pulldowns", "sets": standardSets("12")},
          {"id": "3", "name": "Face Pulls", "sets": standardSets("15")},
          {"id": "4", "name": "Hammer Curls", "sets": standardSets("12")},
        ];
      case "Glute Builder":
        return [
          {
            "id": "1",
            "name": "Barbell Hip Thrusts",
            "sets": standardSets("12"),
          },
          {"id": "2", "name": "Romanian Deadlifts", "sets": standardSets("10")},
          {
            "id": "3",
            "name": "Bulgarian Split Squats",
            "sets": standardSets("10"),
          },
          {"id": "4", "name": "Cable Kickbacks", "sets": standardSets("15")},
        ];
      case "Shoulder Boulders":
        return [
          {
            "id": "1",
            "name": "Dumbbell Shoulder Press",
            "sets": standardSets("10"),
          },
          {"id": "2", "name": "Arnold Press", "sets": standardSets("10")},
          {"id": "3", "name": "Front Raises", "sets": standardSets("12")},
          {"id": "4", "name": "Dumbbell Shrugs", "sets": standardSets("15")},
        ];
      case "Arm Day Blast":
        return [
          {"id": "1", "name": "Barbell Curls", "sets": standardSets("10")},
          {"id": "2", "name": "Skullcrushers", "sets": standardSets("10")},
          {"id": "3", "name": "Preacher Curls", "sets": standardSets("12")},
          {"id": "4", "name": "Tricep Dips", "sets": standardSets("12")},
        ];
      case "Cardio Shred":
        return [
          {"id": "1", "name": "High Knees", "sets": standardSets("45s")},
          {"id": "2", "name": "Jumping Jacks", "sets": standardSets("60s")},
          {"id": "3", "name": "Skaters", "sets": standardSets("40s")},
          {"id": "4", "name": "Half Burpees", "sets": standardSets("15")},
        ];
      case "Mobility & Core":
        return [
          {"id": "1", "name": "Bird Dog", "sets": standardSets("12")},
          {"id": "2", "name": "Dead Bug", "sets": standardSets("12")},
          {"id": "3", "name": "Plank", "sets": standardSets("60s")},
          {"id": "4", "name": "Side Plank", "sets": standardSets("30s")},
        ];
      case "Functional Fitness":
        return [
          {"id": "1", "name": "Kettlebell Swings", "sets": standardSets("15")},
          {"id": "2", "name": "Farmer's Walk", "sets": standardSets("60s")},
          {"id": "3", "name": "Box Jumps", "sets": standardSets("10")},
          {"id": "4", "name": "Bear Crawl", "sets": standardSets("30s")},
        ];
      case "Plyo Power":
        return [
          {"id": "1", "name": "Lunge Jumps", "sets": standardSets("16")},
          {"id": "2", "name": "Clapping Pushups", "sets": standardSets("10")},
          {"id": "3", "name": "Broad Jumps", "sets": standardSets("10")},
          {"id": "4", "name": "Tuck Jumps", "sets": standardSets("12")},
        ];
      case "Chest & Triceps":
        return [
          {
            "id": "1",
            "name": "Decline Bench Press",
            "sets": standardSets("10"),
          },
          {"id": "2", "name": "Pec Deck Flyes", "sets": standardSets("12")},
          {"id": "3", "name": "Close Grip Bench", "sets": standardSets("10")},
          {
            "id": "4",
            "name": "Overhead Tricep Extension",
            "sets": standardSets("12"),
          },
        ];
      case "Back & Core":
        return [
          {"id": "1", "name": "Deadlifts", "sets": standardSets("8")},
          {"id": "2", "name": "T-Bar Rows", "sets": standardSets("10")},
          {"id": "3", "name": "Ab Wheel Rollouts", "sets": standardSets("12")},
          {"id": "4", "name": "Hyperextensions", "sets": standardSets("15")},
        ];
      case "Lower Body Strength":
        return [
          {"id": "1", "name": "Front Squats", "sets": standardSets("8")},
          {"id": "2", "name": "Hack Squats", "sets": standardSets("10")},
          {"id": "3", "name": "Leg Extensions", "sets": standardSets("12")},
          {"id": "4", "name": "Seated Calf Raises", "sets": standardSets("15")},
        ];
      case "Bodyweight Mastery":
        return [
          {"id": "1", "name": "Pistol Squats", "sets": standardSets("6")},
          {"id": "2", "name": "Pike Pushups", "sets": standardSets("10")},
          {"id": "3", "name": "L-Sit Hold", "sets": standardSets("20s")},
          {"id": "4", "name": "Pull-ups", "sets": standardSets("8")},
        ];
      case "Core Stabilizer":
        return [
          {"id": "1", "name": "Hollow Hold", "sets": standardSets("45s")},
          {"id": "2", "name": "Superman", "sets": standardSets("15")},
          {"id": "3", "name": "Pallof Press", "sets": standardSets("12")},
          {"id": "4", "name": "V-Ups", "sets": standardSets("15")},
        ];
      case "Endurance Builder":
        return [
          {"id": "1", "name": "Wall Sit", "sets": standardSets("60s")},
          {"id": "2", "name": "High Rep Squats", "sets": standardSets("30")},
          {"id": "3", "name": "Long Plank", "sets": standardSets("90s")},
          {"id": "4", "name": "Step Ups", "sets": standardSets("20")},
        ];
      case "Ultimate Finisher":
        return [
          {"id": "1", "name": "Thrusters", "sets": standardSets("12")},
          {"id": "2", "name": "Battle Ropes", "sets": standardSets("45s")},
          {"id": "3", "name": "Man Makers", "sets": standardSets("8")},
          {
            "id": "4",
            "name": "Kettlebell Snatches",
            "sets": standardSets("15"),
          },
        ];
      default:
        return [
          {"id": "1", "name": "Pushups", "sets": standardSets("15")},
          {"id": "2", "name": "Squats", "sets": standardSets("20")},
          {"id": "3", "name": "Lunges", "sets": standardSets("16")},
          {"id": "4", "name": "Plank", "sets": standardSets("60s")},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _neonYellow),
              const SizedBox(height: 30),
              Text(
                "Loading '${widget.routineName}'...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
