import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fitcoach_/services/workout_manager.dart';

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
  final _supabase = Supabase.instance.client;
  bool _isSaving = false;
  final bool _isMetric = true;

  Timer? _restTimer;
  int _restSecondsRemaining = 0;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white12 : Colors.black12;

  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _successGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!WorkoutManager.instance.isWorkoutActive.value) {
        WorkoutManager.instance.startWorkout(
          widget.routineTitle,
          widget.exercises,
        );
      }
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_restSecondsRemaining > 0) {
            _restSecondsRemaining--;
          } else {
            _restTimer?.cancel();
          }
        });
      }
    });
  }

  int _calculateVolume() {
    int volume = 0;
    for (var ex in WorkoutManager.instance.activeExercises) {
      for (var set in ex.sets) {
        if (set.isCompleted) {
          int weight = int.tryParse(set.weightController.text) ?? 0;
          int reps = int.tryParse(set.repsController.text) ?? 0;
          volume += (weight * reps);
        }
      }
    }
    return volume;
  }

  int _calculateSets() {
    int completedSets = 0;
    for (var ex in WorkoutManager.instance.activeExercises) {
      for (var set in ex.sets) {
        if (set.isCompleted) completedSets++;
      }
    }
    return completedSets;
  }

  Future<void> _saveWorkoutToHistory() async {
    setState(() => _isSaving = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final List<Map<String, dynamic>> exercisesData = WorkoutManager
        .instance
        .activeExercises
        .map((ex) {
          return {
            "name": ex.name,
            "id": ex.id,
            "sets": ex.sets
                .where((s) => s.isCompleted)
                .map(
                  (s) => {
                    "weight": s.weightController.text,
                    "reps": s.repsController.text,
                  },
                )
                .toList(),
          };
        })
        .toList();

    try {
      await _supabase.from('workout_history').insert({
        'user_id': user.id,
        'routine_title': WorkoutManager.instance.routineTitle,
        'duration_seconds': WorkoutManager.instance.secondsElapsed.value,
        'unit': _isMetric ? "kg" : "lb",
        'exercises': exercisesData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final logResponse = await _supabase
          .from('daily_logs')
          .select('id')
          .eq('user_id', user.id)
          .eq('log_date', todayKey)
          .limit(1);

      if (logResponse.isNotEmpty) {
        await _supabase
            .from('daily_logs')
            .update({
              'workout_done': true,
              'workout_name': WorkoutManager.instance.routineTitle,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', logResponse.first['id']);
      } else {
        await _supabase.from('daily_logs').insert({
          'user_id': user.id,
          'log_date': todayKey,
          'workout_done': true,
          'workout_name': WorkoutManager.instance.routineTitle,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      final userResponse = await _supabase
          .from('users')
          .select('total_workouts')
          .eq('id', user.id)
          .maybeSingle();

      int currentWorkouts =
          (userResponse?['total_workouts'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('users')
          .update({'total_workouts': currentWorkouts + 1})
          .eq('id', user.id);

      WorkoutManager.instance.finishWorkout();

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            WorkoutManager.instance.isMinimized.value = true;
            Navigator.pop(context);
          },
        ),
        title: ValueListenableBuilder<int>(
          valueListenable: WorkoutManager.instance.secondsElapsed,
          builder: (context, seconds, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Log Workout",
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  WorkoutManager.instance.formatTime(seconds),
                  style: TextStyle(
                    color: _neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.timer_outlined,
              color: _restSecondsRemaining > 0 ? _successGreen : _textWhite,
            ),
            onPressed: _showRestTimerPicker,
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(
                    right: 15,
                    top: 10,
                    bottom: 10,
                  ),
                  child: ElevatedButton(
                    onPressed: _showFinishDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neonBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      "Finish",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: WorkoutManager.instance.secondsElapsed,
                  builder: (context, seconds, child) {
                    return _buildStatHeader(
                      "Duration",
                      WorkoutManager.instance.formatTime(seconds),
                      isBlue: true,
                    );
                  },
                ),
                _buildStatHeader(
                  "Volume",
                  "${_calculateVolume()} ${_isMetric ? 'kg' : 'lb'}",
                ),
                _buildStatHeader("Sets", "${_calculateSets()}"),
              ],
            ),
          ),
          Divider(color: _dividerColor, height: 1),
          if (_restSecondsRemaining > 0) _buildRestBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 10),
              itemCount: WorkoutManager.instance.activeExercises.length,
              itemBuilder: (context, index) => _buildExerciseCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatHeader(String label, String value, {bool isBlue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isBlue ? _neonBlue : _textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = WorkoutManager.instance.activeExercises[index];
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _dividerColor),
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
          Divider(color: _dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 30),
                Expanded(
                  child: Center(
                    child: Text(
                      _isMetric ? "WEIGHT (KG)" : "WEIGHT (LB)",
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "REPS",
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((entry) {
            return Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    "${entry.key + 1}",
                    style: TextStyle(
                      color: _textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: _buildInput(entry.value.weightController, "-")),
                Expanded(child: _buildInput(entry.value.repsController, "-")),
                IconButton(
                  icon: Icon(
                    entry.value.isCompleted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: entry.value.isCompleted
                        ? _successGreen
                        : _textGrey.withOpacity(0.5),
                  ),
                  onPressed: () => setState(
                    () => entry.value.isCompleted = !entry.value.isCompleted,
                  ),
                ),
              ],
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => exercise.sets.add(ActiveSet())),
            icon: Icon(Icons.add, color: _textWhite, size: 18),
            label: Text(
              "Add Set",
              style: TextStyle(color: _textWhite, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        onChanged: (val) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildRestBanner() {
    return Container(
      width: double.infinity,
      color: _successGreen.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "RESTING: ${WorkoutManager.instance.formatTime(_restSecondsRemaining)}",
        textAlign: TextAlign.center,
        style: TextStyle(color: _successGreen, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showRestTimerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Set Rest Timer",
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text("Finish Workout?", style: TextStyle(color: _textWhite)),
        content: Text(
          "All completed sets will be saved to your history.",
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: _textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveWorkoutToHistory();
            },
            child: Text(
              "Finish",
              style: TextStyle(color: _neonBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
