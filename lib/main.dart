import 'package:firebase_core/firebase_core.dart';
import 'package:fitcoach_/firebase_options.dart';

import 'package:fitcoach_/services/auth_gate.dart';
import 'package:flutter/material.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage('assets/images/splash.png'), context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // FIX: Use AuthGate instead of SplashScreen directly
      home: const AuthGate(),
    );
  }
}
