import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  // Creates users/{uid} only if it does not exist yet. Returns the user's name.
  static Future<String> ensureUserDocument(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    final fallback = user.displayName ?? 'مستخدم رُوى';
    if (doc.exists) {
      return (doc.data()?['full_name'] as String?) ?? fallback;
    }
    await ref.set({'full_name': fallback, 'email': user.email});
    return fallback;
  }

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _isChecking = false;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    // Checks automatically every 4 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkActivated(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkActivated({bool silent = false}) async {
    if (_isChecking) return;
    _isChecking = true;
    if (!silent && mounted) setState(() {});
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      await current.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _pollTimer?.cancel();
        // Refresh the token so Firestore rules see email_verified = true
        await user.getIdToken(true);
        final name = await ActivationScreen.ensureUserDocument(user);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              name: name,
              email: user.email ?? '',
              initialIndex: 0,
            ),
          ),
          (route) => false,
        );
      } else if (!silent && mounted) {
        _showMessage('لم يتم تفعيل الحساب بعد، تحقق من بريدك الإلكتروني');
      }
    } catch (e) {
      if (!silent && mounted) _showMessage('حدث خطأ، حاول مرة أخرى');
    } finally {
      _isChecking = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      _showMessage('تم إرسال رابط التفعيل مرة أخرى');
      setState(() => _cooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _cooldown--);
        if (_cooldown <= 0) t.cancel();
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.code == 'too-many-requests'
          ? 'محاولات كثيرة، انتظر قليلًا ثم حاول مرة أخرى'
          : 'تعذر إرسال الرابط');
    }
  }

  Future<void> _backToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/ruwa_logo.png',
                  height: 110, fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Icon(Icons.mark_email_unread_outlined,
                  size: 64, color: Color(0xFF315B32)),
              const SizedBox(height: 16),
              Text('فعّل حسابك',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                      color: const Color(0xFF234525),
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
                            Text(
                'تم ارسال رابط تفعيل الحساب الى',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                    color: const Color(0xFF7D8079), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: const Color(0xFF234525),
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'لم تصلك الرسالة؟ تحقق من البريد المزعج',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                    color: const Color(0xFF8A8D87), fontSize: 12),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : () => _checkActivated(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF315B32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                      _isChecking ? 'جارٍ التحقق...' : 'لقد فعّلت حسابي',
                      style: GoogleFonts.cairo(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(
                    _cooldown > 0
                        ? 'إعادة الإرسال بعد $_cooldown ثانية'
                        : 'إعادة إرسال رابط التفعيل',
                    style: GoogleFonts.cairo(
                        color: const Color(0xFF315B32),
                        fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: _backToLogin,
                child: Text('العودة إلى تسجيل الدخول',
                    style: GoogleFonts.cairo(color: const Color(0xFF7D8079))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}