import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen2.dart';
import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  String? selectedGender;

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
          "Step 1 of 6",
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
                "What's your Gender ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Description Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFFB19FF4),
              child: const Center(
                child: Text(
                  "Help us get to know you! This allows us to customize your workout intensity and calorie targets.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(),

            // Gender Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGenderButton("Male", Icons.male, "Male"),
                _buildGenderButton("Female", Icons.female, "Female"),
              ],
            ),

            const Spacer(),

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: selectedGender == null
                      ? null
                      : () {
                          Map<String, dynamic> userData = {
                            'gender': selectedGender,
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OnboardingScreen2(userData: userData),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8FF4F),
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

  Widget _buildGenderButton(String genderValue, IconData icon, String label) {
    bool isSelected = selectedGender == genderValue;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = genderValue),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFE8FF4F)
                  : const Color(0xFF2C2C2E),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(
              icon,
              size: 70,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE8FF4F) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}