import 'package:fitcoach_/screens/workout/active_workout_screen.dart';
import 'package:fitcoach_/screens/workout/exercise_list_screen.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;
  final String routineTitle;
  final Map<String, dynamic> routineData;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
    required this.routineTitle,
    required this.routineData,
  });

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  bool _isEditing = false;
  late List<dynamic> _exercises;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final Color blueAccent = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _exercises = List<dynamic>.from(widget.routineData['exercises'] ?? []);
  }

  void _toggleEdit() async {
    if (_isEditing) {
      try {
        await Supabase.instance.client
            .from('routines')
            .update({'exercises': _exercises})
            .eq('id', widget.routineId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Routine updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error updating routine: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save changes: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _showAddEditDialog({int? index}) {
    final isEditingExisting = index != null;
    final nameController = TextEditingController(
      text: isEditingExisting ? _exercises[index]['name'] : '',
    );
    final setsLength = isEditingExisting
        ? (_exercises[index]['sets']?.length ?? 3)
        : 3;
    final setsController = TextEditingController(text: setsLength.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEditingExisting ? "Edit Exercise" : "Add Custom Exercise",
            style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: _textWhite),
                decoration: InputDecoration(
                  labelText: "Exercise Name",
                  labelStyle: TextStyle(color: _textGrey),
                  filled: true,
                  fillColor: isDark ? Colors.black : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: isDark
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _textWhite),
                decoration: InputDecoration(
                  labelText: "Number of Sets",
                  labelStyle: TextStyle(color: _textGrey),
                  filled: true,
                  fillColor: isDark ? Colors.black : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: isDark
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final numSets = int.tryParse(setsController.text) ?? 3;
                final newSetsList = List.generate(
                  numSets,
                  (i) => {"weight": "", "reps": "10"},
                );

                setState(() {
                  if (isEditingExisting) {
                    _exercises[index] = {
                      ..._exercises[index],
                      'name': nameController.text,
                      'sets': newSetsList,
                    };
                  } else {
                    _exercises.add({
                      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameController.text,
                      'sets': newSetsList,
                    });
                  }
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        iconTheme: IconThemeData(color: _textWhite),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check_circle : Icons.edit,
              color: _isEditing ? _neonYellow : _textWhite,
            ),
            onPressed: _toggleEdit,
          ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.more_vert, color: _textWhite),
              onPressed: () {
                // TODO: Show Delete Option
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 50,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 15),
                Text(
                  widget.routineTitle,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  "${_exercises.length} Exercises",
                  style: TextStyle(
                    color: _isEditing ? _neonYellow : _textGrey,
                    fontSize: 16,
                    fontWeight: _isEditing
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Theme(
              data: ThemeData(
                canvasColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return Container(
                    key: ValueKey(ex['name'].toString() + index.toString()),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: _isEditing
                          ? Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            )
                          : Border.all(
                              color: isDark
                                  ? Colors.transparent
                                  : Colors.black12,
                            ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      leading: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: isDark ? Colors.white54 : Colors.black54,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        ex['name'] ?? "Unknown",
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${ex['sets']?.length ?? 0} Sets",
                        style: TextStyle(color: _textGrey, fontSize: 13),
                      ),
                      trailing: _isEditing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: _textGrey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showAddEditDialog(index: index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteExercise(index),
                                ),
                                Icon(Icons.drag_handle, color: _textGrey),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: Icon(Icons.edit_note, color: _textWhite),
                          label: Text(
                            "Custom",
                            style: TextStyle(color: _textWhite, fontSize: 14),
                          ),
                          onPressed: () => _showAddEditDialog(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _neonYellow,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.search, color: Colors.black),
                          label: const Text(
                            "Browse Database",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final List<Exercise>? selectedExercises =
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ExerciseListScreen(),
                                  ),
                                );

                            if (selectedExercises != null &&
                                selectedExercises.isNotEmpty) {
                              setState(() {
                                for (var exercise in selectedExercises) {
                                  _exercises.add({
                                    'id': exercise.id,
                                    'name': exercise.name,
                                    'sets': List.generate(
                                      3,
                                      (i) => {"weight": "", "reps": "10"},
                                    ),
                                  });
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveWorkoutScreen(
                              routineTitle: widget.routineTitle,
                              exercises: _exercises
                                  .cast<Map<String, dynamic>>(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Start Workout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
}
