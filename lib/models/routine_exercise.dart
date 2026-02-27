class WorkoutSet {
  String weight;
  String reps;
  bool isCompleted;

  WorkoutSet({this.weight = "", this.reps = "", this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {'weight': weight, 'reps': reps, 'isCompleted': isCompleted};
  }
}

class RoutineExercise {
  final String id;
  final String name;
  final String bodyPart;
  List<WorkoutSet> sets;
  String? supersetId; // For linking exercises together

  RoutineExercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    List<WorkoutSet>? sets,
    this.supersetId,
  }) : sets = sets ?? [WorkoutSet()]; // Default to 1 empty set

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'supersetId': supersetId,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }
}
