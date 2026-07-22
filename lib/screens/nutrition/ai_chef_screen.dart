import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/services/ai_api_key.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiChefScreen extends StatefulWidget {
  const AiChefScreen({super.key});

  @override
  State<AiChefScreen> createState() => _AiChefScreenState();
}

class _AiChefScreenState extends State<AiChefScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _ingredientsController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _generatedRecipe;

  int _targetCalories = 2000;
  int _targetProtein = 150;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white10 : Colors.black12;

  final Color _calBlue = const Color(0xFF2F80ED);
  final Color _protPurple = const Color(0xFFBB86FC);
  final Color _fatRed = const Color(0xFFFF5252);
  final Color _carbGreen = const Color(0xFFD0FD3E);

  @override
  void initState() {
    super.initState();
    _loadUserMacros();
  }

  Future<void> _loadUserMacros() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('goals')
            .select('calories_goal, protein_goal')
            .eq('user_id', user.id)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _targetCalories =
                (response['calories_goal'] as num?)?.toInt() ?? 2000;
            _targetProtein = (response['protein_goal'] as num?)?.toInt() ?? 150;
          });
        }
      } catch (e) {
        debugPrint("Error loading macros: $e");
      }
    }
  }

  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _generatedRecipe = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: AiApiKey.value,
      );
      final prompt =
          '''
        Act as an elite sports nutritionist and master chef.
        My daily macro targets are roughly $_targetCalories calories and $_targetProtein g of protein.
        I have these ingredients: ${_ingredientsController.text}.

        Create ONE single, highly delicious recipe using some or all of these ingredients. You can assume I have basic pantry staples.
        The recipe MUST align with a high-protein fitness lifestyle.

        Return ONLY a valid JSON object formatted exactly like this. No markdown blocks.
        {
          "title": "Name of the Recipe",
          "description": "1 sentence describing the dish.",
          "calories": 450,
          "protein": 40,
          "carbs": 35,
          "fat": 15,
          "prep_time": "15 mins",
          "ingredients": ["Ingredient 1", "Ingredient 2"],
          "instructions": ["Step 1", "Step 2"]
        }
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final int startIndex = cleanJson.indexOf('{');
        final int endIndex = cleanJson.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        final recipeData = jsonDecode(cleanJson);

        if (mounted) {
          setState(() {
            _generatedRecipe = recipeData;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("AI Chef Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate recipe. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "AI Kitchen Coach",
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: _textWhite, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(bottom: BorderSide(color: _dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's in your fridge?",
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _ingredientsController,
                    style: TextStyle(color: _textWhite),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          "Enter ingredients (e.g. Chicken, Rice, Peppers)",
                      hintStyle: TextStyle(color: _textGrey, fontSize: 14),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _calBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "GENERATE MEAL",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _generatedRecipe != null
                  ? _buildRecipeResult()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _calBlue),
          const SizedBox(height: 20),
          Text("Chef is cooking...", style: TextStyle(color: _textGrey)),
        ],
      ),
    );
  }

  Widget _buildRecipeResult() {
    final recipe = _generatedRecipe!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe['title'] ?? "Custom Recipe",
            style: TextStyle(
              color: _textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe['description'] ?? "",
            style: TextStyle(color: _textGrey, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.timer_outlined, color: _textGrey, size: 20),
              const SizedBox(width: 8),
              Text(
                "Prep Time: ${recipe['prep_time'] ?? '20 mins'}",
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroBadge(
                "Calories",
                "${recipe['calories']} kcal",
                _calBlue,
              ),
              _buildMacroBadge("Protein", "${recipe['protein']}g", _protPurple),
              _buildMacroBadge("Carbs", "${recipe['carbs']}g", _carbGreen),
              _buildMacroBadge("Fat", "${recipe['fat']}g", _fatRed),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "Ingredients",
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate((recipe['ingredients'] as List).length, (
                index,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ",
                        style: TextStyle(
                          color: _calBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recipe['ingredients'][index].toString(),
                          style: TextStyle(color: _textWhite, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "Instructions",
            style: TextStyle(
              color: _textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate((recipe['instructions'] as List).length, (
              index,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _calBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: _calBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        recipe['instructions'][index].toString(),
                        style: TextStyle(color: _textWhite, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value.replaceAll(RegExp(r'[^0-9]'), ''),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
      ],
    );
  }
}
