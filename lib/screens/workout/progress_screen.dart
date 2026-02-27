import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // --- COLORS & THEME ---
  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = const Color(0xFF2F80ED);
  final Color _neonGreen = const Color(0xFFD0FD3E);
  final Color _textGrey = Colors.grey;
  final Color _gridColor = Colors.white10;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Login Required")));

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Statistics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. NEW: WEIGHT TRACKER ---
            const Text(
              "Body Metrics",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildWeightSection(user.uid),

            const SizedBox(height: 30),

            // --- 2. WORKOUT DATA STREAM ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                final stats = _calculateStats(docs);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. RADAR CHART
                    Center(
                      child: Text(
                        "Muscle Balance (30 Days)",
                        style: TextStyle(color: _textGrey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRadarChart(
                      stats['currentMuscleCounts'],
                      stats['prevMuscleCounts'],
                    ),
                    const SizedBox(height: 10),
                    _buildLegend(),
                    const SizedBox(height: 30),

                    // B. QUICK STATS GRID
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      children: [
                        _buildStatBlock(
                          "Workouts",
                          "${docs.length}",
                          "Total Sessions",
                          Icons.fitness_center,
                        ),
                        _buildStatBlock(
                          "Duration",
                          "${stats['totalDuration']}m",
                          "Minutes Trained",
                          Icons.timer,
                        ),
                        _buildStatBlock(
                          "Volume",
                          stats['totalVolumeString'],
                          "Kg Lifted",
                          Icons.bar_chart,
                        ),
                        _buildStatBlock(
                          "Sets",
                          "${stats['totalSets']}",
                          "Total Sets",
                          Icons.layers,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // C. ADVANCED MENUS (RESTORED)
                    const Text(
                      "Advanced Statistics",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildMenuTile(
                      icon: Icons.pie_chart_outline,
                      title: "Set count per muscle group",
                      subtitle: "Breakdown by percentages",
                      onTap: () =>
                          _showPieChartSheet(stats['currentMuscleCounts']),
                    ),
                    _buildMenuTile(
                      icon: Icons.bar_chart,
                      title: "Muscle Intensity (Heatmap)",
                      subtitle: "Which muscles are overworked?",
                      onTap: () =>
                          _showHeatMapSheet(stats['currentMuscleCounts']),
                    ),
                    _buildMenuTile(
                      icon: Icons.list,
                      title: "Main exercises",
                      subtitle: "Your most frequent lifts",
                      onTap: () =>
                          _showTopExercisesSheet(stats['topExercises']),
                    ),
                    _buildMenuTile(
                      icon: Icons.emoji_events_outlined,
                      title: "Leaderboard Exercises",
                      subtitle: "Your Personal Records (1RM)",
                      onTap: () => _showPRSheet(stats['prMap']),
                    ),
                    _buildMenuTile(
                      icon: Icons.calendar_today,
                      title: "Monthly Report",
                      subtitle: "Recap of this month",
                      onTap: () => _showMonthlyReport(stats),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  //                 SECTION 1: WEIGHT TRACKER
  // =========================================================

  Widget _buildWeightSection(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('weight_history')
          .orderBy('date', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );

        var docs = snapshot.data!.docs;
        double currentWeight = docs.isNotEmpty
            ? (docs.first['weight'] as num).toDouble()
            : 0.0;
        double weeklyAvg = 0.0;
        List<FlSpot> graphPoints = [];

        if (docs.isNotEmpty) {
          double sum = 0;
          for (var i = 0; i < docs.length; i++) {
            double w = (docs[i]['weight'] as num).toDouble();
            sum += w;
            graphPoints.add(FlSpot((docs.length - 1 - i).toDouble(), w));
          }
          weeklyAvg = sum / docs.length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current",
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                      Text(
                        currentWeight > 0 ? "$currentWeight kg" : "--",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Weekly Avg",
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                      Text(
                        weeklyAvg > 0
                            ? "${weeklyAvg.toStringAsFixed(1)} kg"
                            : "--",
                        style: TextStyle(
                          color: _neonGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: docs.isEmpty
                    ? Center(
                        child: Text(
                          "Log your weight to see trends",
                          style: TextStyle(color: _textGrey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: (weeklyAvg - 5),
                          maxY: (weeklyAvg + 5),
                          lineBarsData: [
                            LineChartBarData(
                              spots: graphPoints,
                              isCurved: true,
                              color: _neonBlue,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _neonBlue.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogWeightDialog(uid),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Log Today's Weight"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: _neonBlue),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogWeightDialog(String uid) {
    final TextEditingController weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text("Log Weight", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter kg",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _neonBlue),
            onPressed: () async {
              double? weight = double.tryParse(weightController.text);
              if (weight != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('weight_history')
                    .add({
                      'weight': weight,
                      'date': FieldValue.serverTimestamp(),
                    });
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'weight': weight});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  //                 SECTION 2: WORKOUT CHARTS
  // =========================================================

  Widget _buildRadarChart(Map<String, int> current, Map<String, int> previous) {
    final muscles = ['Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Core'];
    List<RadarEntry> getEntries(Map<String, int> data) {
      return muscles.map((m) {
        double val = (data[m] ?? 0).toDouble();
        return RadarEntry(value: min(val, 20));
      }).toList();
    }

    return SizedBox(
      height: 250,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: [
            RadarDataSet(
              fillColor: Colors.grey.withOpacity(0.15),
              borderColor: Colors.grey.withOpacity(0.5),
              entryRadius: 0,
              dataEntries: getEntries(previous),
              borderWidth: 1.5,
            ),
            RadarDataSet(
              fillColor: _neonBlue.withOpacity(0.2),
              borderColor: _neonBlue,
              entryRadius: 3,
              dataEntries: getEntries(current),
              borderWidth: 2,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.1,
          titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          getTitle: (index, angle) {
            if (index < muscles.length)
              return RadarChartTitle(text: muscles[index]);
            return const RadarChartTitle(text: "");
          },
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          gridBorderData: BorderSide(color: _gridColor, width: 1),
          tickBorderData: BorderSide(color: _gridColor, width: 1),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Current", _neonBlue),
        const SizedBox(width: 20),
        _legendItem("Previous", Colors.grey),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatBlock(
    String title,
    String value,
    String subValue,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subValue,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: _textGrey, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: _textGrey, size: 18),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  //                 SECTION 3: BOTTOM SHEETS
  // =========================================================

  void _showPieChartSheet(Map<String, int> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 450,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Set Breakdown",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: data.entries.map((e) {
                    return PieChartSectionData(
                      color: _getMuscleColor(e.key),
                      value: e.value.toDouble(),
                      title: '${e.value}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: data.keys
                  .map((k) => _legendItem(k, _getMuscleColor(k)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHeatMapSheet(Map<String, int> data) {
    var sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    int maxVal = sorted.isNotEmpty ? sorted.first.value : 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Muscle Intensity",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  var item = sorted[index];
                  double percent = item.value / maxVal;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.key,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              "${item.value} Sets",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.black,
                          color: Color.lerp(Colors.blue, Colors.red, percent),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopExercisesSheet(Map<String, int> data) {
    var sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Top Exercises",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: min(sorted.length, 15),
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _neonBlue.withOpacity(0.2),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(color: _neonBlue),
                    ),
                  ),
                  title: Text(
                    sorted[index].key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    "${sorted[index].value} times",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPRSheet(Map<String, double> prs) {
    var sorted = prs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Personal Records (Est. 1RM)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    sorted[index].key,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    "${sorted[index].value.toStringAsFixed(1)} kg",
                    style: TextStyle(
                      color: _neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  void _showMonthlyReport(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text(
          "Monthly Recap",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Total Volume: ${stats['totalVolumeString']}\nTotal Sets: ${stats['totalSets']}\nMost Trained: ${stats['topMuscle']}",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  //                 SECTION 4: LOGIC HELPERS
  // =========================================================

  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalVol = 0;
    int totalSets = 0;
    int totalDuration = 0;
    Map<String, int> currentMuscleCounts = {
      'Chest': 0,
      'Back': 0,
      'Legs': 0,
      'Arms': 0,
      'Shoulders': 0,
      'Core': 0,
    };
    Map<String, int> prevMuscleCounts = {
      'Chest': 0,
      'Back': 0,
      'Legs': 0,
      'Arms': 0,
      'Shoulders': 0,
      'Core': 0,
    };
    Map<String, int> topExercises = {};
    Map<String, double> prMap = {};

    DateTime now = DateTime.now();
    DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
    DateTime sixtyDaysAgo = now.subtract(const Duration(days: 60));

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime date = (data['timestamp'] as Timestamp).toDate();
      bool isCurrent = date.isAfter(thirtyDaysAgo);
      bool isPrevious =
          date.isAfter(sixtyDaysAgo) && date.isBefore(thirtyDaysAgo);

      if (isCurrent)
        totalDuration += (data['durationSeconds'] as int? ?? 0) ~/ 60;

      List exercises = data['exercises'] ?? [];
      for (var ex in exercises) {
        List sets = ex['sets'] ?? [];
        String name = ex['name'].toString();

        if (isCurrent) topExercises[name] = (topExercises[name] ?? 0) + 1;
        String target = _getMuscleTarget(name);

        if (isCurrent) {
          totalSets += sets.length;
          currentMuscleCounts[target] =
              (currentMuscleCounts[target] ?? 0) + sets.length;
        } else if (isPrevious) {
          prevMuscleCounts[target] =
              (prevMuscleCounts[target] ?? 0) + sets.length;
        }

        for (var s in sets) {
          double w = double.tryParse(s['weight'].toString()) ?? 0;
          double r = double.tryParse(s['reps'].toString()) ?? 0;
          if (isCurrent) totalVol += (w * r);
          if (w > 0 && r > 0) {
            double oneRM = w * (1 + r / 30);
            if (oneRM > (prMap[name] ?? 0)) prMap[name] = oneRM;
          }
        }
      }
    }

    String topMuscle = "None";
    if (currentMuscleCounts.isNotEmpty) {
      var maxEntry = currentMuscleCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      if (maxEntry.value > 0) topMuscle = maxEntry.key;
    }

    return {
      "totalVolumeString": totalVol > 1000
          ? "${(totalVol / 1000).toStringAsFixed(1)}k"
          : totalVol.toStringAsFixed(0),
      "totalSets": totalSets,
      "totalDuration": totalDuration,
      "currentMuscleCounts": currentMuscleCounts,
      "prevMuscleCounts": prevMuscleCounts,
      "topExercises": topExercises,
      "prMap": prMap,
      "topMuscle": topMuscle,
    };
  }

  String _getMuscleTarget(String name) {
    name = name.toLowerCase();
    if (name.contains("bench") ||
        name.contains("chest") ||
        name.contains("push") ||
        name.contains("fly"))
      return "Chest";
    if (name.contains("back") ||
        name.contains("row") ||
        name.contains("pull") ||
        name.contains("lat"))
      return "Back";
    if (name.contains("squat") || name.contains("leg") || name.contains("calf"))
      return "Legs";
    if (name.contains("curl") ||
        name.contains("tricep") ||
        name.contains("bicep"))
      return "Arms";
    if (name.contains("shoulder") ||
        name.contains("press") ||
        name.contains("raise"))
      return "Shoulders";
    return "Core";
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle) {
      case "Chest":
        return Colors.blue;
      case "Back":
        return Colors.purple;
      case "Legs":
        return Colors.red;
      case "Arms":
        return Colors.orange;
      case "Shoulders":
        return Colors.yellow;
      default:
        return Colors.teal;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: _cardDark),
            const SizedBox(height: 20),
            const Text(
              "No Workout Data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Complete a workout to see stats here.",
              style: TextStyle(color: _textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
