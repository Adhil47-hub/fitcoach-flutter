import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fitcoach_/screens/nutrition/food_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoodItem {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final bool isAiGenerated;
  final double standardServingWeight;
  final String standardServingUnit;

  FoodItem({
    this.id = '',
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    this.isAiGenerated = false,
    this.standardServingWeight = 100.0,
    this.standardServingUnit = "serving",
  });
}

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

  List<FoodItem> _aiResults = [];
  List<FoodItem> _dbResults = [];
  bool _isSearchingAi = false;
  bool _isSearchingDb = false;

  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white10 : Colors.black12;

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

  void _searchFood(String query) {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _aiResults = [];
      _dbResults = [];
      _isSearchingAi = true;
      _isSearchingDb = true;
    });

    _fetchAiResult(query);
    _fetchDatabaseResults(query);
  }

  Future<void> _fetchAiResult(String query) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      final prompt =
          '''
        Act as a highly accurate nutrition database.
        Identify 3 to 5 common variations of "$query" (e.g., Raw, Cooked, Brand name).
        Return ONLY a raw JSON ARRAY. No conversational text.
        Macros (calories, protein, carbs, fat) MUST be strictly based on 100 grams of the food.
        Crucially, also provide a realistic standard serving unit (e.g., "egg", "slice", "cup", "piece") and its exact weight in grams.
        [
          { 
            "name": "Hard Boiled Egg", 
            "calories": 155, 
            "protein": 12.6, 
            "carbs": 1.1, 
            "fat": 10.6,
            "serving_weight": 50, 
            "serving_unit": "egg" 
          }
        ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null && mounted) {
        final String text = response.text!;
        final int startIndex = text.indexOf('[');
        final int endIndex = text.lastIndexOf(']');

        if (startIndex != -1 && endIndex != -1) {
          final String cleanJson = text.substring(startIndex, endIndex + 1);
          List<dynamic> dataList = jsonDecode(cleanJson);

          final List<FoodItem> parsedItems = dataList.map<FoodItem>((data) {
            return FoodItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: data['name'] ?? "Unknown",
              calories: (data['calories'] as num).toDouble(),
              protein: (data['protein'] as num).toDouble(),
              carbs: (data['carbs'] as num).toDouble(),
              fat: (data['fat'] as num).toDouble(),
              standardServingWeight:
                  (data['serving_weight'] as num?)?.toDouble() ?? 100.0,
              standardServingUnit: data['serving_unit'] ?? "g",
              isAiGenerated: true,
            );
          }).toList();

          setState(() {
            _aiResults = parsedItems;
            _isSearchingAi = false;
          });
        }
      }
    } catch (e) {
      debugPrint("AI Search Error: $e");
      if (mounted) setState(() => _isSearchingAi = false);
    }
  }

  Future<void> _fetchDatabaseResults(String query) async {
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

      if (result.products != null && mounted) {
        final List<FoodItem> parsedDbItems = result.products!
            .map<FoodItem>((p) {
              return FoodItem(
                id:
                    p.barcode ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
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
                standardServingWeight: p.servingQuantity ?? 100.0,
                standardServingUnit: "g",
                isAiGenerated: false,
              );
            })
            .where((item) => item.calories > 0 && item.name != "Unknown")
            .toList();

        setState(() {
          _dbResults = parsedDbItems;
          _isSearchingDb = false;
        });
      }
    } catch (e) {
      debugPrint("DB Search Error: $e");
      if (mounted) setState(() => _isSearchingDb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        iconTheme: IconThemeData(color: _textWhite),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: _textWhite),
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search food...",
            hintStyle: TextStyle(color: _textGrey),
            border: InputBorder.none,
          ),
          onSubmitted: _searchFood,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: _textWhite),
            onPressed: () => _searchFood(_searchController.text),
          ),
        ],
      ),
      body:
          _aiResults.isEmpty &&
              _dbResults.isEmpty &&
              !_isSearchingAi &&
              !_isSearchingDb
          ? Center(
              child: Text(
                "Search for any food.",
                style: TextStyle(color: _textGrey),
              ),
            )
          : CustomScrollView(
              slivers: [
                if (_isSearchingAi || _aiResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 20,
                        bottom: 10,
                      ),
                      child: Text(
                        "AI Estimates",
                        style: TextStyle(
                          color: _aiPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_isSearchingAi)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: _aiPurple),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildFoodCard(_aiResults[index], isTopPick: true),
                    childCount: _aiResults.length,
                  ),
                ),
                if (_isSearchingDb || _dbResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 30,
                        bottom: 10,
                      ),
                      child: Text(
                        "Database Verified",
                        style: TextStyle(
                          color: _textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_isSearchingDb)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.grey),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildFoodCard(_dbResults[index], isTopPick: false),
                    childCount: _dbResults.length,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFoodCard(FoodItem item, {required bool isTopPick}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTopPick ? _aiPurple.withOpacity(0.3) : _dividerColor,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.fastfood, color: _textGrey),
                ),
              )
            : Icon(
                isTopPick ? Icons.auto_awesome : Icons.local_dining,
                color: isTopPick ? _aiPurple : _textGrey,
              ),
        title: Text(
          item.name,
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${item.calories.toInt()} kcal • ${item.protein.toInt()}p • ${item.carbs.toInt()}c • ${item.fat.toInt()}f",
          style: TextStyle(color: _textGrey, fontSize: 13),
        ),
        trailing: Icon(Icons.add_circle_outline, color: _textWhite),
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
  }
}
