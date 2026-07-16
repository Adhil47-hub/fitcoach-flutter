import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyCalendar extends StatefulWidget {
  final Function(String) onDaySelected;
  final String initialDay;

  const WeeklyCalendar({
    super.key,
    required this.onDaySelected,
    required this.initialDay,
  });

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  final _supabase = Supabase.instance.client;
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  late String _selectedDay;
  Set<String> _activeDays = {};

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    _fetchActiveDays();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDay.isNotEmpty) {
        widget.onDaySelected(widget.initialDay);
      }
    });
  }

  void _fetchActiveDays() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .from('routines')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (List<Map<String, dynamic>> data) {
            final Set<String> newActive = {};
            for (var routine in data) {
              if (routine.containsKey('day') && routine['day'] != null) {
                newActive.add(routine['day']);
              }
            }
            if (mounted) {
              setState(() => _activeDays = newActive);
            }
          },
          onError: (error) {
            debugPrint("Calendar Stream Error: $error");
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          final dayName = _days[index];
          final isSelected = dayName == _selectedDay;
          final hasWorkout = _activeDays.contains(dayName);
          final shortName = dayName.substring(0, 3).toUpperCase();

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = dayName);
              widget.onDaySelected(dayName);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2F80ED)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: isSelected
                    ? Border.all(color: const Color(0xFF56CCF2), width: 1)
                    : Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                boxShadow: (isDark || isSelected)
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shortName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (hasWorkout)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFD0FD3E)
                                  : const Color(0xFF00A86B)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Colors.white.withOpacity(0.5)
                                : (isDark
                                      ? const Color(0xFFD0FD3E).withOpacity(0.6)
                                      : Colors.transparent),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
