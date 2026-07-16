import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _supabase = Supabase.instance.client;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bgBlack => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardDark => Theme.of(context).cardColor;
  Color get _textWhite => isDark ? Colors.white : Colors.black;
  Color get _textGrey => isDark ? Colors.grey : Colors.black54;
  Color get _dividerColor => isDark ? Colors.white12 : Colors.black12;
  Color get _neonYellow =>
      isDark ? const Color(0xFFD0FD3E) : const Color(0xFF00A86B);

  bool _isLoading = true;
  bool _workoutReminders = true;
  bool _mealReminders = true;
  bool _waterReminders = true;
  bool _stepReminders = true;
  bool _communityAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutReminders = prefs.getBool('workout_reminders') ?? true;
      _mealReminders = prefs.getBool('meal_reminders') ?? true;
      _waterReminders = prefs.getBool('water_reminders') ?? true;
      _stepReminders = prefs.getBool('step_reminders') ?? true;
      _communityAlerts = prefs.getBool('community_alerts') ?? true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textWhite),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _neonYellow))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Reminders",
                      style: TextStyle(
                        color: _neonYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildToggle(
                            "Workout Reminders",
                            "Daily reminder to exercise",
                            _workoutReminders,
                            (val) async {
                              setState(() => _workoutReminders = val);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('workout_reminders', val);

                              if (val) {
                                await NotificationManager.instance
                                    .scheduleWorkoutReminder();
                              } else {
                                await NotificationManager.instance
                                    .cancelNotification(201);
                              }
                            },
                          ),
                          _buildDivider(),
                          _buildToggle(
                            "Meal Reminders",
                            "Breakfast, Lunch, and Dinner alerts",
                            _mealReminders,
                            (val) async {
                              setState(() => _mealReminders = val);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('meal_reminders', val);

                              if (val) {
                                await NotificationManager.instance
                                    .scheduleMealReminders();
                              } else {
                                await NotificationManager.instance
                                    .cancelNotification(101);
                                await NotificationManager.instance
                                    .cancelNotification(102);
                                await NotificationManager.instance
                                    .cancelNotification(103);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Goal Alerts",
                      style: TextStyle(
                        color: _neonYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildToggle(
                            "Water Goal",
                            "Notify when hydration goal is met",
                            _waterReminders,
                            (val) async {
                              setState(() => _waterReminders = val);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('water_reminders', val);
                            },
                          ),
                          _buildDivider(),
                          _buildToggle(
                            "Step Goal",
                            "Notify when 10,000 steps are reached",
                            _stepReminders,
                            (val) async {
                              setState(() => _stepReminders = val);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('step_reminders', val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Social & Community",
                      style: TextStyle(
                        color: _neonYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _buildToggle(
                        "Community Alerts",
                        "Likes, comments, and new followers",
                        _communityAlerts,
                        (val) async {
                          setState(() => _communityAlerts = val);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('community_alerts', val);
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await NotificationManager.instance
                              .sendTestNotification();

                          final user = _supabase.auth.currentUser;
                          if (user != null) {
                            try {
                              await _supabase.from('notifications').insert({
                                'user_id': user.id,
                                'title': 'Test ✅',
                                'body': 'Notifications are working perfectly!',
                                'type': 'system',
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Test notification sent & saved to inbox!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("Error saving to inbox: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving to inbox: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You must be logged in to save to inbox.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.notifications_active,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Test Notifications",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _neonYellow,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: isDark ? Colors.black : Colors.white,
            activeTrackColor: _neonYellow,
            inactiveThumbColor: isDark ? Colors.grey : Colors.grey.shade400,
            inactiveTrackColor: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(color: _dividerColor, height: 1, indent: 15, endIndent: 15);
}
