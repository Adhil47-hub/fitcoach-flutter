import 'package:fitcoach_/services/auth_service.dart';
import 'package:fitcoach_/services/google_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  // Added Name Controller
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reenterController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose(); // Dispose name controller
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _reenterController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
  }

  // ... (Validators remain the same, add one for name) ...
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your name';
    if (v.trim().length < 2) return 'Name too short';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  // ... other validators ...
  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your mobile number';
    var s = v.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceFirst(RegExp(r'^\+?91'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(s)) {
      return 'Enter a valid 10-digit number';
    }
    if (s.startsWith('0')) return 'Number should not start with 0';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Re-enter your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // Navigation Logic (Same as before)
  Future<void> _checkAndNavigate(User user) async {
    bool isComplete = await AuthService.instance.isProfileComplete(user.uid);
    if (!mounted) return;
    if (isComplete) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding1',
        (route) => false,
      ); // Changed to screen 1 (Gender)
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    var phone = _mobileController.text.trim().replaceAll(RegExp(r'\s+'), '');

    try {
      // 1. Create Auth User
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update Display Name in Auth (Optional but good practice)
      await cred.user?.updateDisplayName(name);
      await cred.user?.sendEmailVerification();

      // 3. Save to Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'displayName': name, // Save Name Here
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('Account created. Verification email sent.');

      // 4. Go to Onboarding Step 1 (Gender)
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding1',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // ... error handling ...
      if (mounted) _showSnack(e.message ?? 'Error', bg: Colors.red);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Social Logins (No changes needed here usually, as they get name from provider)
  Future<void> _facebookFromSignup() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final userCred = await AuthService.instance.signInWithFacebook();
      await _checkAndNavigate(userCred.user!);
    } catch (e) {
      if (mounted) _showSnack('Facebook login failed: $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleFromSignup() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final userCred = await GoogleAuthService.instance.signInWithGoogle();
      await _checkAndNavigate(userCred.user!);
    } catch (e) {
      if (mounted) _showSnack('Google login failed: $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      "Sign Up",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE8FF4F),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Create your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 35,
                      ),
                      decoration: const BoxDecoration(color: Color(0xFFB19FF4)),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- NAME FIELD ---
                            const SizedBox(height: 15),
                            const Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: _validateName,
                            ),

                            // --- EMAIL FIELD ---
                            const SizedBox(height: 20),
                            const Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: _validateEmail,
                            ),

                            // --- MOBILE FIELD ---
                            const SizedBox(height: 20),
                            const Text(
                              'Mobile Number',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\s]'),
                                ),
                                LengthLimitingTextInputFormatter(14),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: _validatePhone,
                            ),

                            // --- PASSWORD FIELDS ---
                            const SizedBox(height: 20),
                            const Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePass,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                            ),

                            const SizedBox(height: 20),
                            const Text(
                              'Re-enter Password',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _reenterController,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: _validateConfirm,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- SIGN UP BUTTON ---
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF3A3A3C,
                            ).withOpacity(0.5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- SOCIAL LOGIN SECTION ---
                    const Center(
                      child: Text(
                        "or sign up with",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: InkWell(
                            onTap: _loading ? null : _facebookFromSignup,
                            child: Image.asset("assets/icons/facebook.png"),
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: InkWell(
                            onTap: _loading ? null : _googleFromSignup,
                            child: Image.asset("assets/icons/Google.png"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Log In",
                            style: TextStyle(color: Color(0xFFE8FF4F)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
