import 'package:flutter/material.dart';
import 'package:fitcoach_/screens/welcomescreens/welcomescreen1.dart';

class SplashScreen extends StatefulWidget {
  final bool navigateAutomatically;

  const SplashScreen({super.key, this.navigateAutomatically = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasStartedNavigation = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (widget.navigateAutomatically && !_hasStartedNavigation) {
      _startTimer();
    }
  }

  void _startTimer() async {
    _hasStartedNavigation = true;

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
