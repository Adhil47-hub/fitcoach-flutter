import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/homescreen.dart';
import 'package:flutter/material.dart';

class OnboardingScreen6 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen6({super.key, required this.userData});

  @override
  State<OnboardingScreen6> createState() => _OnboardingScreen6State();
}

class _OnboardingScreen6State extends State<OnboardingScreen6> {
  String? _selectedGoal;
  bool _isLoading = false;

  Color get neonLime => const Color(0xFFE8FF4F);

  // --- SAVE LOGIC ---
  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No user logged in!")));
        return;
      }

      // 1. Add final data points
      widget.userData['goal'] = _selectedGoal;
      widget.userData['profileComplete'] = true; // MARK PROFILE AS COMPLETE

      // Optional: Add timestamp if not present
      if (!widget.userData.containsKey('createdAt')) {
        widget.userData['updatedAt'] = FieldValue.serverTimestamp();
      }

      // 2. Save to Firestore (Merge to avoid deleting email/uid)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(widget.userData, SetOptions(merge: true));
      print("✅ SUCCESS! Data saved to Firebase: ${widget.userData}");

      // 3. Navigate to Home (Clear back stack so they can't go back to onboarding)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homescreen()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          "Step 6 of 6",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        // CHANGE 1: Removed the outer Padding widget here
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // CHANGE 2: Added Padding specifically for the Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "What Is Your Goal?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // CHANGE 3: The Container has NO external padding (touches edges)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              color: const Color(0xFFB19FF4),
              child: const Center(
                child: Text(
                  "Select your primary goal so we can tailor your workout and nutrition plan.",
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

            // --- GOAL CARDS ---
            Expanded(
              child: SingleChildScrollView(
                // CHANGE 4: Added Padding inside scroll view for the cards
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildGoalCard(
                      "Lose Weight",
                      "Burn fat & get lean",
                      Icons.local_fire_department,
                    ),
                    const SizedBox(height: 15),
                    _buildGoalCard(
                      "Build Muscle",
                      "Gain mass & strength",
                      Icons.fitness_center,
                    ),
                    const SizedBox(height: 15),
                    _buildGoalCard(
                      "Keep Fit",
                      "Maintain weight & tone",
                      Icons.favorite,
                    ),
                    const SizedBox(height: 15),
                    _buildGoalCard(
                      "Gain Weight",
                      "Healthy bulking",
                      Icons.monitor_weight,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- FINISH BUTTON ---
            // CHANGE 5: Added Padding specifically for the Button
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedGoal == null || _isLoading)
                      ? null
                      : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonLime,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade900,
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Finish",
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
    );
  }

  // --- Custom Card Builder ---
  Widget _buildGoalCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedGoal == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = title;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? neonLime : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            // Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Radio Circle Indicator
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
