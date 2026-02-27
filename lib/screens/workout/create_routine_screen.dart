import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:fitcoach_/models/routine_exercise.dart'; // Import the model above
import 'package:fitcoach_/screens/workout/exercise_list_screen.dart';
import 'package:flutter/material.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController _titleController = TextEditingController();
  final List<RoutineExercise> _addedExercises = []; // Stores RoutineExercises
  bool _isSaving = false;

  // Colors
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _blueAccent = Colors.blueAccent;
  final Color _supersetPurple = const Color(0xFFBB86FC);

  // --- FIX: THE MISSING LOGIC ---
  void _openExerciseList() async {
    // 1. Wait for the list screen to return data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseListScreen()),
    );

    // 2. Check if we got data back
    if (result != null && result is List<Exercise>) {
      setState(() {
        // 3. CONVERT 'Exercise' -> 'RoutineExercise'
        for (var ex in result) {
          // Check if already added to avoid duplicates if desired
          if (!_addedExercises.any((e) => e.id == ex.id)) {
            _addedExercises.add(
              RoutineExercise(
                id: ex.id,
                name: ex.name,
                bodyPart: ex.bodyPart,
                sets: [WorkoutSet()], // Start with 1 empty set
              ),
            );
          }
        }
      });
    }
  }

  void _saveRoutine() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a routine name")),
      );
      return;
    }
    if (_addedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one exercise")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final routineData = {
        'title': _titleController.text,
        'exercises': _addedExercises.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('routines')
          .add(routineData);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isSaving = false);
    }
  }

  // Helper to add a set to a specific exercise
  void _addSet(int index) {
    setState(() {
      _addedExercises[index].sets.add(WorkoutSet());
    });
  }

  // Helper to remove an exercise
  void _removeExercise(int index) {
    setState(() {
      _addedExercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Routine",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : TextButton(
                  onPressed: _saveRoutine,
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Routine Title Input
          Container(
            padding: const EdgeInsets.all(20),
            color: _cardDark,
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Routine Title (e.g., Chest Day)",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Exercise List
          Expanded(
            child: _addedExercises.isEmpty
                ? const Center(
                    child: Text(
                      "No exercises added yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _addedExercises.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(index);
                    },
                  ),
          ),

          // "Add Exercise" Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _openExerciseList, // Calls the fixed function
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Add exercise",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _addedExercises[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _removeExercise(index),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Header Row
          Row(
            children: const [
              SizedBox(
                width: 30,
                child: Text(
                  "SET",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "KG",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "REPS",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Sets List
          ...exercise.sets.asMap().entries.map((entry) {
            int setIndex = entry.key;
            WorkoutSet set = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      "${setIndex + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "-",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (val) => set.weight = val,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "-",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (val) => set.reps = val,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Add Set Button
          Center(
            child: TextButton(
              onPressed: () => _addSet(index),
              child: const Text(
                "+ Add Set",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
