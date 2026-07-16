import 'dart:io';
import 'package:fitcoach_/screens/settings/notification_settings_screen.dart';
import 'package:fitcoach_/screens/settings/theme_settings_screen.dart';
import 'package:fitcoach_/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
  final _supabase = Supabase.instance.client;
  bool _isUploadingImage = false;

  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonBlue = const Color(0xFF2F80ED);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(context).cardColor;
  Color get textColor => isDark ? Colors.white : Colors.black;
  Color get subTextColor => isDark ? Colors.grey : Colors.black54;
  Color get dividerColor => isDark ? Colors.white10 : Colors.black12;

  Color get dynamicAccent =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final List<String> _dietOptions = [
    "Balanced (Maintain)",
    "Fat Loss (Deficit)",
    "Muscle Gain (Surplus)",
    "Body Recomposition",
  ];

  User? get _currentUser => _supabase.auth.currentUser;

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showError("Error signing out: $e");
    }
  }

  // --- ✅ UPDATED: Password Verification for Deletion ---
  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete Account",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This action cannot be undone. All your data will be lost.",
                style: TextStyle(color: subTextColor),
              ),
              const SizedBox(height: 15),
              Text(
                "Please enter your password to confirm:",
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: TextStyle(color: subTextColor),
                  filled: true,
                  fillColor: isDark ? Colors.black : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: subTextColor)),
              onPressed: () => Navigator.pop(context),
            ),
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      if (passwordController.text.isEmpty) {
                        _showError("Please enter your password.");
                        return;
                      }

                      setDialogState(() => isDeleting = true);

                      try {
                        // 1. Verify the password by re-authenticating
                        await _supabase.auth.signInWithPassword(
                          email: _currentUser?.email ?? "",
                          password: passwordController.text,
                        );

                        // 2. Delete public profile data
                        await _supabase
                            .from('users')
                            .delete()
                            .eq('id', _currentUser!.id);

                        // Note: If you want to delete the actual Auth user from Supabase entirely
                        // from the client app, you would typically call an RPC function here
                        // e.g., await _supabase.rpc('delete_user');

                        // 3. Sign out and redirect to login
                        await _supabase.auth.signOut();
                        if (!mounted) return;

                        Navigator.pop(context); // Close dialog
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      } on AuthException catch (_) {
                        setDialogState(() => isDeleting = false);
                        _showError("Incorrect password.");
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        _showError("Error deleting account: $e");
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDietMode(String newMode) async {
    try {
      await _supabase
          .from('users')
          .update({
            'diet_mode': newMode,
            'custom_calories': null,
            'custom_protein': null,
            'custom_carbs': null,
            'custom_fats': null,
          })
          .eq('id', _currentUser!.id);

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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading image...")));

    try {
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = 'avatar_${_currentUser!.id}.$fileExt';
      final filePath = 'profiles/$fileName';

      await _supabase.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final String rawUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);
      final String finalUrl =
          "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': finalUrl}),
      );

      await _supabase
          .from('users')
          .update({'user_avatar': finalUrl})
          .eq('id', _currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Error uploading image: $e");
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    String memberSince = "";
    if (_currentUser?.createdAt != null) {
      memberSince =
          "Member since ${DateTime.parse(_currentUser!.createdAt).year}";
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('users')
            .stream(primaryKey: ['id'])
            .eq('id', _currentUser?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: dynamicAccent),
            );
          }

          final Map<String, dynamic> data =
              (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!.first
              : <String, dynamic>{};

          String age = data['age']?.toString() ?? "--";
          String gender = data['gender'] ?? "--";
          String activity = data['activity_level'] ?? "Unknown";
          String goal = data['primary_goal'] ?? "No Goal";
          String dietMode = data['diet_mode'] ?? "Balanced (Maintain)";
          String weightUnit = data['weight_unit'] ?? "kg";
          String heightUnit = data['height_unit'] ?? "cm";
          String dietaryPattern = data['dietary_pattern'] ?? "Standard";
          String cuisine = data['cuisine'] ?? "Global";
          String dietaryNotes = data['dietary_notes'] ?? "";
          String workouts = data['total_workouts']?.toString() ?? "0";
          String streak = data['current_streak']?.toString() ?? "0";
          String fitnessLevel = data['fitness_level'] ?? "Intermediate";
          String equipment = data['equipment'] ?? "Gym (Full)";

          String displayWeight = "--";
          if (data['weight'] != null) {
            if (weightUnit == 'lbs') {
              int lbs = ((data['weight'] as num) * 2.20462).round();
              displayWeight = "$lbs lbs";
            } else {
              displayWeight = "${data['weight']} kg";
            }
          }

          String displayHeight = "--";
          if (data['height'] != null) {
            if (heightUnit == 'ft') {
              int cm = (data['height'] as num).toInt();
              double inches = cm / 2.54;
              int ft = (inches / 12).floor();
              int remInches = (inches % 12).round();
              displayHeight = "$ft' $remInches\"";
            } else {
              displayHeight = "${data['height']} cm";
            }
          }

          String bmi = "0.0";
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
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            _isUploadingImage
                                ? SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator(
                                      color: dynamicAccent,
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 50,
                                    backgroundColor: cardColor,
                                    backgroundImage: data['user_avatar'] != null
                                        ? NetworkImage(data['user_avatar'])
                                        : null,
                                    child: data['user_avatar'] == null
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: subTextColor,
                                          )
                                        : null,
                                  ),
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: dynamicAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: bgColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          data['displayName'] ?? "User",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentUser?.email ?? "",
                          style: TextStyle(color: subTextColor, fontSize: 14),
                        ),
                        if (memberSince.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              memberSince,
                              style: TextStyle(
                                color: _purpleAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconStatItem(
                        Icons.fitness_center,
                        "Workouts",
                        workouts,
                      ),
                      Container(width: 1, height: 30, color: dividerColor),
                      _buildIconStatItem(
                        Icons.local_fire_department,
                        "Streak",
                        "$streak Days",
                        iconColor: Colors.orangeAccent,
                      ),
                      Container(width: 1, height: 30, color: dividerColor),
                      _buildBmiStat(bmi),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Personal Details",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Gender", gender),
                        Divider(color: dividerColor),
                        _buildDetailRow("Age", "$age years"),
                        Divider(color: dividerColor),
                        _buildDetailRow("Height", displayHeight),
                        Divider(color: dividerColor),
                        _buildDetailRow("Weight", displayWeight),
                        Divider(color: dividerColor),
                        _buildDetailRow("Activity", activity),
                        Divider(color: dividerColor),
                        _buildDetailRow(
                          "Main Goal",
                          goal,
                          valueColor: dynamicAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Training Preferences",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("Fitness Level", fitnessLevel),
                        Divider(color: dividerColor),
                        _buildDetailRow("Equipment", equipment),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Nutrition Plan & Diet",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: dividerColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _dietOptions.contains(dietMode)
                                  ? dietMode
                                  : "Balanced (Maintain)",
                              dropdownColor: cardColor,
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: textColor,
                              ),
                              style: TextStyle(color: textColor, fontSize: 16),
                              onChanged: (val) {
                                if (val != null) _updateDietMode(val);
                              },
                              items: _dietOptions
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getModeDescription(dietMode),
                          style: TextStyle(color: _neonBlue, fontSize: 12),
                        ),
                        const SizedBox(height: 15),
                        Divider(color: dividerColor),
                        _buildDetailRow("Diet Pattern", dietaryPattern),
                        Divider(color: dividerColor),
                        _buildDetailRow("Cuisine", cuisine),
                        if (dietaryNotes.isNotEmpty) ...[
                          Divider(color: dividerColor),
                          _buildDetailRow(
                            "Custom Rules",
                            dietaryNotes,
                            valueColor: Colors.redAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
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
                  Text(
                    "Support",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
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
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Log Out",
                        style: TextStyle(color: textColor),
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

  Widget _buildIconStatItem(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? subTextColor, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: dynamicAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildBmiStat(String bmiString) {
    double bmi = double.tryParse(bmiString) ?? 0;
    String label = "";
    Color color = Colors.grey;

    if (bmi > 0) {
      if (bmi < 18.5) {
        label = "Underweight";
        color = Colors.blueAccent;
      } else if (bmi < 25) {
        label = "Normal";
        color = Colors.greenAccent;
      } else if (bmi < 30) {
        label = "Overweight";
        color = Colors.orangeAccent;
      } else {
        label = "Obese";
        color = Colors.redAccent;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight_outlined, color: subTextColor, size: 16),
            const SizedBox(width: 4),
            Text(
              bmiString == "0.0" ? "--" : bmiString,
              style: TextStyle(
                color: dynamicAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.isEmpty ? "BMI" : "BMI ($label)",
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
      leading: Icon(icon, color: textColor, size: 22),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios, color: subTextColor, size: 14),
      onTap: () {
        if (title == "Edit Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
        } else if (title == "Change Password") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        } else if (title == "Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen(),
            ),
          );
        } else if (title == "Theme") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
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
                title: "Terms & Conditions",
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

  Widget _buildDivider() => Divider(color: dividerColor, height: 1);

  String _getModeDescription(String mode) {
    switch (mode) {
      case "Fat Loss (Deficit)":
        return "Caloric deficit to burn fat while maintaining muscle";
      case "Muscle Gain (Surplus)":
        return "Caloric surplus focused on muscle growth and strength";
      case "Body Recomposition":
        return "Build muscle and lose fat simultaneously (Moderate)";
      default:
        return "Maintain current weight with balanced macros";
    }
  }
}
