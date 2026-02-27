import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class AiChefScreen extends StatefulWidget {
  const AiChefScreen({super.key});

  @override
  State<AiChefScreen> createState() => _AiChefScreenState();
}

class _AiChefScreenState extends State<AiChefScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedRecipe;

  // ✅ YOUR WORKING KEY
  final String _apiKey = 'AIzaSyCXF7tJQT9wjqXMhg2o1ZzONDP4ZxhjblA';

  final Color _bgBlack = const Color(0xFF0F0F10);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = const Color(0xFF2F80ED);

  // ✅ FREE TIER LATEST MODEL
  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.isEmpty) return;
    setState(() => _isGenerating = true);

    try {
      // strictly using the winning model
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );
      final prompt =
          '''
        I have these ingredients: ${_ingredientsController.text}.
        Suggest a high-protein meal recipe using them.
        Strictly return a JSON object with this structure (no markdown):
        {
          "title": "Recipe Name",
          "calories": 500,
          "protein": 30,
          "carbs": 40,
          "fats": 15,
          "instructions": "Step 1... Step 2..."
        }
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        Map<String, dynamic> data = jsonDecode(cleanJson);

        setState(() {
          _generatedRecipe = data;
        });
      }
    } catch (e) {
      print("Model failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI Error: Could not generate recipe. Try again."),
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _logMeal() async {
    if (_generatedRecipe == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('nutrition_logs')
        .doc(today)
        .collection('meals')
        .add({
          "foodName": _generatedRecipe!['title'],
          "calories": _generatedRecipe!['calories'],
          "protein": _generatedRecipe!['protein'],
          "carbs": _generatedRecipe!['carbs'],
          "fats": _generatedRecipe!['fats'],
          "timestamp": FieldValue.serverTimestamp(),
          "source": "AI Chef",
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Recipe Logged!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "AI Kitchen Coach",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's in your fridge?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter ingredients (e.g. Chicken, Rice, Peppers)",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ingredientsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: _cardDark,
                hintText: "Type ingredients...",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateRecipe,
                style: ElevatedButton.styleFrom(backgroundColor: _neonBlue),
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "GENERATE MEAL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (_generatedRecipe != null) ...[
              const SizedBox(height: 40),
              _buildRecipeCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _logMeal,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _neonBlue),
                  ),
                  child: const Text(
                    "COOK & LOG THIS MEAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _generatedRecipe!['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat("Cals", "${_generatedRecipe!['calories']}"),
              _stat("Prot", "${_generatedRecipe!['protein']}g"),
              _stat("Carb", "${_generatedRecipe!['carbs']}g"),
              _stat("Fat", "${_generatedRecipe!['fats']}g"),
            ],
          ),
          const Divider(color: Colors.white12, height: 30),
          Text(
            _generatedRecipe!['instructions'],
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
