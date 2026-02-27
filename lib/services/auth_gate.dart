import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcoach_/screens/homescreen.dart';
import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen1.dart';
import 'package:fitcoach_/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debug print
        // print("Auth State: ${snapshot.connectionState}, User: ${snapshot.data?.uid}");

        // 1. Waiting for Auth Status -> Show Static Splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(navigateAutomatically: false);
        }

        // 2. User is NOT logged in -> Show Active Splash (navigates to Welcome)
        if (!snapshot.hasData) {
          return const SplashScreen(navigateAutomatically: true);
        }

        // 3. User IS logged in -> Check Firestore for Profile Completion
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Waiting for Firestore -> Show Static Splash
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen(navigateAutomatically: false);
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              final bool isComplete = userData?['profileComplete'] ?? false;

              if (isComplete) {
                return const Homescreen();
              } else {
                return const OnboardingScreen1();
              }
            }

            // Fallback if no user doc found -> Start Onboarding
            // This handles the case where a user is in Auth but not in Firestore
            return const OnboardingScreen1();
          },
        );
      },
    );
  }
}
