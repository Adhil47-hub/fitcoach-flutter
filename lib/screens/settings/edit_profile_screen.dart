import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const EditProfileScreen({super.key, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  // Dropdown Values (AI Sync Fields)
  String _selectedGoal = "Build Muscle";
  String _selectedLevel = "Intermediate";
  String _selectedEquipment = "Gym (Full)";
  String _selectedGender = "Male";
  String _selectedActivity = "Active";

  // Options Lists
  final List<String> _goals = [
    "Build Muscle",
    "Lose Weight",
    "Increase Strength",
  ];
  final List<String> _levels = ["Beginner", "Intermediate", "Pro"];
  final List<String> _equipmentOptions = [
    "Gym (Full)",
    "Home (Dumbbells)",
    "Bodyweight Only",
  ];
  final List<String> _genders = ["Male", "Female", "Other"];
  final List<String> _activities = [
    "Sedentary",
    "Lightly Active",
    "Active",
    "Very Active",
  ];

  bool _isLoading = false;

  // Colors
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonYellow = const Color(0xFFD0FD3E);
  final Color _neonBlue = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    _nameController = TextEditingController(
      text: widget.currentData['displayName'] ?? "",
    );
    _weightController = TextEditingController(
      text: widget.currentData['weight']?.toString() ?? "",
    );
    _heightController = TextEditingController(
      text: widget.currentData['height']?.toString() ?? "",
    );
    _ageController = TextEditingController(
      text: widget.currentData['age']?.toString() ?? "",
    );

    // Safety checks for dropdowns to ensure values exist in our lists
    if (_goals.contains(widget.currentData['primaryGoal'])) {
      _selectedGoal = widget.currentData['primaryGoal'];
    } else if (_goals.contains(widget.currentData['goal'])) {
      _selectedGoal = widget.currentData['goal'];
    }

    if (_levels.contains(widget.currentData['fitnessLevel'])) {
      _selectedLevel = widget.currentData['fitnessLevel'];
    }

    if (_equipmentOptions.contains(widget.currentData['equipment'])) {
      _selectedEquipment = widget.currentData['equipment'];
    }

    if (_genders.contains(widget.currentData['gender'])) {
      _selectedGender = widget.currentData['gender'];
    }

    if (_activities.contains(widget.currentData['activity_level'])) {
      _selectedActivity = widget.currentData['activity_level'];
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      double weight = double.tryParse(_weightController.text) ?? 0;
      double height = double.tryParse(_heightController.text) ?? 0;

      // Auto-Calculate BMI for AI
      double bmi = 0;
      if (weight > 0 && height > 0) {
        bmi = weight / ((height / 100) * (height / 100));
      }

      // --- SMART SYNC WRITE ---
      // We write to both legacy fields (for ProfileScreen) and new fields (for AI)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'weight': weight,
        'height': height,
        'bmi': double.parse(bmi.toStringAsFixed(1)),

        // AI SPECIFIC FIELDS
        'fitnessLevel': _selectedLevel, // AI Needs this
        'primaryGoal': _selectedGoal, // AI Needs this
        'goal': _selectedGoal, // ProfileScreen uses this
        'equipment': _selectedEquipment, // AI Needs this
        'activity_level': _selectedActivity,

        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // Go back to Profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated & Synced with AI!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    "SAVE",
                    style: TextStyle(
                      color: _neonYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Basic Info"),
            _buildTextField("Display Name", _nameController),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildTextField("Age", _ageController, isNumber: true),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDropdown(
                    "Gender",
                    _genders,
                    _selectedGender,
                    (v) => setState(() => _selectedGender = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionHeader("Body Stats (For AI)"),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Weight (kg)",
                    _weightController,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTextField(
                    "Height (cm)",
                    _heightController,
                    isNumber: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionHeader("Training Preferences"),
            _buildDropdown(
              "Fitness Level",
              _levels,
              _selectedLevel,
              (v) => setState(() => _selectedLevel = v!),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Primary Goal",
              _goals,
              _selectedGoal,
              (v) => setState(() => _selectedGoal = v!),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Access to Equipment",
              _equipmentOptions,
              _selectedEquipment,
              (v) => setState(() => _selectedEquipment = v!),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Activity Level",
              _activities,
              _selectedActivity,
              (v) => setState(() => _selectedActivity = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: _neonBlue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              dropdownColor: _cardDark,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
