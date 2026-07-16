import 'package:fitcoach_/screens/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen7 extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OnboardingScreen7({super.key, required this.userData});

  @override
  State<OnboardingScreen7> createState() => _OnboardingScreen7State();
}

class _OnboardingScreen7State extends State<OnboardingScreen7> {
  final _supabase = Supabase.instance.client;
  String? _selectedGoal;
  bool _isLoading = false;

  Color get neonLime => const Color(0xFFE8FF4F);

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      widget.userData['id'] = user.id;
      widget.userData['goal'] = _selectedGoal;
      widget.userData['profileComplete'] = true;
      widget.userData['updatedAt'] = DateTime.now().toIso8601String();

      await _supabase.from('users').upsert(widget.userData);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Homescreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
          "Step 7 of 7",
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              color: const Color(0xFFB19FF4),
              child: const Center(
                child: Text(
                  "Select your goal so we can tailor your plan.",
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
            Expanded(
              child: SingleChildScrollView(
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedGoal == null || _isLoading)
                      ? null
                      : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
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

  Widget _buildGoalCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedGoal == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? neonLime : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white),
            const SizedBox(width: 20),
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
