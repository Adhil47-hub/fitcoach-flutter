import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen7.dart';
import 'package:flutter/material.dart';

class OnboardingScreen6 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen6({super.key, required this.userData});

  @override
  State<OnboardingScreen6> createState() => _OnboardingScreen6State();
}

class _OnboardingScreen6State extends State<OnboardingScreen6> {
  String? _selectedDiet;
  String? _selectedCuisine;

  final TextEditingController _notesController = TextEditingController();

  Color get neonLime => const Color(0xFFE8FF4F);
  Color get purpleBox => const Color(0xFFB19FF4);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _continueToNextScreen() {
    widget.userData['dietary_pattern'] = _selectedDiet;
    widget.userData['cuisine'] = _selectedCuisine;
    widget.userData['dietary_notes'] = _notesController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen7(userData: widget.userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Step 6 of 7",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Dietary Preferences",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: purpleBox,
              child: const Center(
                child: Text(
                  "This helps our AI Coach suggest accurate food swaps and personalized meal ideas based on your lifestyle.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dietary Pattern",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSelectionGroup(
                      options: [
                        "Standard (No Restrictions)",
                        "Vegetarian",
                        "Vegan",
                        "Pescetarian",
                        "Keto / Low Carb",
                      ],
                      selectedValue: _selectedDiet,
                      onSelected: (val) => setState(() => _selectedDiet = val),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Primary Cuisine",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSelectionGroup(
                      options: [
                        "Global / Mixed",
                        "Asian",
                        "Indian",
                        "Mediterranean",
                        "Western",
                        "Latin American",
                      ],
                      selectedValue: _selectedCuisine,
                      onSelected: (val) =>
                          setState(() => _selectedCuisine = val),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Any specific cuisines or custom rules?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "e.g., I love Arabic cuisine, I do intermittent fasting, allergic to peanuts...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: neonLime, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedDiet == null || _selectedCuisine == null)
                      ? null
                      : _continueToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonLime,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade900,
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGroup({
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        bool isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? neonLime : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? neonLime : Colors.white12),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
