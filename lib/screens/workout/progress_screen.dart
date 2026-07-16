import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final Color _purpleAccent = const Color(0xFFBB86FC);
  final Color _neonGreen = const Color(0xFF00E676);
  final Color _neonBlue = const Color(0xFF2F80ED);
  Color get _gridColor => isDark ? Colors.white10 : Colors.black12;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: _bgBlack,
        body: Center(
          child: Text("Login Required", style: TextStyle(color: _textWhite)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _textWhite),
        title: Text(
          "Workout Statistics",
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Body Metrics", "Track your physical progress"),
            const SizedBox(height: 15),
            _buildWeightSection(user.id),
            const SizedBox(height: 35),
            _buildHeader("Performance", "Data-driven training insights"),
            const SizedBox(height: 15),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('workout_history')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final List<Map<String, dynamic>> docs = snapshot.data ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                docs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
                final stats = _calculateStats(docs);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadarContainer(stats),
                    const SizedBox(height: 30),
                    _buildQuickStatsGrid(docs.length, stats),
                    const SizedBox(height: 35),
                    _buildHeader(
                      "Advanced Analysis",
                      "Deep dive into your volume",
                    ),
                    const SizedBox(height: 15),
                    _buildMenuTile(
                      icon: Icons.pie_chart_outline,
                      title: "Set Distribution",
                      subtitle: "Percentage of training per muscle group",
                      onTap: () =>
                          _showPieChartSheet(stats['currentMuscleCounts']),
                    ),
                    _buildMenuTile(
                      icon: Icons.local_fire_department_outlined,
                      title: "Muscle Intensity (Heatmap)",
                      subtitle: "Identify overworked or neglected muscles",
                      onTap: () =>
                          _showHeatMapSheet(stats['currentMuscleCounts']),
                    ),
                    _buildMenuTile(
                      icon: Icons.trending_up_rounded,
                      title: "Top Exercises",
                      subtitle: "Frequency breakdown of your main lifts",
                      onTap: () =>
                          _showTopExercisesSheet(stats['topExercises']),
                    ),
                    _buildMenuTile(
                      icon: Icons.emoji_events_outlined,
                      title: "Personal Records",
                      subtitle: "Calculated 1RM for all your history",
                      onTap: () => _showPRSheet(stats['prMap']),
                    ),
                    _buildMenuTile(
                      icon: Icons.summarize_outlined,
                      title: "Monthly Progress Report",
                      subtitle: "Detailed recap of the last 30 days",
                      onTap: () => _showMonthlyReport(stats),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSection(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('weight_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150);

        var docs = List<Map<String, dynamic>>.from(snapshot.data!);
        docs.sort((a, b) => b['date'].compareTo(a['date']));

        var graphDocs = docs.length > 7 ? docs.sublist(0, 7) : docs;

        double currentWeight = docs.isNotEmpty
            ? (docs.first['weight'] as num).toDouble()
            : 0.0;
        double sum = 0;
        List<FlSpot> graphPoints = [];

        for (var i = 0; i < graphDocs.length; i++) {
          double w = (graphDocs[i]['weight'] as num).toDouble();
          sum += w;
          graphPoints.add(FlSpot((graphDocs.length - 1 - i).toDouble(), w));
        }
        double weeklyAvg = graphDocs.isNotEmpty ? sum / graphDocs.length : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _weightMetricCol(
                    "Current",
                    "${currentWeight}kg",
                    _textWhite,
                    24,
                  ),
                  _weightMetricCol(
                    "Weekly Avg",
                    "${weeklyAvg.toStringAsFixed(1)}kg",
                    _neonGreen,
                    18,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 140,
                child: docs.isEmpty
                    ? Center(
                        child: Text(
                          "Log your weight to see trends",
                          style: TextStyle(color: _textGrey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: graphPoints,
                              isCurved: true,
                              color: _neonBlue,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _neonBlue.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogWeightDialog(uid),
                  icon: const Icon(Icons.add_chart, size: 20),
                  label: const Text(
                    "Log Today's Weight",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _neonBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> docs) {
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

    for (var data in docs) {
      DateTime date = DateTime.parse(data['timestamp']);
      bool isCurrent = date.isAfter(thirtyDaysAgo);
      bool isPrevious =
          date.isAfter(sixtyDaysAgo) && date.isBefore(thirtyDaysAgo);

      if (isCurrent) {
        totalDuration += (data['duration_seconds'] as int? ?? 0) ~/ 60;
      }

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
      "topMuscle": currentMuscleCounts.entries.isNotEmpty
          ? currentMuscleCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : "None",
    };
  }

  void _showPieChartSheet(Map<String, int> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              "Set Distribution",
              style: TextStyle(
                color: _textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: data.entries.where((e) => e.value > 0).map((e) {
                    return PieChartSectionData(
                      color: _getMuscleColor(e.key),
                      value: e.value.toDouble(),
                      title: '${e.value}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: data.keys
                  .where((k) => data[k]! > 0)
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Muscle Intensity Map",
              style: TextStyle(
                color: _textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            ...sorted.map((item) {
              double percent = item.value / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.key,
                          style: TextStyle(
                            color: _textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${item.value} Sets",
                          style: TextStyle(color: _textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        color: Color.lerp(Colors.blue, Colors.red, percent),
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              "Most Frequent Exercises",
              style: TextStyle(
                color: _textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _neonBlue.withOpacity(0.2),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: _neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    sorted[index].key,
                    style: TextStyle(
                      color: _textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    "${sorted[index].value} sessions",
                    style: TextStyle(color: _textGrey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPRSheet(Map<String, double> prMap) {
    var sorted = prMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              "Strength Leaderboard (1RM)",
              style: TextStyle(
                color: _textWhite,
                fontSize: 20,
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
                    style: TextStyle(color: _textWhite),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "30-Day Training Recap",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reportLine("Total Volume:", "${stats['totalVolumeString']} kg"),
            _reportLine("Total Sets Completed:", "${stats['totalSets']}"),
            _reportLine("Time in Gym:", "${stats['totalDuration']} mins"),
            _reportLine("Primary Muscle Group:", "${stats['topMuscle']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: TextStyle(color: _neonBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(sub, style: TextStyle(color: _textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildRadarContainer(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gridColor),
      ),
      child: Column(
        children: [
          _buildRadarChart(
            stats['currentMuscleCounts'],
            stats['prevMuscleCounts'],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem("This Month", _neonBlue),
              const SizedBox(width: 25),
              _legendItem("Previous Month", Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, int> current, Map<String, int> previous) {
    final muscles = ['Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Core'];
    List<RadarEntry> getEntries(Map<String, int> data) => muscles
        .map((m) => RadarEntry(value: min((data[m] ?? 0).toDouble(), 20)))
        .toList();
    return SizedBox(
      height: 240,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: Colors.grey.withOpacity(0.1),
              borderColor: Colors.grey.withOpacity(0.4),
              entryRadius: 0,
              dataEntries: getEntries(previous),
              borderWidth: 1,
            ),
            RadarDataSet(
              fillColor: _neonBlue.withOpacity(0.2),
              borderColor: _neonBlue,
              entryRadius: 3,
              dataEntries: getEntries(current),
              borderWidth: 2,
            ),
          ],
          getTitle: (index, angle) => RadarChartTitle(text: muscles[index]),
          titleTextStyle: TextStyle(color: _textGrey, fontSize: 11),
          tickCount: 3,
          gridBorderData: BorderSide(color: _gridColor),
          tickBorderData: BorderSide(color: _gridColor),
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(int count, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _statBlock("Workouts", "$count", "Sessions", Icons.fitness_center),
        _statBlock("Time", "${stats['totalDuration']}m", "Total", Icons.timer),
        _statBlock(
          "Load",
          stats['totalVolumeString'],
          "Volume",
          Icons.bar_chart,
        ),
        _statBlock("Sets", "${stats['totalSets']}", "Completed", Icons.layers),
      ],
    );
  }

  Widget _statBlock(String t, String v, String s, IconData i) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gridColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: TextStyle(color: _textGrey, fontSize: 13)),
        const Spacer(),
        Text(
          v,
          style: TextStyle(
            color: _textWhite,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(s, style: TextStyle(color: _textGrey, fontSize: 11)),
      ],
    ),
  );

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: _textWhite, size: 28),
      title: Text(
        title,
        style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _textGrey, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: _textGrey),
      onTap: onTap,
    ),
  );

  Widget _legendItem(String t, Color c) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(t, style: TextStyle(color: _textGrey, fontSize: 12)),
    ],
  );

  Widget _weightMetricCol(String l, String v, Color c, double s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: TextStyle(color: _textGrey, fontSize: 12)),
      Text(
        v,
        style: TextStyle(color: c, fontSize: s, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _reportLine(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: _textGrey)),
        Text(
          v,
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

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
    if (name.contains("squat") ||
        name.contains("leg") ||
        name.contains("calf") ||
        name.contains("deadlift"))
      return "Legs";
    if (name.contains("curl") ||
        name.contains("tricep") ||
        name.contains("bicep") ||
        name.contains("arm"))
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

  void _showLogWeightDialog(String uid) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        title: Text("Update Weight", style: TextStyle(color: _textWhite)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _textWhite),
          decoration: const InputDecoration(hintText: "Weight in kg"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              double? w = double.tryParse(ctrl.text);
              if (w != null) {
                await _supabase.from('weight_history').insert({
                  'user_id': uid,
                  'weight': w,
                  'date': DateTime.now().toIso8601String(),
                });
                await _supabase
                    .from('users')
                    .update({'weight': w})
                    .eq('id', uid);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.bar_chart_rounded,
          size: 80,
          color: _textGrey.withOpacity(0.3),
        ),
        const SizedBox(height: 20),
        Text(
          "No Workout History Found",
          style: TextStyle(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Your stats will appear after your first session.",
          style: TextStyle(color: _textGrey),
        ),
      ],
    ),
  );
}
