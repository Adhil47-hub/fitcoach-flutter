import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/nutrition/food_search_screen.dart'; // To import FoodItem model
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  // State
  String _selectedMeal = "Breakfast";
  double _inputQuantity = 1.0;
  String _selectedUnit = "serving";
  double _gramsPerUnit = 100.0;

  double _finalMultiplier = 1.0;
  bool _isLoading = false;

  // User Goals
  int _goalCalories = 2000;
  int _goalCarbs = 250;
  int _goalFat = 70;
  int _goalProtein = 150;

  // Colors
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _calBlue = const Color(0xFF2F80ED);
  final Color _protPurple = const Color(0xFFBB86FC);
  final Color _fatRed = const Color(0xFFFF5252);
  final Color _carbGreen = const Color(0xFFD0FD3E);

  @override
  void initState() {
    super.initState();
    _fetchUserGoals();
    _determineMealTime();

    // ✅ NO HARDCODING: We use what the AI/Database gave us
    _selectedUnit = widget.food.standardServingUnit;
    _gramsPerUnit = widget.food.standardServingWeight;
    _recalculate();
  }

  void _determineMealTime() {
    int hour = DateTime.now().hour;
    if (hour < 11)
      _selectedMeal = "Breakfast";
    else if (hour < 16)
      _selectedMeal = "Lunch";
    else if (hour < 20)
      _selectedMeal = "Dinner";
    else
      _selectedMeal = "Snacks";
  }

  Future<void> _fetchUserGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          _goalCalories = data['ai_target_calories'] ?? 2000;
          _goalProtein = data['ai_target_protein'] ?? 150;
          _goalCarbs = data['ai_target_carbs'] ?? 250;
          _goalFat = data['ai_target_fats'] ?? 70;
        });
      }
    }
  }

  void _recalculate() {
    // Formula: (Qty * Grams_Per_Unit) / 100 (Since base data is per 100g)
    setState(() {
      _finalMultiplier = (_inputQuantity * _gramsPerUnit) / 100;
    });
  }

  // --- THE IMPROVED DIALOG ---
  void _showServingDialog() {
    TextEditingController qtyController = TextEditingController(
      text: _inputQuantity.toString(),
    );
    TextEditingController weightController = TextEditingController(
      text: _gramsPerUnit.toString(),
    );
    // Only allow editing the name if it's generic, otherwise keep what API gave us
    TextEditingController unitNameController = TextEditingController(
      text: _selectedUnit,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Edit Portion",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. QUANTITY
              _buildDialogInput(qtyController, "Number of Servings"),
              const SizedBox(height: 15),

              // 2. UNIT NAME
              _buildDialogInput(
                unitNameController,
                "Unit Name (e.g. slice, cup)",
              ),
              const SizedBox(height: 15),

              // 3. GRAMS PER UNIT
              _buildDialogInput(weightController, "Weight of 1 Unit (grams)"),
              const SizedBox(height: 10),

              const Text(
                "💡 Verify weight for accuracy.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _calBlue),
              onPressed: () {
                setState(() {
                  _inputQuantity = double.tryParse(qtyController.text) ?? 1.0;
                  _selectedUnit = unitNameController.text;
                  _gramsPerUnit =
                      double.tryParse(weightController.text) ?? 100.0;
                  _recalculate();
                });
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        TextField(
          controller: controller,
          keyboardType: TextInputType.text, // Allow text for unit name
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _logFood() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('nutrition_logs')
          .doc(today)
          .collection('meals')
          .add({
            "foodName": widget.food.name.replaceAll('✨ ', ''),
            "calories": (widget.food.calories * _finalMultiplier).toInt(),
            "protein": (widget.food.protein * _finalMultiplier).toInt(),
            "carbs": (widget.food.carbs * _finalMultiplier).toInt(),
            "fats": (widget.food.fat * _finalMultiplier).toInt(),
            "mealType": _selectedMeal,
            "timestamp": FieldValue.serverTimestamp(),
            "source": widget.food.isAiGenerated ? "AI" : "Database",
            "servingAmount": _inputQuantity,
            "servingUnit": _selectedUnit,
            "gramsPerServing": _gramsPerUnit,
          });

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Food Added Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current Totals
    double totalCals = widget.food.calories * _finalMultiplier;
    double totalProt = widget.food.protein * _finalMultiplier;
    double totalCarbs = widget.food.carbs * _finalMultiplier;
    double totalFat = widget.food.fat * _finalMultiplier;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Food",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.greenAccent, size: 28),
            onPressed: _isLoading ? null : _logFood,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.food.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.food.isAiGenerated)
                  const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                if (!widget.food.isAiGenerated)
                  const Icon(Icons.verified, color: Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              "${widget.food.calories.toInt()} kcal per 100g",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // --- INPUT CARD (Clickable) ---
            GestureDetector(
              onTap: _showServingDialog,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _calBlue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Meal Selector
                    _buildRowItem(
                      "Meal",
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMeal,
                          dropdownColor: _cardDark,
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          items: ["Breakfast", "Lunch", "Dinner", "Snacks"]
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedMeal = val);
                          },
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),

                    // Serving Info
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Serving Size",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Row(
                            children: [
                              Text(
                                "$_inputQuantity $_selectedUnit",
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Hint about weight
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15, bottom: 5),
                        child: Text(
                          "(${_gramsPerUnit.toInt()}g per $_selectedUnit)",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // --- VISUALS ---
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 45,
                          sections: [
                            PieChartSectionData(
                              color: _carbGreen,
                              value: totalCarbs,
                              radius: 8,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: _fatRed,
                              value: totalFat,
                              radius: 8,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: _protPurple,
                              value: totalProt,
                              radius: 8,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${totalCals.toInt()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Cal",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroStat("Carbs", totalCarbs, _carbGreen),
                      _buildMacroStat("Fat", totalFat, _fatRed),
                      _buildMacroStat("Protein", totalProt, _protPurple),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- GOALS ---
            _buildGoalBar(
              "Calories",
              totalCals,
              _goalCalories.toDouble(),
              _calBlue,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildGoalBar(
                    "Carbs",
                    totalCarbs,
                    _goalCarbs.toDouble(),
                    _carbGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGoalBar(
                    "Fat",
                    totalFat,
                    _goalFat.toDouble(),
                    _fatRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGoalBar(
                    "Protein",
                    totalProt,
                    _goalProtein.toDouble(),
                    _protPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- DETAIL LIST ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Calories", "${totalCals.toInt()}"),
                  const Divider(color: Colors.white10),
                  _buildDetailRow("Fat", "${totalFat.toStringAsFixed(1)} g"),
                  const Divider(color: Colors.white10),
                  _buildDetailRow(
                    "Carbohydrates",
                    "${totalCarbs.toStringAsFixed(1)} g",
                  ),
                  const Divider(color: Colors.white10),
                  _buildDetailRow(
                    "Protein",
                    "${totalProt.toStringAsFixed(1)} g",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildRowItem(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, double value, Color color) {
    double totalWeight =
        (widget.food.carbs + widget.food.fat + widget.food.protein) *
        _finalMultiplier;
    int percent = totalWeight > 0 ? ((value / totalWeight) * 100).toInt() : 0;
    return Column(
      children: [
        Text(
          "$percent%",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          "${value.toInt()}g",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildGoalBar(String label, double current, double goal, Color color) {
    double percent = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "${(percent * 100).toInt()}%",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
