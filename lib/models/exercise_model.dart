class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final String target;
  final String equipment;
  final String gifUrl;
  final List<String> instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.target,
    required this.equipment,
    required this.gifUrl,
    required this.instructions,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    String imageUrl = "";
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      String imagePath = json['images'][0];
      imageUrl =
          "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imagePath";
    }

    String derivedBodyPart = "Full Body";
    if (json['primaryMuscles'] != null &&
        (json['primaryMuscles'] as List).isNotEmpty) {
      derivedBodyPart = json['primaryMuscles'][0];
    }

    String derivedTarget = json['category'] ?? "General";
    if (json['secondaryMuscles'] != null &&
        (json['secondaryMuscles'] as List).isNotEmpty) {}

    List<String> instructionList = [];
    if (json['instructions'] != null) {
      instructionList = List<String>.from(json['instructions']);
    }

    return Exercise(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? "Unknown Exercise",
      bodyPart: derivedBodyPart,
      target: derivedTarget,
      equipment: json['equipment'] ?? "Body Weight",
      gifUrl: imageUrl,
      instructions: instructionList,
    );
  }
}
