import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/screens/workout/ai_generate_screen.dart';
import 'package:fitcoach_/screens/workout/routines_screen.dart';
import 'package:fitcoach_/widgets/weekly_calender.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitcoach_/screens/workout/active_workout_screen.dart';

class WorkoutMenuScreen extends StatefulWidget {
  const WorkoutMenuScreen({super.key});

  @override
  State<WorkoutMenuScreen> createState() => _WorkoutMenuScreenState();
}

class _WorkoutMenuScreenState extends State<WorkoutMenuScreen> {
  final _supabase = Supabase.instance.client;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  final Color _neonGreen = const Color(0xFF00E676);
  final Color _neonBlue = const Color(0xFF2F80ED);

  String _selectedDay = DateFormat('EEEE').format(DateTime.now());

  List<Map<String, dynamic>> _routines = [];
  bool _isLoading = true;
  Key _calendarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase
        .from('routines')
        .select()
        .eq('user_id', user.id);

    if (mounted) {
      setState(() {
        _routines = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
        _calendarKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _bgBlack,
        body: Center(
          child: Text("Please Login", style: TextStyle(color: _textWhite)),
        ),
      );
    }

    final dailyRoutines = _routines
        .where((r) => r['day'] == _selectedDay)
        .toList();

    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
        title: Text(
          "Workouts",
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "My Routines",
                    icon: Icons.list_alt,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoutinesScreen(),
                        ),
                      ).then((_) => _loadRoutines());
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionButton(
                    label: "AI Generator",
                    icon: Icons.auto_awesome,
                    color: _neonGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiGenerateScreen(),
                        ),
                      ).then((_) => _loadRoutines());
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Text(
              "Weekly Schedule",
              style: TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          WeeklyCalendar(
            key: _calendarKey,
            initialDay: _selectedDay,
            onDaySelected: (day) {
              setState(() => _selectedDay = day);
            },
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _neonYellow))
                : dailyRoutines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: dailyRoutines.length,
                    itemBuilder: (context, index) {
                      return _buildWorkoutCard(dailyRoutines[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> data) {
    String title = data['title'] ?? "Workout";
    List exercises = data['exercises'] ?? [];
    int duration = exercises.length * 4;

    String subtitle = "";
    if (exercises.isNotEmpty) {
      Set<String> targets = {};
      for (var ex in exercises) {
        if (ex['target'] != null) {
          targets.add(ex['target'].toString().split(' ')[0].toUpperCase());
        }
      }
      subtitle = targets.take(3).join(" • ");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: _textGrey),
                color: _cardDark,
                onSelected: (value) {
                  if (value == 'reschedule') {
                    _showRescheduleDialog(data['id'].toString(), _selectedDay);
                  }
                  if (value == 'delete') _deleteWorkout(data['id'].toString());
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reschedule',
                    child: Text(
                      "Reschedule",
                      style: TextStyle(color: _textWhite),
                    ),
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
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: _neonBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.fitness_center, size: 14, color: _textGrey),
              const SizedBox(width: 5),
              Text(
                "${exercises.length} Exercises",
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
              const SizedBox(width: 15),
              Icon(Icons.timer, size: 14, color: _textGrey),
              const SizedBox(width: 5),
              Text(
                "~$duration Mins",
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveWorkoutScreen(
                    routineTitle: title,
                    exercises: exercises,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "START NOW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.spa, size: 60, color: _textGrey),
          const SizedBox(height: 20),
          Text(
            "Rest Day",
            style: TextStyle(
              color: _textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "No workout scheduled for $_selectedDay",
            style: TextStyle(color: _textGrey),
          ),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () => _showAssignRoutineSheet(),
            icon: Icon(Icons.list_alt, color: _textWhite),
            label: Text(
              "Choose from My Routines",
              style: TextStyle(color: _textWhite),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _neonBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoutineSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final availableRoutines = _routines
            .where((r) => r['day'] != _selectedDay)
            .toList();

        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            children: [
              Text(
                "Schedule for $_selectedDay",
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Select a routine to assign to this day.",
                style: TextStyle(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: availableRoutines.isEmpty
                    ? Center(
                        child: Text(
                          "No other routines available.\nCreate one in 'My Routines'.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textGrey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableRoutines.length,
                        itemBuilder: (context, index) {
                          final data = availableRoutines[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                data['title'] ?? "Workout",
                                style: TextStyle(
                                  color: _textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                data['day'] ?? "Unscheduled",
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.blueAccent,
                              ),
                              onTap: () async {
                                Navigator.pop(context);

                                await _supabase
                                    .from('routines')
                                    .update({'day': _selectedDay})
                                    .eq('id', data['id']);

                                if (mounted) {
                                  await _loadRoutines();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Scheduled for $_selectedDay",
                                      ),
                                      backgroundColor: _neonBlue,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRescheduleDialog(String routineId, String currentDay) {
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
                "Reschedule Workout",
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
                            Navigator.pop(context);

                            await _supabase
                                .from('routines')
                                .update({'day': day})
                                .eq('id', routineId);

                            if (mounted) {
                              await _loadRoutines();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Moved to $day"),
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
            title: Text("Delete Workout?", style: TextStyle(color: _textWhite)),
            content: Text(
              "This cannot be undone.",
              style: TextStyle(color: _textGrey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: TextStyle(color: _textWhite)),
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
      if (mounted) {
        await _loadRoutines();
      }
    }
  }
}
