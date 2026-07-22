import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiRecommendationService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<List<Map<String, dynamic>>> getDynamicRecommendations({
    required String userName,
    required String goal,
    required int currentSteps,
    required int stepGoal,
    required double currentWater,
    required double waterGoal,
    required double currentSleep,
    required double sleepGoal,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      final prompt =
          '''
      You are an elite AI fitness coach. Analyze this user's daily progress and generate exactly 5 personalized, highly actionable recommendations for today.
      
      User Data:
      Name: $userName
      Goal: $goal
      Steps: $currentSteps / $stepGoal
      Water: $currentWater L / $waterGoal L
      Sleep last night: $currentSleep / $sleepGoal hours

      Instructions:
      1. Create 2 or 3 recommendations based STRICTLY on their daily stats.
      2. Create 2 or 3 GENERAL, high-value fitness, nutrition, or mindset tips that will help them achieve their main goal ($goal).
      
      Return ONLY a raw JSON array of exactly 5 objects. Do not use markdown blocks. 
      Use this exact structure:
      [
        {
          "title": "Short catchy title",
          "tag": "Short category",
          "metric": "Short metric text",
          "category": "Choose one exact word: water, sleep, workout, nutrition, or general",
          "description": "A detailed 4-5 sentence breakdown and personalized, motivating advice."
        }
      ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      String responseText = response.text ?? '[]';

      int startIndex = responseText.indexOf('[');
      int endIndex = responseText.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1) {
        responseText = responseText.substring(startIndex, endIndex + 1);
      }

      final List<dynamic> jsonList = jsonDecode(responseText);

      return jsonList.map((item) {
        final Map<String, dynamic> visuals = _getVisualsForCategory(
          item['category'] ?? 'general',
        );

        return {
          "title": item['title'] ?? "AI Suggestion",
          "tag": item['tag'] ?? "TIP",
          "metric": item['metric'] ?? "",
          "icon": visuals['icon'],
          "color": visuals['color'],
          "imageUrl": visuals['image'],
          "description":
              item['description'] ?? "Keep pushing towards your goals!",
        };
      }).toList();
    } catch (e) {
      debugPrint("AI Recommendation Error: $e");
      return getFallbackRecommendations();
    }
  }

  static Map<String, dynamic> _getVisualsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'water':
        return {
          'icon': Icons.water_drop,
          'color': Colors.blueAccent,
          'image':
              'https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=1470&auto=format&fit=crop',
        };
      case 'sleep':
      case 'recovery':
        return {
          'icon': Icons.bedtime,
          'color': const Color(0xFFBB86FC),
          'image':
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1520&auto=format&fit=crop',
        };
      case 'workout':
      case 'activity':
        return {
          'icon': Icons.fitness_center,
          'color': const Color(0xFFD0FD3E),
          'image':
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
        };
      case 'nutrition':
      case 'food':
        return {
          'icon': Icons.restaurant_menu,
          'color': Colors.redAccent,
          'image':
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1470&auto=format&fit=crop',
        };
      default:
        return {
          'icon': Icons.lightbulb_outline,
          'color': const Color(0xFF00A86B),
          'image':
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1470&auto=format&fit=crop',
        };
    }
  }

  static List<Map<String, dynamic>> getFallbackRecommendations() {
    return [
      {
        "title": "Hydration Check",
        "tag": "DAILY GOAL",
        "metric": "Stay hydrated",
        "icon": Icons.water_drop,
        "color": Colors.blueAccent,
        "imageUrl":
            "https://images.unsplash.com/photo-1523362628745-0c100150b504?q=80&w=1470&auto=format&fit=crop",
        "description":
            "You need water to fuel muscle recovery. Log your water now. Staying hydrated ensures nutrients are delivered to your muscles efficiently and helps lubricate your joints for better performance.",
      },
      {
        "title": "Protein Power",
        "tag": "NUTRITION",
        "metric": "Diet Tip",
        "icon": Icons.restaurant_menu,
        "color": Colors.redAccent,
        "imageUrl":
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1470&auto=format&fit=crop",
        "description":
            "Try to include at least 20g of protein in your next meal to keep you full and preserve muscle mass. Eating lean meats, dairy, or plant-based alternatives will help you hit your daily goals effortlessly.",
      },
      {
        "title": "Hit Your Steps",
        "tag": "ACTIVITY",
        "metric": "Get moving",
        "icon": Icons.directions_walk,
        "color": const Color(0xFFD0FD3E),
        "imageUrl":
            "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
        "description":
            "You are slightly behind on your step goal today. A quick 15-minute brisk walk will easily catch you up! Walking aids in digestion, lowers stress levels, and burns extra calories without taxing your nervous system.",
      },
      {
        "title": "The 80/20 Rule",
        "tag": "MINDSET",
        "metric": "Focus",
        "icon": Icons.lightbulb_outline,
        "color": const Color(0xFF00A86B),
        "imageUrl":
            "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1470&auto=format&fit=crop",
        "description":
            "Consistency beats perfection. If you stick to your plan 80% of the time, you will see massive results. Do not let one bad meal or missed workout ruin your entire week; just get back on track tomorrow.",
      },
      {
        "title": "Evening Stretch",
        "tag": "RECOVERY",
        "metric": "10 Mins",
        "icon": Icons.bedtime,
        "color": const Color(0xFFBB86FC),
        "imageUrl":
            "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1520&auto=format&fit=crop",
        "description":
            "Loosen up your muscles before bed to improve your deep sleep cycles and reduce cortisol levels. A short 10-minute routine focusing on your hamstrings, hips, and lower back can prevent tomorrow's soreness.",
      },
    ];
  }
}
