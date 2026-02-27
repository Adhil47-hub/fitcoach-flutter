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
    // 1. IMAGE HANDLING
    // The API gives a path like "exercises/0/0.jpg". We add the base GitHub URL.
    String imageUrl = "";
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      String imagePath = json['images'][0]; // e.g. "0/0.jpg"
      imageUrl = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imagePath";
    }

    // 2. BODY PART HANDLING
    // New DB uses "primaryMuscles" (List) instead of "bodyPart" (String)
    String derivedBodyPart = "Full Body";
    if (json['primaryMuscles'] != null && (json['primaryMuscles'] as List).isNotEmpty) {
      derivedBodyPart = json['primaryMuscles'][0];
    }

    // 3. TARGET HANDLING
    // We use the category (e.g., strength) as the target if specific target is missing
    String derivedTarget = json['category'] ?? "General";
    if (json['secondaryMuscles'] != null && (json['secondaryMuscles'] as List).isNotEmpty) {
       // Optional: Use secondary muscles as subtitle details if preferred
       // derivedTarget = json['secondaryMuscles'][0];
    }

    // 4. INSTRUCTIONS HANDLING
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