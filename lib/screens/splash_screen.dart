import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/welcomescreens/welcomescreen1.dart';

class SplashScreen extends StatefulWidget {
  final bool navigateAutomatically;

  const SplashScreen({super.key, this.navigateAutomatically = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Add a flag to ensure we don't navigate twice
  bool _hasStartedNavigation = false;

  @override
  void initState() {
    super.initState();
    // Check immediately on creation
    _checkAndNavigate();
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check again if the widget parameters changed (e.g. false -> true)
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    // If automatic navigation is on, AND we haven't started the timer yet...
    if (widget.navigateAutomatically && !_hasStartedNavigation) {
      _startTimer();
    }
  }

  void _startTimer() async {
    _hasStartedNavigation = true; // Mark as started so we don't loop

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Welcomescreen1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B0B0B),
      body: Center(
        child: Image(image: AssetImage('assets/images/splash.png'), width: 180),
      ),
    );
  }
}
