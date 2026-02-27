import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/workout/exercise_list_screen.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:flutter/material.dart';

// --- LOCAL MODELS ---
class ActiveSet {
  final TextEditingController kgController;
  final TextEditingController repsController;
  bool isCompleted;

  ActiveSet({String kg = "", String reps = "", this.isCompleted = false})
    : kgController = TextEditingController(text: kg),
      repsController = TextEditingController(text: reps);
}

class ActiveExercise {
  String name;
  String id;
  List<ActiveSet> sets;
  String? supersetId;

  ActiveExercise({
    required this.name,
    required this.id,
    required this.sets,
    this.supersetId,
  });
}

class ActiveWorkoutScreen extends StatefulWidget {
  final String routineTitle;
  final List<dynamic> exercises;

  const ActiveWorkoutScreen({
    super.key,
    required this.routineTitle,
    required this.exercises,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _workoutTimer;
  int _secondsElapsed = 0;
  List<ActiveExercise> _activeExercises = [];
  bool _isSaving = false;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  final Color _bgBlack = const Color(0xFF0F0F10);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _neonBlue = Colors.blueAccent;
  final Color _textWhite = Colors.white;
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _supersetPurple = const Color(0xFFBB86FC);

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
    _initializeData();
  }

  void _initializeData() {
    _activeExercises = widget.exercises.map((ex) {
      List<dynamic> rawSets = ex['sets'] ?? [];
      if (rawSets.isEmpty)
        rawSets = [
          {'weight': '', 'reps': ''},
        ];

      List<ActiveSet> activeSets = rawSets.map((s) {
        return ActiveSet(
          kg: s['weight']?.toString() ?? "",
          reps: s['reps']?.toString() ?? "",
          isCompleted: false,
        );
      }).toList();

      return ActiveExercise(
        name: ex['name'] ?? "Unknown",
        id: ex['id'] ?? "unknown_id",
        sets: activeSets,
        supersetId: ex['supersetId'],
      );
    }).toList();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  // --- REST TIMER ---
  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_restSecondsRemaining > 0)
            _restSecondsRemaining--;
          else
            _restTimer?.cancel();
        });
      }
    });
  }

  void _showRestTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Set Rest Timer",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 15,
                  children: [30, 60, 90, 120]
                      .map(
                        (s) => ElevatedButton(
                          onPressed: () {
                            _startRestTimer(s);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                          ),
                          child: Text(
                            "${s}s",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- PLATE CALCULATOR ---
  void _showPlateCalculator() {
    final TextEditingController weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardDark,
          title: const Text(
            "Plate Calculator",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Target Weight (kg)",
                style: TextStyle(color: Colors.grey),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                onSubmitted: (val) {
                  Navigator.pop(context);
                  _calculatePlates(double.tryParse(val) ?? 0);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                "Assumes 20kg Bar",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _calculatePlates(double.tryParse(weightController.text) ?? 0);
              },
              child: const Text("Calculate"),
            ),
          ],
        );
      },
    );
  }

  void _calculatePlates(double targetWeight) {
    if (targetWeight <= 20) return;
    double weightPerSide = (targetWeight - 20) / 2;
    List<double> plates = [25, 20, 15, 10, 5, 2.5, 1.25];
    Map<double, int> result = {};

    for (double plate in plates) {
      while (weightPerSide >= plate) {
        result[plate] = (result[plate] ?? 0) + 1;
        weightPerSide -= plate;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text(
          "${targetWeight}kg Setup",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: result.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "${e.value}x",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${e.key} kg",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    for (var ex in _activeExercises) {
      for (var s in ex.sets) {
        s.kgController.dispose();
        s.repsController.dispose();
      }
    }
    super.dispose();
  }

  void _addSet(int index) =>
      setState(() => _activeExercises[index].sets.add(ActiveSet()));

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          "Finish Workout?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Sets will be saved.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Finish",
              style: TextStyle(color: Colors.blueAccent),
            ),
            onPressed: () {
              Navigator.pop(context);
              _saveWorkoutToHistory();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkoutToHistory() async {
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final workoutData = {
      "routineTitle": widget.routineTitle,
      "durationSeconds": _secondsElapsed,
      "timestamp": FieldValue.serverTimestamp(),
      "exercises": _activeExercises.map((ex) {
        return {
          "name": ex.name,
          "id": ex.id,
          "sets": ex.sets
              .where((s) => s.isCompleted)
              .map(
                (s) => {
                  "weight": s.kgController.text,
                  "reps": s.repsController.text,
                },
              )
              .toList(),
        };
      }).toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add(workoutData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.routineTitle,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              _formatTime(_secondsElapsed),
              style: TextStyle(color: _neonYellow, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Colors.white),
            onPressed: _showPlateCalculator,
          ),
          IconButton(
            icon: Icon(
              Icons.timer_outlined,
              color: _restSecondsRemaining > 0 ? _successGreen : Colors.white,
            ),
            onPressed: _showRestTimerPicker,
          ),
          TextButton(
            onPressed: _showFinishDialog,
            child: const Text(
              "FINISH",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_restSecondsRemaining > 0)
            Container(
              width: double.infinity,
              color: _successGreen.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "RESTING: ${_formatTime(_restSecondsRemaining)}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 10),
              itemCount: _activeExercises.length,
              itemBuilder: (context, index) => _buildExerciseCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _activeExercises[index];
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white12),
          ...exercise.sets.asMap().entries.map((entry) {
            return Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    "${entry.key + 1}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(child: _buildInput(entry.value.kgController)),
                Expanded(child: _buildInput(entry.value.repsController)),
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: entry.value.isCompleted
                        ? _successGreen
                        : Colors.grey,
                  ),
                  onPressed: () => setState(
                    () => entry.value.isCompleted = !entry.value.isCompleted,
                  ),
                ),
              ],
            );
          }),
          TextButton.icon(
            onPressed: () => _addSet(index),
            icon: const Icon(Icons.add),
            label: const Text("Add Set"),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
