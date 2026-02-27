import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- THIS WAS MISSING. ADD IT HERE. ---
  Future<bool> isProfileComplete(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['profileComplete'] ?? false;
      }
    } catch (e) {
      print("Error checking profile: $e");
    }
    return false;
  }
  // --------------------------------------

  // Sign in with Facebook only
  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw FirebaseAuthException(
        code: 'ABORTED_BY_USER',
        message: 'Facebook sign-in cancelled',
      );
    }

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw FirebaseAuthException(
        code: 'FACEBOOK_LOGIN_FAILED',
        message: 'Facebook login failed',
      );
    }

    final accessToken = result.accessToken!;
    final String token =
        (accessToken as dynamic).token ??
        (accessToken as dynamic).tokenString ??
        '';

    if (token.isEmpty) {
      throw FirebaseAuthException(
        code: 'MISSING_ACCESS_TOKEN',
        message: 'Facebook access token missing',
      );
    }

    final credential = FacebookAuthProvider.credential(token);
    final userCred = await _auth.signInWithCredential(credential);

    final user = userCred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'loginProvider': 'facebook',
        'lastSignIn': FieldValue.serverTimestamp(),
        // Don't overwrite profileComplete if it exists
      }, SetOptions(merge: true));
    }

    return userCred;
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
