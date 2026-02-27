import 'dart:ui';
import 'package:fitcoach_/screens/login.dart';
import 'package:flutter/material.dart';

class Welcomescreen2 extends StatefulWidget {
  const Welcomescreen2({super.key});

  @override
  State<Welcomescreen2> createState() => _Welcomescreen2State();
}

class _Welcomescreen2State extends State<Welcomescreen2> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.95,
            child: const Image(
              image: AssetImage("assets/images/welcome.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.9),
                      BlendMode.srcATop,
                    ),
                    child: const Image(
                      image: AssetImage('assets/images/welcome2.png'),
                      height: 230,
                      width: 230,
                    ),
                  ),
                ),

                const Image(
                  image: AssetImage('assets/images/welcome2.png'),
                  height: 230,
                  width: 230,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
