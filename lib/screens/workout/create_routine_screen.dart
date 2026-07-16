import 'package:fitcoach_/models/exercise_model.dart';
import 'package:fitcoach_/models/routine_exercise.dart';
import 'package:fitcoach_/screens/workout/exercise_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final List<RoutineExercise> _addedExercises = [];
  bool _isSaving = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _inputBg => isDark ? Colors.black : Colors.grey.shade200;

  final Color _blueAccent = Colors.blueAccent;

  void _openExerciseList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseListScreen()),
    );

    if (result != null && result is List<Exercise>) {
      setState(() {
        for (var ex in result) {
          if (!_addedExercises.any((e) => e.id == ex.id)) {
            _addedExercises.add(
              RoutineExercise(
                id: ex.id,
                name: ex.name,
                bodyPart: ex.bodyPart,
                sets: [WorkoutSet()],
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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final routineData = {
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'exercises': _addedExercises.map((e) => e.toMap()).toList(),
        'day': 'Unscheduled',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _supabase.from('routines').insert(routineData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Routine Saved!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSaving = false);
      }
    }
  }

  void _addSet(int index) {
    setState(() {
      _addedExercises[index].sets.add(WorkoutSet());
    });
  }

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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Routine",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: CircularProgressIndicator(
                      color: _blueAccent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveRoutine,
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: _blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: _cardDark,
            child: TextField(
              controller: _titleController,
              style: TextStyle(
                color: _textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Routine Title (e.g., Chest Day)",
                hintStyle: TextStyle(color: _textGrey),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _addedExercises.isEmpty
                ? Center(
                    child: Text(
                      "No exercises added yet",
                      style: TextStyle(color: _textGrey),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _openExerciseList,
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
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
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
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _removeExercise(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  "SET",
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "KG",
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "REPS",
                    style: TextStyle(color: _textGrey, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
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
                      style: TextStyle(
                        color: _textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        style: TextStyle(color: _textWhite),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
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
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        style: TextStyle(color: _textWhite),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
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
          Center(
            child: TextButton.icon(
              onPressed: () => _addSet(index),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Set"),
              style: TextButton.styleFrom(foregroundColor: _blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
