import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Single Import
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class FoodLensScreen extends StatefulWidget {
  const FoodLensScreen({super.key});

  @override
  State<FoodLensScreen> createState() => _FoodLensScreenState();
}

class _FoodLensScreenState extends State<FoodLensScreen> {
  final _supabase = Supabase.instance.client; // ✅ Supabase Client Instance
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  final ImagePicker _picker = ImagePicker();
  final String _apiKey = "AIzaSyACHwc1yYdZ5QYviaOsquCDTaaC0Kgs40c";

  // --- ✅ DYNAMIC THEME COLORS ---
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white10 : Colors.black12;

  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _neonGreen = const Color(0xFFD0FD3E);

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
        _error = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final prompt = TextPart(
        "Analyze this food image as an expert nutritionist. Identify the dish name and provide a short description. Provide estimates for ALL macros (Protein, Carbs, Fats) and Calories. Return ONLY a valid JSON object with no markdown. Structure: { \"foodName\": \"...\", \"description\": \"...\", \"calories\": 0, \"protein\": 0, \"carbs\": 0, \"fat\": 0 }",
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      final model = GenerativeModel(
        model: 'gemini-flash-latest', // ✅ Updated to latest stable model
        apiKey: _apiKey,
      );
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        Map<String, dynamic> data = jsonDecode(cleanJson);

        if (mounted) {
          setState(() {
            _result = data;
            _isAnalyzing = false;
          });
        }
      } else {
        throw "Empty response from AI.";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _error = "Could not identify food. Please try again.";
        });
      }
    }
  }

  // --- ✅ UPDATED: LOG MEAL TO SUPABASE ---
  Future<void> _logMeal() async {
    final user = _supabase.auth.currentUser; // ✅ Using Supabase User
    if (user == null || _result == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // ✅ Map keys to snake_case schema established in ai_chef and food_detail screens
      await _supabase.from('meals').insert({
        'user_id': user.id,
        'food_name': _result!['foodName'],
        'calories': (_result!['calories'] as num).toInt(),
        'protein': (_result!['protein'] as num).toInt(),
        'carbs': (_result!['carbs'] as num).toInt(),
        'fats': (_result!['fat'] as num).toInt(),
        'log_date': today,
        'timestamp': DateTime.now()
            .toIso8601String(), // ✅ ISO String for PostgreSQL
        'source': "AI Food Lens",
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Meal Logged Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logging meal: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI remains identical to your original design...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
        title: Text(
          "AI Food Lens",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showPickerOptions(),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _dividerColor),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 50,
                            color: _neonBlue,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tap to Snap or Upload",
                            style: TextStyle(color: _textGrey),
                          ),
                        ],
                      )
                    : _isAnalyzing
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 15),
                              Text(
                                "AI is Analyzing...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neonGreen.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _result!['foodName'] ?? "Unknown Food",
                            style: TextStyle(
                              color: _textWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _neonGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_result!['calories']} kcal",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _result!['description'] ?? "",
                      style: TextStyle(color: _textGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMacroItem(
                          "Protein",
                          "${_result!['protein']}g",
                          Colors.blueAccent,
                        ),
                        _buildMacroItem(
                          "Carbs",
                          "${_result!['carbs']}g",
                          _neonGreen,
                        ),
                        _buildMacroItem(
                          "Fat",
                          "${_result!['fat']}g",
                          Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _logMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "LOG THIS MEAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ] else if (_image == null) ...[
              Text(
                "Snap a photo to instantly calculate macros.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
      ],
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: _textWhite),
                title: Text("Take Photo", style: TextStyle(color: _textWhite)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: _textWhite),
                title: Text(
                  "Choose from Gallery",
                  style: TextStyle(color: _textWhite),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
