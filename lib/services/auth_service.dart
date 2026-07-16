import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isProfileComplete(String uid) async {
    try {
      final data = await _supabase
          .from('users')
          .select('profileComplete')
          .eq('id', uid)
          .maybeSingle();

      if (data != null) {
        return data['profileComplete'] ?? false;
      }
    } catch (e) {
      print("Error checking profile: $e");
    }
    return false;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.adhil.fitcoach://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Google Web OAuth Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
