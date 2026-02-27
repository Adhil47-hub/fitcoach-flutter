import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final Color _bgBlack = const Color(0xFF000000);
  final Color _cardDark = const Color(0xFF1C1C1E);
  final Color _neonBlue = Colors.blueAccent;
  final Color _textGrey = Colors.grey;

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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: _neonBlue,
                labelColor: _neonBlue,
                unselectedLabelColor: Colors.grey,
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
      bottomNavigationBar: Container(
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
      ),
    );
  }

  Widget _buildSummaryTab() {
    // FIX: Safely handle missing/empty URLs from API
    String rawUrl = widget.exercise.gifUrl;
    bool hasUrl = rawUrl.isNotEmpty;

    // Only try to fix the URL if one actually exists
    String displayUrl = "";
    if (hasUrl) {
      displayUrl = rawUrl.replaceAll('https://', 'http://');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allWorkouts = snapshot.data!.docs;
        final relevantHistory = _filterHistoryForExercise(
          allWorkouts,
          widget.exercise.id,
        );
        final double maxWeight = _calculateMaxWeight(relevantHistory);
        final double oneRepMax = _calculateOneRepMax(relevantHistory);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    // SAFETY CHECK: If no URL, show Icon. If URL exists, load Image.
                    child: !hasUrl
                        ? const Icon(
                            Icons.fitness_center,
                            size: 80,
                            color: Colors.grey,
                          )
                        : CachedNetworkImage(
                            imageUrl: displayUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Target: ${widget.exercise.target}",
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Chart
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
                      ),
              ),
              const SizedBox(height: 30),

              // Stats
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final allWorkouts = snapshot.data!.docs;
        final history = _filterHistoryForExercise(
          allWorkouts,
          widget.exercise.id,
        );

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 60,
                  color: _textGrey.withOpacity(0.3),
                ),
                const SizedBox(height: 15),
                const Text(
                  "No exercise history",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final workout = history[index];
            final date = (workout['timestamp'] as Timestamp).toDate();
            final exerciseData = workout['exerciseData'];

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMM y').format(date),
                    style: const TextStyle(
                      color: Colors.white,
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
                        style: const TextStyle(color: Colors.white70),
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

  Widget _buildHowToTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.exercise.instructions.isEmpty)
            const Text(
              "No instructions available.",
              style: TextStyle(color: Colors.grey),
            )
          else
            ...widget.exercise.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${entry.key + 1}.",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
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
          const Text(
            "Community Leaderboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text("Coming Soon!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textGrey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- STAT CALCULATIONS ---
  List<Map<String, dynamic>> _filterHistoryForExercise(
    List<QueryDocumentSnapshot> docs,
    String exerciseId,
  ) {
    List<Map<String, dynamic>> history = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final exercises = data['exercises'] as List<dynamic>? ?? [];
      final matchingExercise = exercises.firstWhere(
        (ex) => ex['id'].toString() == exerciseId.toString(),
        orElse: () => null,
      );
      if (matchingExercise != null) {
        history.add({
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'exerciseData': matchingExercise,
        });
      }
    }
    return history;
  }

  double _calculateMaxWeight(List<Map<String, dynamic>> history) {
    double max = 0.0;
    for (var item in history) {
      for (var set in item['exerciseData']['sets']) {
        final weight = double.tryParse(set['weight'].toString()) ?? 0.0;
        if (weight > max) max = weight;
      }
    }
    return max;
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
    for (var item in history.reversed) {
      double sessionMax = 0.0;
      for (var set in item['exerciseData']['sets']) {
        final weight = double.tryParse(set['weight'].toString()) ?? 0.0;
        if (weight > sessionMax) sessionMax = weight;
      }
      points.add(sessionMax);
    }
    if (points.length > 10) return points.sublist(points.length - 10);
    return points;
  }
}

class CustomLineChart extends StatelessWidget {
  final List<double> dataPoints;
  const CustomLineChart({super.key, required this.dataPoints});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ChartPainter(dataPoints), child: Container());
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  _ChartPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.white;
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
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
