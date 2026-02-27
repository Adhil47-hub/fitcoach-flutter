import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcoach_/screens/homescreen.dart';
import 'package:fitcoach_/services/auth_service.dart';
import 'package:fitcoach_/services/google_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:fitcoach_/screens/settings/edit_profile_screen.dart';
import 'package:fitcoach_/screens/settings/change_password_screen.dart';
import 'package:fitcoach_/screens/settings/static_content_page.dart';
import 'package:fitcoach_/screens/settings/legal_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;

  // --- COLORS ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _neonBlue = const Color(0xFF2F80ED); // Added for Nutrition
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.grey;

  // --- NUTRITION DATA ---
  final List<String> _dietOptions = [
    "Balanced",
    "Cutting",
    "Bulking",
    "Keto",
    "Low Carb",
  ];

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // --- ACTIONS ---
  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
      await GoogleAuthService.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showError("Error signing out: $e");
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This action cannot be undone. All your data will be lost.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser?.uid)
                    .delete();
                await _currentUser?.delete();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                _showError(
                  "Login again to delete account. (Security Requirement)",
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- UPDATE DIET MODE ---
  Future<void> _updateDietMode(String newMode) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .update({
            'diet_mode': newMode,
            // Clear custom overrides so the new AI mode takes effect
            'custom_calories': FieldValue.delete(),
            'custom_protein': FieldValue.delete(),
            'custom_carbs': FieldValue.delete(),
            'custom_fats': FieldValue.delete(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Goal updated to $newMode!"),
            backgroundColor: _neonBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError("Failed to update goal: $e");
    }
  }

  // --- CLOUDINARY UPLOAD ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading image...")));

    try {
      const String cloudName = "dnj23lghq";
      const String uploadPreset = "fitcoach_preset";

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        final String finalUrl = jsonMap['secure_url'];

        await _currentUser!.updatePhotoURL(finalUrl);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'photoURL': finalUrl});

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile Updated!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Homescreen()),
      );
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      bottomNavigationBar: _buildBottomNav(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8FF4F)),
            );
          }

          Map<String, dynamic> data = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            data = snapshot.data!.data() as Map<String, dynamic>;
          }

          String weight = data['weight']?.toString() ?? "--";
          String height = data['height']?.toString() ?? "--";
          String age = data['age']?.toString() ?? "--";
          String gender = data['gender'] ?? "--";
          String activity = data['activity_level'] ?? "Unknown";
          String goal = data['goal'] ?? "No Goal";
          String dietMode = data['diet_mode'] ?? "Balanced"; // Get current mode

          // Calculate BMI
          String bmi = "--";
          if (data['weight'] != null && data['height'] != null) {
            double w = (data['weight'] as num).toDouble();
            double h = (data['height'] as num).toDouble() / 100;
            bmi = (w / (h * h)).toStringAsFixed(1);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. USER IDENTITY ---
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: _cardDark,
                              backgroundImage: _currentUser?.photoURL != null
                                  ? NetworkImage(_currentUser!.photoURL!)
                                  : null,
                              child: _currentUser?.photoURL == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: _textGrey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _neonYellow,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _currentUser?.displayName ?? "User",
                          style: TextStyle(
                            color: _textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentUser?.email ?? "",
                          style: TextStyle(color: _textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 2. STATS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Workouts", "0"),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildStatItem("Streak", "0 Days"),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildStatItem("BMI", bmi),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- 3. PERSONAL DETAILS ---
                  const Text(
                    "Personal Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Gender", gender),
                        const Divider(color: Colors.white10),
                        _buildDetailRow("Age", "$age years"),
                        const Divider(color: Colors.white10),
                        _buildDetailRow("Height", "$height cm"),
                        const Divider(color: Colors.white10),
                        _buildDetailRow("Weight", "$weight kg"),
                        const Divider(color: Colors.white10),
                        _buildDetailRow("Activity", activity),
                        const Divider(color: Colors.white10),
                        _buildDetailRow(
                          "Main Goal",
                          goal,
                          valueColor: _neonYellow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 4. NEW: DIET & NUTRITION GOAL ---
                  const Text(
                    "Nutrition Plan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _dietOptions.contains(dietMode)
                                  ? dietMode
                                  : "Balanced",
                              dropdownColor: _cardDark,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              onChanged: (val) {
                                if (val != null) _updateDietMode(val);
                              },
                              items: _dietOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getModeDescription(dietMode),
                          style: TextStyle(color: _neonBlue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 5. SETTINGS ---
                  const Text(
                    "Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          Icons.person_outline,
                          "Edit Profile",
                          userData: data,
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          Icons.lock_outline,
                          "Change Password",
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          Icons.notifications_outlined,
                          "Notifications",
                        ),
                        _buildDivider(),
                        _buildSettingsTile(Icons.language, "Language"),
                        _buildDivider(),
                        _buildSettingsTile(Icons.dark_mode_outlined, "Theme"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 6. SUPPORT ---
                  const Text(
                    "Support",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(Icons.help_outline, "Help & FAQ"),
                        _buildDivider(),
                        _buildSettingsTile(
                          Icons.privacy_tip_outlined,
                          "Privacy Policy",
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          Icons.description_outlined,
                          "Terms & Conditions",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- 7. ACTIONS ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: TextButton(
                      onPressed: _deleteAccount,
                      child: const Text(
                        "Delete Account",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: BottomNavigationBar(
        backgroundColor: _bgBlack,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _purpleAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined, size: 28),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: 28),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _neonYellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    Map<String, dynamic>? userData,
  }) {
    return ListTile(
      leading: Icon(icon, color: _textWhite, size: 22),
      title: Text(title, style: TextStyle(color: _textWhite, fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios, color: _textGrey, size: 14),
      onTap: () {
        if (title == "Edit Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(currentData: userData ?? {}),
            ),
          );
        } else if (title == "Change Password") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        } else if (title == "Privacy Policy") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: "Privacy Policy",
                content: privacyPolicyText,
              ),
            ),
          );
        } else if (title == "Terms & Conditions") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: "Terms",
                content: termsConditionsText,
              ),
            ),
          );
        } else if (title == "Help & FAQ") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: "Help & FAQ",
                content: helpFaqText,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title is coming soon!")));
        }
      },
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.white.withOpacity(0.05), height: 1);

  String _getModeDescription(String mode) {
    switch (mode) {
      case "Cutting":
        return "High Protein, Calorie Deficit (Fat Loss)";
      case "Bulking":
        return "High Carb, Calorie Surplus (Muscle Gain)";
      case "Keto":
        return "High Fat, Very Low Carb (<30g)";
      case "Low Carb":
        return "Moderate Fat, Reduced Carbs";
      default:
        return "Balanced Macros for General Health";
    }
  }
}
