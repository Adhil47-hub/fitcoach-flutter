import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen6.dart';
import 'package:flutter/material.dart';

class OnboardingScreen5 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen5({super.key, required this.userData});

  @override
  State<OnboardingScreen5> createState() => _OnboardingScreen5State();
}

class _OnboardingScreen5State extends State<OnboardingScreen5> {
  String? _selectedActivityLevel;

  Color get neonLime => const Color(0xFFE8FF4F);
  Color get purpleBox => const Color(0xFFB19FF4);

  void _continueToNextScreen() {
    widget.userData['activity_level'] = _selectedActivityLevel;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen6(userData: widget.userData),
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
          "Step 5 of 6",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Physical Activity Level",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        color: purpleBox,
                        child: const Center(
                          child: Text(
                            "Choose your regular activity level. This helps us calculate your daily calorie burn.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- ACTIVITY CARDS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildActivityCard(
                              level: "Sedentary",
                              description: "Little or no exercise",
                            ),
                            const SizedBox(height: 15),
                            _buildActivityCard(
                              level: "Lightly Active",
                              description: "Light exercise 1-3 days/week",
                            ),
                            const SizedBox(height: 15),
                            _buildActivityCard(
                              level: "Moderately Active",
                              description: "Moderate exercise 3-5 days/week",
                            ),
                            const SizedBox(height: 15),
                            _buildActivityCard(
                              level: "Very Active",
                              description: "Hard exercise 6-7 days/week",
                            ),
                          ],
                        ),
                      ),

                      // Push the button to the bottom
                      const Spacer(),

                      // --- CONTINUE BUTTON ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _selectedActivityLevel == null
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String level,
    required String description,
  }) {
    bool isSelected = _selectedActivityLevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivityLevel = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? neonLime : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? neonLime : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
