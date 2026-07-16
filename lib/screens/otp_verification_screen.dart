import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitcoach_/services/auth_gate.dart';
import 'package:fitcoach_/screens/signup.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  final _supabase = Supabase.instance.client;

  void _showSnack(String message, {Color bg = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();

    if (code.length != 8) {
      _showSnack("Please enter a valid 8-digit code");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: widget.email,
        token: code,
      );

      if (res.user != null) {
        await _supabase.from('users').upsert({
          'id': res.user!.id,
          'displayName': widget.name,
          'email': widget.email,
          'phone': widget.phone,
          'profileComplete': false,
          'createdAt': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;
        _showSnack("Email verified successfully!", bg: Colors.green);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      await _supabase.auth.resend(type: OtpType.signup, email: widget.email);
      _showSnack("Verification code resent!", bg: Colors.green);
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Signup()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Check your email",
              style: TextStyle(
                color: Color(0xFFE8FF4F),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "We sent an 8-digit verification code to:\n${widget.email}",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "00000000",
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  letterSpacing: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                counterText: "",
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8FF4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Verify Account",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Didn't receive the code?",
                  style: TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: _isResending ? null : _resendOTP,
                  child: _isResending
                      ? const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8FF4F),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Resend",
                          style: TextStyle(
                            color: Color(0xFFE8FF4F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
