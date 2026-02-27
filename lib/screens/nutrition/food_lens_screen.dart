import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class FoodLensScreen extends StatefulWidget {
  const FoodLensScreen({super.key});

  @override
  State<FoodLensScreen> createState() => _FoodLensScreenState();
}

class _FoodLensScreenState extends State<FoodLensScreen> {
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _error;

  final ImagePicker _picker = ImagePicker();

  // ✅ YOUR WORKING KEY
  final String _apiKey = 'AIzaSyCXF7tJQT9wjqXMhg2o1ZzONDP4ZxhjblA';

  final Color _bgBlack = const Color(0xFF0F0F10);
  final Color _cardDark = const Color(0xFF1C1C1E);
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

  // ✅ FREE TIER LATEST MODEL
  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final prompt = TextPart(
        "Analyze this food image as an expert nutritionist for a bodybuilder. Identify the dish name and provide a short description. Crucially, provide highly accurate estimates for ALL macros (Protein, Carbs, Fats) and Calories. If unsure, estimate based on standard serving sizes for these ingredients. Return ONLY a valid JSON object with no markdown formatting. Structure: { \"foodName\": \"...\", \"description\": \"...\", \"calories\": 0, \"protein\": 0, \"carbs\": 0, \"fat\": 0 }",
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      // strictly using the winning model
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
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
      print("Model failed for image analysis: $e");
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _error = "Could not identify food. Please try again.";
        });
      }
    }
  }

  Future<void> _logMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _result == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('nutrition_logs')
        .doc(today)
        .collection('meals')
        .add({
          "foodName": _result!['foodName'],
          "calories": _result!['calories'],
          "protein": _result!['protein'],
          "carbs": _result!['carbs'],
          "fats": _result!['fat'],
          "timestamp": FieldValue.serverTimestamp(),
          "source": "AI Food Lens",
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meal Logged Successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "AI Food Lens",
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
                  border: Border.all(color: Colors.white10),
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
                          const Text(
                            "Tap to Snap or Upload",
                            style: TextStyle(color: Colors.grey),
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
                            style: const TextStyle(
                              color: Colors.white,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                          Colors.greenAccent,
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
              const Text(
                "Snap a photo to instantly calculate macros.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  "Take Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(color: Colors.white),
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
