import 'package:fitcoach_/screens/homescreen.dart';
import 'package:fitcoach_/screens/onboarding_screens/onboarding_screen1.dart';
import 'package:fitcoach_/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(navigateAutomatically: false);
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return const SplashScreen(navigateAutomatically: true);
        }

        final user = session.user;

        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen(navigateAutomatically: false);
            }

            final userData = userSnapshot.data;

            if (userData != null) {
              final bool isComplete = userData['profileComplete'] ?? false;
              return isComplete
                  ? const Homescreen()
                  : const OnboardingScreen1();
            }

            return const OnboardingScreen1();
          },
        );
      },
    );
  }
}
