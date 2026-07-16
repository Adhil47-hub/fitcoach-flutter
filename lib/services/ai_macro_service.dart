import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiMacroService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> generateAndSaveMacros({
    required double currentWeightKg,
    double? previousWeightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String primaryGoal,
    required String activityLevel,
  }) async {
    try {
      final apiKey = 'AIzaSyACHwc1yYdZ5QYviaOsquCDTaaC0Kgs40c';
      if (apiKey.isEmpty) throw Exception("API Key is missing!");

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      String weightContext = previousWeightKg != null
          ? "Two weeks ago they weighed $previousWeightKg kg. Today they weigh $currentWeightKg kg."
          : "They currently weigh $currentWeightKg kg. This is their baseline starting point.";

      final prompt =
          '''
        You are an elite, clinical AI sports nutritionist.
        
        Client Profile:
        - Age: $age
        - Gender: $gender
        - Height: $heightCm cm
        - Goal: $primaryGoal
        - Activity Level: $activityLevel
        - Weight Context: $weightContext

        Task 1: Calculate their precise Total Daily Energy Expenditure (TDEE).
        Task 2: Adjust their calories based on their exact Goal and their Weight Context. 
        Task 3: Calculate the optimal macronutrient split (Protein, Carbs, Fats in grams).
        Task 4: Write a 2-sentence 'coach_rationale' directly to the user (using "you/your").

        CRITICAL: Return ONLY a raw JSON object. No markdown.
        Format:
        {
          "calories": 2500,
          "protein": 160,
          "carbs": 250,
          "fat": 70,
          "coach_rationale": "Rationale text here..."
        }
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) throw Exception("AI returned empty response.");

      final String text = response.text!;
      final int startIndex = text.indexOf('{');
      final int endIndex = text.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1)
        throw Exception("Invalid JSON structure.");

      final String cleanJson = text.substring(startIndex, endIndex + 1);
      final Map<String, dynamic> macroData = jsonDecode(cleanJson);

      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('goals').upsert({
          'user_id': user.id,
          'calories': macroData['calories'],
          'protein': macroData['protein'],
          'carbs': macroData['carbs'],
          'fat': macroData['fat'],
          'coach_rationale': macroData['coach_rationale'],
          'last_updated': DateTime.now().toIso8601String(),
          'logged_weight': currentWeightKg,
        });

        await _supabase.from('goals').upsert({
          'user_id': user.id,
          'calories_goal': macroData['calories'],
        });
      }

      return macroData;
    } catch (e) {
      print("🚨 AI Macro Generation Error: $e");
      return null;
    }
  }
}
