import 'dart:async';
import 'package:flutter/material.dart';

class StretchingTimerScreen extends StatefulWidget {
  final String routineName;
  const StretchingTimerScreen({super.key, required this.routineName});

  @override
  State<StretchingTimerScreen> createState() => _StretchingTimerScreenState();
}

class _StretchingTimerScreenState extends State<StretchingTimerScreen> {
  // Dummy stretching list (AI would generate this in the future)
  final List<Map<String, dynamic>> _stretches = [
    {"name": "Cross-Body Shoulder Stretch", "duration": 30},
    {"name": "Overhead Triceps Stretch", "duration": 30},
    {"name": "Child's Pose", "duration": 45},
    {"name": "Cat-Cow Stretch", "duration": 45},
  ];

  int _currentIndex = 0;
  int _timeLeft = 30;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = _stretches[_currentIndex]["duration"];
  }

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          _nextStretch();
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _nextStretch() {
    _timer?.cancel();
    if (_currentIndex < _stretches.length - 1) {
      setState(() {
        _currentIndex++;
        _timeLeft = _stretches[_currentIndex]["duration"];
        _isRunning = false;
      });
    } else {
      // Finished Routine!
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Recovery Routine Completed!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentName = _stretches[_currentIndex]["name"];
    int totalDuration = _stretches[_currentIndex]["duration"];
    double progress = _timeLeft / totalDuration;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.routineName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Stretch ${_currentIndex + 1} of ${_stretches.length}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              currentName,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            
            // --- HUGE CIRCULAR TIMER ---
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white10,
                    color: Colors.blueAccent,
                  ),
                ),
                Text(
                  "00:${_timeLeft.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // --- CONTROLS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _startPauseTimer,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 40),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: _nextStretch,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(color: Colors.grey.shade800, shape: BoxShape.circle),
                    child: const Icon(Icons.skip_next, color: Colors.white, size: 30),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}