import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';

class ExerciseApiService {
  // Free, Open Source, Static JSON file
  static const String _baseUrl =
      "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json";

  // Cache
  static List<Exercise>? _cachedExercises;

  // --- SMART MAPPING ---
  static final Map<String, List<String>> _synonyms = {
    "chest": ["chest", "pectorals", "pectoralis", "upper body"],
    "back": [
      "back",
      "lats",
      "latissimus",
      "trapezius",
      "spine",
      "upper back",
      "lower back",
    ],
    "legs": [
      "legs",
      "quadriceps",
      "hamstrings",
      "calves",
      "glutes",
      "thigh",
      "adductors",
      "abductors",
      "lower body",
    ],
    "quads": ["quadriceps", "legs", "thigh"],
    "hamstrings": ["legs", "glutes", "posterior chain"],
    "arms": ["arms", "biceps", "triceps", "forearms", "brachialis"],
    "shoulders": ["shoulders", "delts", "deltoids", "rotator cuff"],
    "abs": ["abs", "abdominals", "core", "waist"],
    "calves": ["calves", "lower legs", "soleus", "gastrocnemius"],
    "cardio": ["cardio", "cardiovascular"],
  };

  // --- THE "TIER S" RANKED LIST (Your Coach Brain) ---
  // The AI scans this list FIRST.
  static final List<Exercise> _rankedExercises = [
    // --- 1. CHEST ---
    // Compound
    _ex("c_1", "Incline Dumbbell Press", "chest", "chest compound", [
      "Best combination of stretch and clavicular recruitment",
    ]),
    _ex("c_2", "Machine Chest Press (Converging)", "chest", "chest compound", [
      "High stability allows for safe absolute failure",
    ]),
    _ex("c_3", "Flat Barbell Bench Press", "chest", "chest compound", [
      "High mechanical tension potential",
    ]),
    _ex("c_4", "Weighted Dips", "chest", "chest compound", [
      "Excellent for lower chest mass",
    ]),
    _ex("c_5", "Smith Machine Incline Press", "chest", "chest compound", [
      "Focuses purely on pushing",
    ]),
    _ex("c_6", "Deficit Push-ups (Weighted)", "chest", "chest compound", [
      "Increases range of motion",
    ]),
    // Iso: Upper
    _ex("c_7", "Low-to-High Cable Fly", "chest", "chest isolation", [
      "Matches the fan-shape of the upper fibers",
    ]),
    _ex("c_8", "Incline Dumbbell Fly", "chest", "chest isolation", [
      "Great stretch",
    ]),
    _ex("c_9", "Incline Cable Fly", "chest", "chest isolation", [
      "Constant tension",
    ]),
    _ex(
      "c_10",
      "Reverse Grip Dumbbell Front Raise",
      "chest",
      "chest isolation",
      ["Targets clavicular head"],
    ),
    // Iso: Mid/Lower
    _ex(
      "c_11",
      "Cable Crossover (Shoulder Height)",
      "chest",
      "chest isolation",
      ["Max tension at peak contraction"],
    ),
    _ex("c_12", "Pec Deck (Machine Fly)", "chest", "chest isolation", [
      "Minimizes injury risk, maximizes squeeze",
    ]),
    _ex("c_13", "Flat Dumbbell Fly", "chest", "chest isolation", [
      "Classic stretcher",
    ]),
    _ex("c_14", "High-to-Low Cable Fly", "chest", "chest isolation", [
      "Targets sternal fibers",
    ]),
    _ex("c_15", "Dumbbell Pullover", "chest", "chest isolation", [
      "Works chest when elbows are tucked",
    ]),

    // --- 2. BACK ---
    // Compound
    _ex("b_1", "Chest-Supported T-Bar Row", "back", "back compound", [
      "Pure lat output",
    ]),
    _ex("b_2", "Weighted Pull-Up", "back", "back compound", [
      "Most effective vertical pull for mass",
    ]),
    _ex("b_3", "Bent-Over Barbell Row", "back", "back compound", [
      "High systemic load",
    ]),
    _ex("b_4", "Lat Pulldown (Neutral Grip)", "back", "back compound", [
      "Better biomechanics for lats",
    ]),
    _ex("b_5", "Seated Cable Row", "back", "back compound", [
      "Excellent for mid-back thickness",
    ]),
    _ex("b_6", "Meadows Row", "back", "back compound", [
      "Unilateral row, massive stretch",
    ]),
    // Iso: Lats (Width)
    _ex("b_7", "Straight-Arm Cable Pullover", "back", "back isolation", [
      "Purest lat isolation",
    ]),
    _ex("b_8", "Single-Arm Iliac Lat Pulldown", "back", "back isolation", [
      "Pulling high-to-low across body",
    ]),
    _ex("b_9", "Single-Arm Lat Prayer", "back", "back isolation", [
      "Kneeling cable pulldown for max stretch",
    ]),
    _ex("b_10", "Machine Pullover", "back", "back isolation", [
      "Maintains tension through whole arc",
    ]),
    // Iso: Upper Back/Rear Delt
    _ex("b_11", "Face Pull", "shoulders", "back isolation", [
      "Essential for rear delts and rotator cuff",
    ]),
    _ex("b_12", "Reverse Pec Deck", "shoulders", "back isolation", [
      "High stability isolation",
    ]),
    _ex("b_13", "Cable Rear Delt Fly", "shoulders", "back isolation", [
      "Constant tension",
    ]),
    _ex(
      "b_14",
      "Chest-Supported Rear Delt Row",
      "shoulders",
      "back isolation",
      ["Elbows flared 45 degrees"],
    ),
    _ex("b_15", "Kelso Shrug", "back", "back isolation", [
      "Focuses purely on retraction",
    ]),

    // --- 3. LEGS (QUADS) ---
    // Compound
    _ex("l_1", "Hack Squat", "legs", "quads compound", [
      "King of Quads due to back support",
    ]),
    _ex("l_2", "High-Bar Back Squat", "legs", "quads compound", [
      "Classic mass builder",
    ]),
    _ex("l_3", "Bulgarian Split Squat", "legs", "quads compound", [
      "Removes spinal loading, hammers quads",
    ]),
    _ex("l_4", "Leg Press", "legs", "quads compound", ["Heavy loading safely"]),
    _ex("l_5", "Front Squat", "legs", "quads compound", [
      "Shifts bias to quads",
    ]),
    _ex("l_6", "Walking Lunges", "legs", "quads compound", [
      "Dynamic movement",
    ]),
    // Isolation
    _ex("l_7", "Leg Extension", "legs", "quads isolation", [
      "Works Rectus Femoris fully",
    ]),
    _ex("l_8", "Sissy Squat", "legs", "quads isolation", [
      "Extreme stretch under load",
    ]),
    _ex("l_9", "Single-Leg Extension", "legs", "quads isolation", [
      "Fixes imbalances",
    ]),
    _ex("l_10", "Reverse Nordic Curl", "legs", "quads isolation", [
      "Eccentric-focused stretcher",
    ]),

    // --- 4. LEGS (HAMSTRINGS & GLUTES) ---
    // Compound (Hinge)
    _ex("hg_1", "Romanian Deadlift (Barbell)", "legs", "hamstrings compound", [
      "Max mechanical tension",
    ]),
    _ex("hg_2", "Stiff-Legged Deadlift", "legs", "hamstrings compound", [
      "Start from floor",
    ]),
    _ex("hg_3", "Hip Thrust", "legs", "glutes compound", [
      "Highest activation for Glutes",
    ]),
    _ex("hg_4", "Sumo Deadlift", "legs", "glutes compound", [
      "High glute recruitment",
    ]),
    _ex("hg_5", "Glute Bridge (Weighted)", "legs", "glutes compound", [
      "High peak contraction",
    ]),
    _ex("hg_6", "Good Mornings", "legs", "hamstrings compound", [
      "Excellent hamstring stretch",
    ]),
    // Iso: Hamstrings
    _ex("hg_7", "Seated Leg Curl", "legs", "hamstrings isolation", [
      "Biomechanically superior to lying",
    ]),
    _ex("hg_8", "Lying Leg Curl", "legs", "hamstrings isolation", [
      "Classic isolation",
    ]),
    _ex("hg_9", "Nordic Hamstring Curl", "legs", "hamstrings isolation", [
      "Eccentric overload",
    ]),
    _ex("hg_10", "Standing Single-Leg Curl", "legs", "hamstrings isolation", [
      "Mind-muscle connection",
    ]),
    // Iso: Glutes
    _ex("hg_11", "Cable Glute Kickback", "legs", "glutes isolation", [
      "Targets the shelf (Glute Max)",
    ]),
    _ex(
      "hg_12",
      "45-Degree Hyperextension (Round Back)",
      "legs",
      "glutes isolation",
      ["Rounding back shifts focus to glutes"],
    ),
    _ex("hg_13", "Seated Abductor Machine", "legs", "glutes isolation", [
      "Targets Glute Medius",
    ]),
    _ex("hg_14", "Cable Pull-Through", "legs", "glutes isolation", [
      "Replicates hinge pattern",
    ]),

    // --- 5. SHOULDERS ---
    // Compound
    _ex(
      "s_1",
      "Seated Dumbbell Overhead Press",
      "shoulders",
      "shoulders compound",
      ["Stability allows heavy isolation"],
    ),
    _ex("s_2", "Standing Military Press", "shoulders", "shoulders compound", [
      "Builds total body strength",
    ]),
    _ex("s_3", "Machine Shoulder Press", "shoulders", "shoulders compound", [
      "Safest way to reach failure",
    ]),
    _ex("s_4", "Arnold Press", "shoulders", "shoulders compound", [
      "Hits all three heads",
    ]),
    _ex("s_5", "Push Press", "shoulders", "shoulders compound", [
      "Overload negative",
    ]),
    _ex("s_6", "Landmine Press", "shoulders", "shoulders compound", [
      "Shoulder friendly",
    ]),
    // Iso: Side Delt
    _ex(
      "s_7",
      "Cable Lateral Raise (Behind Back)",
      "shoulders",
      "shoulders isolation",
      ["Puts delt in stretched position"],
    ),
    _ex("s_8", "Dumbbell Lateral Raise", "shoulders", "shoulders isolation", [
      "Classic width builder",
    ]),
    _ex("s_9", "Egyptian Cable Raise", "shoulders", "shoulders isolation", [
      "Constant resistance curve",
    ]),
    _ex("s_10", "Machine Lateral Raise", "shoulders", "shoulders isolation", [
      "Prevents cheating",
    ]),
    _ex("s_11", "Upright Row (Wide Grip)", "shoulders", "shoulders isolation", [
      "Hits side delts heavily",
    ]),
    _ex("s_12", "Lu Raise", "shoulders", "shoulders isolation", [
      "Full range of motion",
    ]),
    // Iso: Front Delt
    _ex("s_13", "Cable Front Raise", "shoulders", "shoulders isolation", [
      "Constant tension",
    ]),

    // --- 6. ARMS ---
    // Triceps Compound
    _ex("t_1", "Close-Grip Bench Press", "arms", "triceps compound", [
      "Heaviest loading",
    ]),
    _ex("t_2", "Weighted Dips (Upright)", "arms", "triceps compound", [
      "Targets triceps over chest",
    ]),
    _ex("t_3", "JM Press", "arms", "triceps compound", [
      "Hybrid press/skullcrusher",
    ]),
    _ex("t_4", "Diamond Pushups", "arms", "triceps compound", [
      "Bodyweight compound",
    ]),
    // Triceps Iso (Long Head)
    _ex("t_5", "Overhead Cable Extension (Rope)", "arms", "triceps isolation", [
      "Constant tension on long head",
    ]),
    _ex("t_6", "Skull Crushers (EZ Bar)", "arms", "triceps isolation", [
      "Mass builder",
    ]),
    _ex("t_7", "French Press", "arms", "triceps isolation", ["Deep stretch"]),
    _ex("t_8", "Katana Extension", "arms", "triceps isolation", [
      "Dual cable overhead",
    ]),
    // Triceps Iso (Lateral/Medial)
    _ex("t_9", "Tricep Pushdown (Rope)", "arms", "triceps isolation", [
      "Better contraction",
    ]),
    _ex("t_10", "Tricep Pushdown (Straight Bar)", "arms", "triceps isolation", [
      "Heavier weight",
    ]),
    _ex("t_11", "Cable Kickback", "arms", "triceps isolation", [
      "Peak contraction",
    ]),

    // Biceps Compound (Back Assist)
    _ex("bi_1", "Chin-Ups (Supinated)", "arms", "biceps compound", [
      "The Squat of biceps",
    ]),
    _ex("bi_2", "Underhand Grip Pulldown", "arms", "biceps compound", [
      "Heavy loading",
    ]),
    // Biceps Iso (Stretch)
    _ex("bi_3", "Bayesian Curl (Cable)", "arms", "biceps isolation", [
      "Max stretch, high hypertrophy",
    ]),
    _ex("bi_4", "Incline Dumbbell Curl", "arms", "biceps isolation", [
      "Stretches long head",
    ]),
    _ex("bi_5", "Behind-the-Back Cable Curl", "arms", "biceps isolation", [
      "Unilateral focus",
    ]),
    // Biceps Iso (Peak)
    _ex("bi_6", "Preacher Curl (EZ Bar)", "arms", "biceps isolation", [
      "Eliminates momentum",
    ]),
    _ex("bi_7", "Spider Curl", "arms", "biceps isolation", [
      "Peak contraction focus",
    ]),
    _ex("bi_8", "Concentration Curl", "arms", "biceps isolation", [
      "Unilateral squeeze",
    ]),
    // Biceps Iso (Brachialis)
    _ex("bi_9", "Dumbbell Hammer Curl", "arms", "biceps isolation", [
      "Adds width",
    ]),
    _ex("bi_10", "Rope Hammer Curl", "arms", "biceps isolation", [
      "Constant tension",
    ]),
    _ex("bi_11", "Zottman Curl", "arms", "biceps isolation", [
      "Hits forearms and brachialis",
    ]),

    // --- 7. ABS (ABDOMINALS) ---
    // Compound (Integrated Core)
    _ex("abs_1", "Hanging Leg Raise (Toes-to-Bar)", "waist", "abs compound", [
      "Gold standard; compresses entire core",
    ]),
    _ex("abs_2", "Ab Wheel Rollout", "waist", "abs compound", [
      "Massive eccentric damage; prevents extension",
    ]),
    _ex("abs_3", "Dragon Flags", "waist", "abs compound", [
      "Extreme tension on entire core",
    ]),
    _ex("abs_4", "Weighted Decline Sit-Ups", "waist", "abs compound", [
      "Allows deep stretch",
    ]),
    _ex("abs_5", "Cable Woodchoppers", "waist", "abs compound", [
      "Rotational compound power",
    ]),
    _ex("abs_6", "L-Sit Pull-Ups", "waist", "abs compound", [
      "Back compound + isometric core",
    ]),
    // Isolation (Spinal Flexion)
    _ex("abs_7", "Kneeling Cable Crunch", "waist", "abs isolation", [
      "Top Rank; heavy progressive overload",
    ]),
    _ex("abs_8", "Weighted Swiss Ball Crunch", "waist", "abs isolation", [
      "Increases Range of Motion",
    ]),
    _ex("abs_9", "Machine Crunch", "waist", "abs isolation", [
      "High stability failure",
    ]),
    _ex("abs_10", "Reverse Crunch", "waist", "abs isolation", [
      "Targets lower abs effectively",
    ]),
    _ex("abs_11", "Garhammer Raise", "waist", "abs isolation", [
      "Eliminates hip flexors",
    ]),
    _ex("abs_12", "Rope Tuck (Seated)", "waist", "abs isolation", [
      "Seated cable crunch variation",
    ]),

    // --- 8. CALVES ---
    // Compound (Straight Leg / Gastrocnemius)
    _ex("cf_1", "Donkey Calf Raise", "calves", "calves compound", [
      "Absolute best; max stretch, no spinal load",
    ]),
    _ex("cf_2", "Leg Press Calf Raise", "calves", "calves compound", [
      "Excellent stability for massive loading",
    ]),
    _ex("cf_3", "Standing Smith Machine Raise", "calves", "calves compound", [
      "Stable alternative to free weights",
    ]),
    _ex("cf_4", "Single-Leg Dumbbell Calf Raise", "calves", "calves compound", [
      "Fixes imbalances",
    ]),
    _ex("cf_5", "Farmer’s Walk (On Toes)", "calves", "calves compound", [
      "Functional isometric torch",
    ]),
    _ex("cf_6", "Sled Push", "calves", "calves compound", [
      "Functional dynamic loading",
    ]),
    // Isolation (Bent Leg / Soleus)
    _ex("cf_7", "Seated Calf Raise (Machine)", "calves", "calves isolation", [
      "Primary mass builder for Soleus",
    ]),
    _ex("cf_8", "Seated Dumbbell Calf Raise", "calves", "calves isolation", [
      "Good for home workouts",
    ]),
    _ex("cf_9", "Tibialis Raise", "calves", "calves isolation", [
      "Trains front of shin; knee health",
    ]),
    _ex("cf_10", "Squatting Calf Raise", "calves", "calves isolation", [
      "Isolates soleus via bent knee",
    ]),
    _ex("cf_11", "Cable Toe Raise", "calves", "calves isolation", [
      "Dorsiflexion focus",
    ]),
    _ex("cf_12", "Wall Sit Heel Raise", "calves", "calves isolation", [
      "Isometric quad + soleus",
    ]),
  ];

  // Helper to make the list cleaner
  static Exercise _ex(
    String id,
    String name,
    String body,
    String target,
    List<String> instr,
  ) {
    return Exercise(
      id: "ranked_$id", // Unique prefix so we know it's our gold data
      name: name,
      bodyPart: body,
      target: target,
      equipment: name.toLowerCase().contains("dumbbell")
          ? "dumbbell"
          : name.toLowerCase().contains("cable")
          ? "cable"
          : name.toLowerCase().contains("machine")
          ? "machine"
          : name.toLowerCase().contains("bodyweight")
          ? "body weight"
          : "barbell",
      gifUrl: "", // Use placeholders or add real URLs later
      instructions: instr,
    );
  }

  /// Fetch exercises with Ranked Injection
  static Future<List<Exercise>> fetchExercises({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_cachedExercises == null) {
      await _loadAllExercises();
    }
    return _getPaginated(_cachedExercises!, limit, offset);
  }

  static Future<List<Exercise>> fetchByBodyPart(String category) async {
    if (_cachedExercises == null) await _loadAllExercises();

    final searchTerms =
        _synonyms[category.toLowerCase()] ?? [category.toLowerCase()];

    return _cachedExercises!.where((ex) {
      final body = ex.bodyPart.toLowerCase();
      final target = ex.target.toLowerCase();
      for (final term in searchTerms) {
        if (body.contains(term) || target.contains(term)) return true;
      }
      return false;
    }).toList();
  }

  static Future<List<Exercise>> searchExercises(String query) async {
    if (_cachedExercises == null) await _loadAllExercises();
    if (query.isEmpty) return _getPaginated(_cachedExercises!, 50, 0);

    return _cachedExercises!.where((ex) {
      return ex.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // --- INTERNAL LOADING LOGIC ---
  static Future<bool> _loadAllExercises() async {
    List<Exercise> fetchedList = [];
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        fetchedList = data.map((json) => Exercise.fromJson(json)).toList();
      }
    } catch (e) {
      print("❌ Network Error (Using Local Backup): $e");
    }

    // MERGE STRATEGY:
    // 1. Put our _rankedExercises FIRST.
    // 2. Add the API exercises after.
    _cachedExercises = [..._rankedExercises, ...fetchedList];

    print("✅ Loaded ${_cachedExercises!.length} exercises (Ranked First).");
    return true;
  }

  static List<Exercise> _getPaginated(
    List<Exercise> all,
    int limit,
    int offset,
  ) {
    if (offset >= all.length) return [];
    int end = offset + limit;
    if (end > all.length) end = all.length;
    return all.sublist(offset, end);
  }
}
