import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/nutrition/food_detail_screen.dart'; // Import the detail screen
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

// --- HELPER CLASS ---
class FoodItem {
  final String name;
  final double calories; // Per 100g
  final double protein; // Per 100g
  final double carbs; // Per 100g
  final double fat; // Per 100g
  final String? imageUrl;
  final bool isAiGenerated;

  // ✅ NEW: Dynamic Serving Data
  final double standardServingWeight; // e.g., 182.0 (grams)
  final String standardServingUnit; // e.g., "medium" or "slice"

  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.isAiGenerated = false,
    this.standardServingWeight = 100.0, // Default if unknown
    this.standardServingUnit = "serving",
  });
}

// --- SSL FIX ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;

  // ✅ YOUR WORKING KEY
  final String _apiKey = 'AIzaSyCXF7tJQT9wjqXMhg2o1ZzONDP4ZxhjblA';

  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _aiPurple = const Color(0xFFBB86FC);

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = MyHttpOverrides();
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'FitCoach',
      url: 'https://fitcoach.app',
    );
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await Future.wait([
        _fetchAiResult(query),
        _fetchDatabaseResults(query),
      ]);

      List<FoodItem> combinedList = [];

      if (results[0] != null) combinedList.addAll(results[0] as List<FoodItem>);
      if (results[1] != null) combinedList.addAll(results[1] as List<FoodItem>);

      if (mounted) {
        setState(() => _searchResults = combinedList);
        if (combinedList.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No results found.")));
        }
      }
    } catch (e) {
      print("Global Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- TASK 1: AI SEARCH (Now asks for Serving Size) ---
  Future<List<FoodItem>> _fetchAiResult(String query) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      // ✅ Updated Prompt to ask for specific weights
      final prompt =
          '''
        Identify 3 to 5 common variations of "$query".
        (e.g. for 'apple', return 'Fresh Apple', 'Dried Apple').
        
        For each, estimate nutrition per 100g.
        CRITICAL: Also provide the "standard_weight" in grams for 1 typical unit (e.g. 1 medium apple = 182g, 1 slice bread = 30g).
        
        Return JSON ARRAY:
        [
          { 
            "name": "...", 
            "calories": 0, "protein": 0, "carbs": 0, "fat": 0,
            "serving_weight": 100, 
            "serving_unit": "serving" 
          }
        ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        List<dynamic> dataList = jsonDecode(cleanJson);

        return dataList.map((data) {
          return FoodItem(
            name: "✨ ${data['name']}",
            calories: (data['calories'] as num).toDouble(),
            protein: (data['protein'] as num).toDouble(),
            carbs: (data['carbs'] as num).toDouble(),
            fat: (data['fat'] as num).toDouble(),
            standardServingWeight:
                (data['serving_weight'] as num?)?.toDouble() ?? 100.0,
            standardServingUnit: data['serving_unit'] ?? "serving",
            isAiGenerated: true,
          );
        }).toList();
      }
    } catch (e) {
      print("AI Search Error: $e");
    }
    return [];
  }

  // --- TASK 2: DATABASE SEARCH (Now extracts Serving Size) ---
  Future<List<FoodItem>> _fetchDatabaseResults(String query) async {
    try {
      final configuration = ProductSearchQueryConfiguration(
        parametersList: <Parameter>[
          SearchTerms(terms: [query]),
          const PageSize(size: 20),
        ],
        version: ProductQueryVersion.v3,
        language: OpenFoodFactsLanguage.ENGLISH,
      );

      final result = await OpenFoodAPIClient.searchProducts(
        null,
        configuration,
      ).timeout(const Duration(seconds: 8));

      if (result.products != null) {
        return result.products!
            .map((p) {
              return FoodItem(
                name: p.productName ?? "Unknown",
                calories:
                    p.nutriments?.getValue(
                      Nutrient.energyKCal,
                      PerSize.oneHundredGrams,
                    ) ??
                    0,
                protein:
                    p.nutriments?.getValue(
                      Nutrient.proteins,
                      PerSize.oneHundredGrams,
                    ) ??
                    0,
                carbs:
                    p.nutriments?.getValue(
                      Nutrient.carbohydrates,
                      PerSize.oneHundredGrams,
                    ) ??
                    0,
                fat:
                    p.nutriments?.getValue(
                      Nutrient.fat,
                      PerSize.oneHundredGrams,
                    ) ??
                    0,
                imageUrl: p.imageFrontUrl,
                // ✅ Extract serving quantity if available (e.g. "40g")
                standardServingWeight: p.servingQuantity ?? 100.0,
                standardServingUnit:
                    "serving", // Database items usually just say "1 serving"
                isAiGenerated: false,
              );
            })
            .where((item) => item.calories > 0)
            .toList();
      }
    } catch (e) {
      print("Database Error: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search food...",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
          onSubmitted: _searchFood,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _searchFood(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _neonBlue))
          : _searchResults.isEmpty
          ? const Center(
              child: Text(
                "Search for any food.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                bool isTopPick = item.isAiGenerated;

                return Container(
                  decoration: isTopPick
                      ? BoxDecoration(
                          color: _aiPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _aiPurple.withOpacity(0.3)),
                        )
                      : null,
                  margin: isTopPick
                      ? const EdgeInsets.only(bottom: 10)
                      : EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: isTopPick
                        ? const EdgeInsets.all(10)
                        : EdgeInsets.zero,
                    leading: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, color: Colors.grey),
                          )
                        : Icon(
                            item.isAiGenerated
                                ? Icons.auto_awesome
                                : Icons.fastfood,
                            color: item.isAiGenerated ? _aiPurple : Colors.grey,
                          ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${item.calories.toInt()} kcal • ${item.protein.toInt()}p • ${item.carbs.toInt()}c • ${item.fat.toInt()}f",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetailScreen(food: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
