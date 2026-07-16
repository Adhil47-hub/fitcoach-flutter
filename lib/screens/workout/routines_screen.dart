import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/screens/workout/ai_generate_screen.dart';
import 'package:fitcoach_/screens/workout/create_routine_screen.dart';
import 'package:fitcoach_/screens/workout/routine_detail_screen.dart';
import 'package:flutter/material.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _supabase = Supabase.instance.client;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;

  final Color _neonBlue = const Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
        title: Text(
          "My Routines",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _textWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('routines')
            .stream(primaryKey: ['id'])
            .eq('user_id', user?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Database Error: Your daily Supabase free tier limit might have been reached, or permissions are blocked.\n\nError details: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _neonBlue));
          }

          final List<Map<String, dynamic>> routines = snapshot.data ?? [];

          routines.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

          if (routines.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              return _buildRoutineCard(routines[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 60,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            "No Routines Yet",
            style: TextStyle(
              color: _textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Create a plan to get started.",
            style: TextStyle(color: _textGrey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiGenerateScreen()),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              "Generate with AI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Map<String, dynamic> data) {
    String title = data['title'] ?? "Workout";
    String day = data['day'] ?? "Unscheduled";
    List exercises = data['exercises'] ?? [];
    String routineId = data['id'].toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineDetailScreen(
              routineId: routineId,
              routineTitle: title,
              routineData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$day • ${exercises.length} Exercises",
                    style: TextStyle(color: _neonBlue, fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: _textGrey),
              color: _cardDark,
              onSelected: (value) {
                if (value == 'schedule') _showScheduleDialog(routineId, day);
                if (value == 'delete') _deleteWorkout(routineId);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'schedule',
                  child: Text("Schedule", style: TextStyle(color: _textWhite)),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(String routineId, String currentDay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final days = [
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
          "Saturday",
          "Sunday",
          "Unscheduled",
        ];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Schedule Routine",
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: days
                      .map(
                        (day) => ListTile(
                          title: Text(
                            day,
                            style: TextStyle(
                              color: day == currentDay ? _textGrey : _textWhite,
                            ),
                          ),
                          trailing: day == currentDay
                              ? Icon(Icons.check, color: _textGrey)
                              : null,
                          onTap: () async {
                            await _supabase
                                .from('routines')
                                .update({'day': day})
                                .eq('id', routineId);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    day == "Unscheduled"
                                        ? "Removed from schedule"
                                        : "Scheduled for $day",
                                  ),
                                  backgroundColor: _neonBlue,
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteWorkout(String routineId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cardDark,
            title: Text("Delete Routine?", style: TextStyle(color: _textWhite)),
            content: Text(
              "This cannot be undone.",
              style: TextStyle(color: _textGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: TextStyle(color: _textGrey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _supabase.from('routines').delete().eq('id', routineId);
    }
  }
}
