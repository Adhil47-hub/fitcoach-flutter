import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/models/exercise_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onAdd;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.onAdd,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  final Color _neonBlue = Colors.blueAccent;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: _bgBlack,
              expandedHeight: 40.0,
              floating: true,
              pinned: true,
              iconTheme: IconThemeData(color: _textWhite),
              title: Text(
                widget.exercise.name,
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: _neonBlue,
                labelColor: _neonBlue,
                unselectedLabelColor: _textGrey,
                isScrollable: true,
                tabs: const [
                  Tab(text: "Summary"),
                  Tab(text: "History"),
                  Tab(text: "How to"),
                  Tab(text: "Leaderboard"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildHistoryTab(),
            _buildHowToTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSummaryTab() {
    String rawUrl = widget.exercise.gifUrl;
    String displayUrl = rawUrl.replaceAll('https://', 'http://');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('workout_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', _supabase.auth.currentUser?.id ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _neonBlue));
        }

        final allHistory = snapshot.data!;
        final relevantHistory = _filterHistoryForExercise(
          allHistory,
          widget.exercise.id,
        );

        final double maxWeight = _calculateMaxWeight(relevantHistory);
        final double oneRepMax = _calculateOneRepMax(relevantHistory);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseImage(displayUrl, rawUrl.isNotEmpty),
              const SizedBox(height: 20),
              Text(
                widget.exercise.name,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Target: ${widget.exercise.target}",
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: relevantHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No history yet",
                          style: TextStyle(color: _textGrey),
                        ),
                      )
                    : CustomLineChart(
                        dataPoints: _getChartData(relevantHistory),
                        isDark: isDark,
                      ),
              ),
              const SizedBox(height: 30),
              _buildStatRow(
                "Heaviest Weight",
                "${maxWeight.toStringAsFixed(1)} kg",
              ),
              _buildStatRow("Best 1RM", "${oneRepMax.toStringAsFixed(1)} kg"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('workout_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', _supabase.auth.currentUser?.id ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _neonBlue));
        }

        final history = _filterHistoryForExercise(
          snapshot.data!,
          widget.exercise.id,
        );

        history.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        if (history.isEmpty) return _buildEmptyHistoryState();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final workout = history[index];
            final date = DateTime.parse(workout['timestamp']);
            final exerciseData = workout['exerciseData'];

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMM y').format(date),
                    style: TextStyle(
                      color: _textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...(exerciseData['sets'] as List).asMap().entries.map((
                    entry,
                  ) {
                    final set = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        "Set ${entry.key + 1}: ${set['weight']}kg x ${set['reps']}",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterHistoryForExercise(
    List<Map<String, dynamic>> docs,
    String exerciseId,
  ) {
    List<Map<String, dynamic>> history = [];
    for (var doc in docs) {
      final List<dynamic> exercises = doc['exercises'] ?? [];
      final matchingExercise = exercises.firstWhere(
        (ex) => ex['id'].toString() == exerciseId,
        orElse: () => null,
      );
      if (matchingExercise != null) {
        history.add({
          'timestamp': doc['timestamp'],
          'exerciseData': matchingExercise,
        });
      }
    }
    return history;
  }

  Widget _buildExerciseImage(String displayUrl, bool hasUrl) {
    return Center(
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: !hasUrl
              ? Icon(Icons.fitness_center, size: 80, color: _textGrey)
              : CachedNetworkImage(
                  imageUrl: displayUrl,
                  fit: BoxFit.contain,
                  placeholder: (c, u) =>
                      const Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }

  double _calculateMaxWeight(List<Map<String, dynamic>> history) {
    double maxVal = 0.0;
    for (var item in history) {
      for (var set in item['exerciseData']['sets']) {
        final weight = double.tryParse(set['weight'].toString()) ?? 0.0;
        if (weight > maxVal) maxVal = weight;
      }
    }
    return maxVal;
  }

  double _calculateOneRepMax(List<Map<String, dynamic>> history) {
    double max1RM = 0.0;
    for (var item in history) {
      for (var set in item['exerciseData']['sets']) {
        final weight = double.tryParse(set['weight'].toString()) ?? 0.0;
        final reps = double.tryParse(set['reps'].toString()) ?? 0.0;
        if (reps > 0) {
          final oneRM = weight * (1 + reps / 30);
          if (oneRM > max1RM) max1RM = oneRM;
        }
      }
    }
    return max1RM;
  }

  List<double> _getChartData(List<Map<String, dynamic>> history) {
    List<double> points = [];
    final sorted = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    for (var item in sorted) {
      double sessionMax = 0.0;
      for (var set in item['exerciseData']['sets']) {
        final weight = double.tryParse(set['weight'].toString()) ?? 0.0;
        if (weight > sessionMax) sessionMax = weight;
      }
      points.add(sessionMax);
    }
    return points.length > 10 ? points.sublist(points.length - 10) : points;
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: _bgBlack,
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            widget.onAdd();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _neonBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Add exercise",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHowToTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.exercise.instructions
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${entry.key + 1}.",
                      style: TextStyle(
                        color: _neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 20),
          Text(
            "Leaderboard",
            style: TextStyle(
              color: _textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("Coming Soon!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() => Center(
    child: Text(
      "No exercise history",
      style: TextStyle(color: _textWhite, fontSize: 18),
    ),
  );

  Widget _buildStatRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: _textGrey, fontSize: 16)),
        Text(
          v,
          style: TextStyle(
            color: _textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class CustomLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final bool isDark;
  const CustomLineChart({
    super.key,
    required this.dataPoints,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(dataPoints, isDark),
      child: Container(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  final bool isDark;
  _ChartPainter(this.points, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = isDark ? Colors.white : Colors.black87;
    final path = Path();

    double maxY = points.reduce(max);
    double minY = points.reduce(min);
    if (maxY == minY) maxY += 10;

    final widthStep =
        size.width / (points.length - 1 == 0 ? 1 : points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y =
          size.height - ((points[i] - minY) / (maxY - minY)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
