import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/workout/active_workout_screen.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

class ActiveSet {
  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted;

  ActiveSet({String weight = "", String reps = "", this.isCompleted = false})
    : weightController = TextEditingController(text: weight),
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

class WorkoutManager {
  static final WorkoutManager instance = WorkoutManager._internal();
  WorkoutManager._internal();

  final ValueNotifier<bool> isWorkoutActive = ValueNotifier(false);
  final ValueNotifier<bool> isMinimized = ValueNotifier(false);
  final ValueNotifier<int> secondsElapsed = ValueNotifier(0);

  String routineTitle = "";
  List<ActiveExercise> activeExercises = [];
  Timer? _workoutTimer;

  void startWorkout(String title, List<dynamic> rawExercises) {
    if (isWorkoutActive.value) return;

    routineTitle = title;
    activeExercises = rawExercises.map((ex) {
      List<dynamic> rawSets = ex['sets'] ?? [];
      if (rawSets.isEmpty)
        rawSets = [
          {'weight': '', 'reps': ''},
        ];
      return ActiveExercise(
        name: ex['name'] ?? "Unknown",
        id: ex['id']?.toString() ?? "unknown_id",
        sets: rawSets
            .map(
              (s) => ActiveSet(
                weight: s['weight']?.toString() ?? "",
                reps: s['reps']?.toString() ?? "",
              ),
            )
            .toList(),
      );
    }).toList();

    secondsElapsed.value = 0;
    isWorkoutActive.value = true;
    isMinimized.value = false;
    _workoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => secondsElapsed.value++,
    );
  }

  void finishWorkout() {
    _workoutTimer?.cancel();
    isWorkoutActive.value = false;
    isMinimized.value = false;
    activeExercises.clear();
  }

  String formatTime(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return h > 0
        ? "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}"
        : "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WorkoutManager.instance.isWorkoutActive,
      builder: (context, isActive, child) {
        if (!isActive) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: WorkoutManager.instance.isMinimized,
          builder: (context, isMinimized, child) {
            if (!isMinimized) return const SizedBox.shrink();

            return Positioned(
              bottom: 25,
              left: 15,
              right: 15,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFF2F80ED),
                child: InkWell(
                  onTap: () {
                    WorkoutManager.instance.isMinimized.value = false;
                    globalNavigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (_) => ActiveWorkoutScreen(
                          routineTitle: WorkoutManager.instance.routineTitle,
                          exercises: const [],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                WorkoutManager.instance.routineTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable:
                                    WorkoutManager.instance.secondsElapsed,
                                builder: (context, s, c) => Text(
                                  WorkoutManager.instance.formatTime(s),
                                  style: const TextStyle(
                                    color: Color(0xFFD0FD3E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
