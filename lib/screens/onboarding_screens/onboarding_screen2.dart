import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen3.dart';
import 'package:flutter/material.dart';

class OnboardingScreen2 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen2({super.key, required this.userData});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  int _currentAge = 25;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Color get neonLime => const Color(0xFFE8FF4F);

  void _continueToNextScreen() {
    widget.userData['age'] = _currentAge;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen3(userData: widget.userData),
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
          "Step 2 of 6",
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
                "Tell Us About You",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFFB19FF4),
              child: const Center(
                child: Text(
                  "Your age is crucial for calculating your Basal Metabolic Rate (BMR) and defining safe heart rate zones",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(), // Center vertically

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "What is your Age?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Age",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        DropdownButton<int>(
                          value: _currentAge,
                          icon: Icon(Icons.arrow_drop_down, color: neonLime),
                          dropdownColor: const Color(0xFF2C2C2E),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          underline: Container(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() => _currentAge = newValue);
                            }
                          },
                          items: List<int>.generate(80, (i) => i + 15)
                              .map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(), // Push button down

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _continueToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonLime,
                    foregroundColor: Colors.black,
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
}
