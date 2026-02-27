// lib/services/exercise_service.dart

class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
  });
}

class ExerciseService {
  // This simulates an API response.
  // Later, we will replace this with: http.get('https://api.api-ninjas.com/v1/exercises')
  static List<Exercise> getExercises() {
    return [
      Exercise(
        id: '1',
        name: 'Bench Press',
        bodyPart: 'Chest',
        equipment: 'Barbell',
      ),
      Exercise(
        id: '2',
        name: 'Push Up',
        bodyPart: 'Chest',
        equipment: 'Bodyweight',
      ),
      Exercise(id: '3', name: 'Squat', bodyPart: 'Legs', equipment: 'Barbell'),
      Exercise(
        id: '4',
        name: 'Leg Press',
        bodyPart: 'Legs',
        equipment: 'Machine',
      ),
      Exercise(
        id: '5',
        name: 'Deadlift',
        bodyPart: 'Back',
        equipment: 'Barbell',
      ),
      Exercise(
        id: '6',
        name: 'Pull Up',
        bodyPart: 'Back',
        equipment: 'Bodyweight',
      ),
      Exercise(
        id: '7',
        name: 'Dumbbell Curl',
        bodyPart: 'Arms',
        equipment: 'Dumbbell',
      ),
      Exercise(
        id: '8',
        name: 'Tricep Dip',
        bodyPart: 'Arms',
        equipment: 'Bodyweight',
      ),
      Exercise(
        id: '9',
        name: 'Shoulder Press',
        bodyPart: 'Shoulders',
        equipment: 'Dumbbell',
      ),
      Exercise(
        id: '10',
        name: 'Plank',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
      ),
    ];
  }
}
