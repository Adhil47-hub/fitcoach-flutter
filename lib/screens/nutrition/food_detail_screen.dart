import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/screens/nutrition/food_search_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _supabase = Supabase.instance.client;

  String _selectedMeal = "Breakfast";
  double _inputQuantity = 1.0;
  String _selectedUnit = "serving";
  double _gramsPerUnit = 100.0;

  double _finalMultiplier = 1.0;
  bool _isLoading = false;

  int _goalCalories = 2000;
  int _goalCarbs = 250;
  int _goalFat = 70;
  int _goalProtein = 150;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white10 : Colors.black12;

  final Color _calBlue = const Color(0xFF2F80ED);
  final Color _protPurple = const Color(0xFFBB86FC);
  final Color _fatRed = const Color(0xFFFF5252);
  final Color _carbGreen = const Color(0xFFD0FD3E);

  @override
  void initState() {
    super.initState();
    _fetchUserGoals();
    _determineMealTime();

    _selectedUnit = widget.food.standardServingUnit;
    _gramsPerUnit = widget.food.standardServingWeight;
    _recalculate();
  }

  void _determineMealTime() {
    int hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMeal = "Breakfast";
    } else if (hour < 16) {
      _selectedMeal = "Lunch";
    } else if (hour < 20) {
      _selectedMeal = "Dinner";
    } else {
      _selectedMeal = "Snacks";
    }
  }

  Future<void> _fetchUserGoals() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('goals')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _goalCalories = (data['calories'] ?? 2000).toInt();
          _goalProtein = (data['protein'] ?? 150).toInt();
          _goalCarbs = (data['carbs'] ?? 250).toInt();
          _goalFat = (data['fat'] ?? 70).toInt();
        });
      }
    } catch (e) {
      debugPrint("Error fetching goals: $e");
    }
  }

  void _recalculate() {
    setState(() {
      _finalMultiplier = (_inputQuantity * _gramsPerUnit) / 100;
    });
  }

  Future<void> _logFood() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await _supabase.from('meals').insert({
        'user_id': user.id,
        'food_name': widget.food.name.replaceAll('✨ ', ''),
        'calories': (widget.food.calories * _finalMultiplier).toInt(),
        'protein': (widget.food.protein * _finalMultiplier).toInt(),
        'carbs': (widget.food.carbs * _finalMultiplier).toInt(),
        'fats': (widget.food.fat * _finalMultiplier).toInt(),
        'meal_type': _selectedMeal,
        'log_date': today,
        'timestamp': DateTime.now().toIso8601String(),
        'source': widget.food.isAiGenerated ? "AI" : "Database",
        'serving_amount': _inputQuantity,
        'serving_unit': _selectedUnit,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalCals = widget.food.calories * _finalMultiplier;
    double totalProt = widget.food.protein * _finalMultiplier;
    double totalCarbs = widget.food.carbs * _finalMultiplier;
    double totalFat = widget.food.fat * _finalMultiplier;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        iconTheme: IconThemeData(color: _textWhite),
        elevation: 0,
        title: Text(
          "Add Food",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _textWhite,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.food.name,
                    style: TextStyle(
                      color: _textWhite,
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
              style: TextStyle(color: _textGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _buildPortionCard(),
            const SizedBox(height: 25),
            _buildMacroBreakdown(totalCals, totalProt, totalCarbs, totalFat),
            const SizedBox(height: 30),
            _buildGoalProgress(totalCals, totalProt, totalCarbs, totalFat),
            const SizedBox(height: 30),
            _buildDetailedStats(totalCals, totalProt, totalCarbs, totalFat),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionCard() {
    return GestureDetector(
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
            _buildRowItem(
              "Meal",
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMeal,
                  dropdownColor: _cardDark,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  items: ["Breakfast", "Lunch", "Dinner", "Snacks"]
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMeal = val);
                  },
                ),
              ),
            ),
            Divider(color: _dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Serving Size",
                    style: TextStyle(color: _textWhite, fontSize: 16),
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
                      Icon(Icons.edit, size: 14, color: _textGrey),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 15, bottom: 5),
                child: Text(
                  "(${_gramsPerUnit.toInt()}g per $_selectedUnit)",
                  style: TextStyle(color: _textGrey, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBreakdown(
    double cals,
    double prot,
    double carbs,
    double fat,
  ) {
    return Row(
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
                      value: carbs,
                      radius: 8,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: _fatRed,
                      value: fat,
                      radius: 8,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: _protPurple,
                      value: prot,
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
                    "${cals.toInt()}",
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("Cal", style: TextStyle(color: _textGrey, fontSize: 12)),
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
              _buildMacroStat("Carbs", carbs, _carbGreen),
              _buildMacroStat("Fat", fat, _fatRed),
              _buildMacroStat("Protein", prot, _protPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(
    double cals,
    double prot,
    double carbs,
    double fat,
  ) {
    return Column(
      children: [
        _buildGoalBar("Calories", cals, _goalCalories.toDouble(), _calBlue),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGoalBar(
                "Carbs",
                carbs,
                _goalCarbs.toDouble(),
                _carbGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGoalBar("Fat", fat, _goalFat.toDouble(), _fatRed),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGoalBar(
                "Protein",
                prot,
                _goalProtein.toDouble(),
                _protPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStats(
    double cals,
    double prot,
    double carbs,
    double fat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow("Calories", "${cals.toInt()}"),
          Divider(color: _dividerColor),
          _buildDetailRow("Fat", "${fat.toStringAsFixed(1)} g"),
          Divider(color: _dividerColor),
          _buildDetailRow("Carbohydrates", "${carbs.toStringAsFixed(1)} g"),
          Divider(color: _dividerColor),
          _buildDetailRow("Protein", "${prot.toStringAsFixed(1)} g"),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textWhite, fontSize: 16)),
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
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
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
            Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
            Text(
              "${(percent * 100).toInt()}%",
              style: TextStyle(color: _textGrey, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
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
          Text(label, style: TextStyle(color: _textWhite)),
          Text(
            value,
            style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showServingDialog() {
    TextEditingController qtyController = TextEditingController(
      text: _inputQuantity.toString(),
    );
    TextEditingController weightController = TextEditingController(
      text: _gramsPerUnit.toString(),
    );
    String tempUnit = _selectedUnit;

    List<String> availableUnits = [
      'g',
      'oz',
      'ml',
      'serving',
      'piece',
      'cup',
      'slice',
      'tbsp',
    ];
    if (!availableUnits.contains(tempUnit)) {
      availableUnits.add(tempUnit);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              "Edit Portion",
              style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInput(qtyController, "Quantity"),
                const SizedBox(height: 15),
                Text("Unit", style: TextStyle(color: _textGrey, fontSize: 12)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tempUnit,
                    dropdownColor: _cardDark,
                    isExpanded: true,
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    items: availableUnits.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          tempUnit = val;
                          if (val == 'g' || val == 'ml') {
                            weightController.text = '1.0';
                          } else if (val == 'oz') {
                            weightController.text = '28.35';
                          } else {
                            weightController.text = widget
                                .food
                                .standardServingWeight
                                .toString();
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildDialogInput(weightController, "Weight of 1 Unit (grams)"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: _textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _calBlue),
                onPressed: () {
                  setState(() {
                    _inputQuantity = double.tryParse(qtyController.text) ?? 1.0;
                    _selectedUnit = tempUnit;
                    _gramsPerUnit =
                        double.tryParse(weightController.text) ?? 100.0;
                    _recalculate();
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogInput(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _textGrey.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _calBlue),
            ),
          ),
        ),
      ],
    );
  }
}
