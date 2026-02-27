import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    // 1. Initialize local state immediately
    _selectedDay = widget.initialDay;
    _fetchActiveDays();

    // 2. THE FIX: Wait for the build to finish before notifying parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDay.isNotEmpty) {
        widget.onDaySelected(widget.initialDay);
      }
    });
  }

  void _fetchActiveDays() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('routines')
        .snapshots()
        .listen((snapshot) {
          final Set<String> newActive = {};
          for (var doc in snapshot.docs) {
            if (doc.data().containsKey('day')) {
              newActive.add(doc['day']);
            }
          }
          if (mounted) {
            setState(() => _activeDays = newActive);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF0F0F10),
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
                    : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(15),
                border: isSelected
                    ? Border.all(color: const Color(0xFF56CCF2), width: 1)
                    : Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shortName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
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
                            : const Color(0xFFD0FD3E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD0FD3E).withOpacity(0.6),
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
