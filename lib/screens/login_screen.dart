
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/ruwa_page_header.dart';
import 'activation_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';
import '../utils/ruwa_notice.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================
  // ألوان رُوى
  // ==========================================
  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF7D8079);

  // ==========================================
  // متحكمات الحقول
  // ==========================================
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // تنسيق النصوص
  // ==========================================
  TextStyle _textStyle(
    double fontSize, {
    Color color = _dark,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      height: 1.5,
    );
  }

  // ==========================================
  // رسائل المستخدم
  // ==========================================
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: success);
  }

  // ==========================================
  // تسجيل الدخول عبر Firebase
  // ==========================================
  Future<void> _login() async {
    if (_isLoggingIn) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // التحقق من الحقول الفارغة
    if (email.isEmpty || password.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول');
      return;
    }

    // التحقق المبدئي من البريد الإلكتروني
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    // التحقق المبدئي من كلمة المرور
    if (password.length < 6) {
      _showMessage(
        'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final userCredential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // الحساب غير مفعّل
      if (!user.emailVerified) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ActivationScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // الحساب مفعّل
      final name =
          await ActivationScreen.ensureUserDocument(user);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            name: name,
            email: email,
            initialIndex: 0,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        _showMessage(
          'لا يوجد حساب بهذا البريد الإلكتروني',
        );
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showMessage(
          'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        );
      } else if (e.code == 'invalid-email') {
        _showMessage(
          'صيغة البريد الإلكتروني غير صحيحة',
        );
      } else {
        _showMessage(
          'حدث خطأ: ${e.message}',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'حدث خطأ غير متوقع، حاول مرة أخرى',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  // ==========================================
  // عناوين الحقول
  // ==========================================
  Widget _fieldLabel(String label) {
    return Text(
      label,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: _textStyle(
        14,
        weight: FontWeight.w700,
      ),
    );
  }

  // ==========================================
  // التصميم الموحد لحقول الإدخال
  // ==========================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: _textStyle(
        13,
        color: _muted,
      ),

      // الأيقونة الأساسية في جهة اليمين
      prefixIcon: Icon(
        icon,
        color: _green,
        size: 23,
      ),

      // أيقونة إظهار كلمة المرور في اليسار
      suffixIcon: trailing,

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _border,
          width: 1.2,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _green,
          width: 1.8,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: RuwaNotice.warnAccent,
          width: 1.2,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: RuwaNotice.warnAccent,
          width: 1.8,
        ),
      ),
    );
  }

  // ==========================================
  // واجهة تسجيل الدخول
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final keyboardVisible =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,

        body: Stack(
          children: [
            // ==================================
            // الزخرفة السفلية
            // ==================================
            if (!keyboardVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/bottom_decoration.png',
                    width: MediaQuery.sizeOf(context).width,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),

            // ==================================
            // محتوى الصفحة
            // ==================================
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),

                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [
                          // ==========================
                          // زر الرجوع الموحد
                          // ==========================
                          const RuwaPageHeader(),

                          const SizedBox(height: 18),

                          // ==========================
                          // شعار رُوى
                          // ==========================
                          Center(
                            child: Image.asset(
                              'assets/images/ruwa_logo.png',
                              width: 180,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // ==========================
                          // عنوان الصفحة
                          // ==========================
                          Text(
                            'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: _textStyle(
                              26,
                              weight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'مرحبًا بعودتك، سجّل دخولك للمتابعة',
                            textAlign: TextAlign.center,
                            style: _textStyle(
                              14,
                              color: _muted,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ==========================
                          // البريد الإلكتروني
                          // ==========================
                          _fieldLabel('البريد الإلكتروني'),

                          const SizedBox(height: 8),

                          TextField(
                            controller: emailController,

                            keyboardType:
                                TextInputType.emailAddress,

                            textInputAction:
                                TextInputAction.next,

                            // ترتيب البريد الإلكتروني LTR
                            textDirection: TextDirection.ltr,

                            // النص والعبارة على اليمين دائمًا
                            textAlign: TextAlign.right,

                            autocorrect: false,
                            enableSuggestions: false,

                            style: _textStyle(14),

                            decoration: _inputDecoration(
                              hint: 'أدخل بريدك الإلكتروني',
                              icon: Icons.mail_outline_rounded,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==========================
                          // كلمة المرور
                          // ==========================
                          _fieldLabel('كلمة المرور'),

                          const SizedBox(height: 8),

                          TextField(
                            controller: passwordController,

                            obscureText: obscurePassword,

                            textInputAction:
                                TextInputAction.done,

                            onSubmitted: (_) => _login(),

                            // يحافظ على ترتيب الرموز والحروف
                            textDirection: TextDirection.ltr,

                            // محاذاة ثابتة جهة اليمين
                            textAlign: TextAlign.right,

                            style: _textStyle(14),

                            decoration: _inputDecoration(
                              hint: 'أدخل كلمة المرور',
                              icon: Icons.lock_outline_rounded,

                              trailing: IconButton(
                                tooltip: obscurePassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',

                                onPressed: () {
                                  setState(() {
                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },

                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,

                                  color: _muted,
                                  size: 23,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          // ==========================
                          // نسيت كلمة المرور
                          // ==========================
                          Align(
                            alignment:
                                AlignmentDirectional.centerStart,

                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },

                              child: Text(
                                'نسيت كلمة المرور؟',

                                style: _textStyle(
                                  13,
                                  color: _green,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==========================
                          // زر تسجيل الدخول
                          // ==========================
                          SizedBox(
                            height: 52,

                            child: ElevatedButton(
                              onPressed:
                                  _isLoggingIn ? null : _login,

                              style: ElevatedButton.styleFrom(
                                elevation: 0,

                                backgroundColor: _green,

                                disabledBackgroundColor:
                                    _green.withValues(alpha: 0.7),

                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),

                              child: _isLoggingIn
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,

                                      children: [
                                        const SizedBox(
                                          width: 21,
                                          height: 21,

                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),

                                        const SizedBox(width: 11),

                                        Text(
                                          'جارٍ تسجيل الدخول...',

                                          style: _textStyle(
                                            14,
                                            color: Colors.white,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'تسجيل الدخول',

                                      style: _textStyle(
                                        16,
                                        color: Colors.white,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==========================
                          // إنشاء حساب جديد
                          // ==========================
                          Wrap(
                            alignment: WrapAlignment.center,

                            crossAxisAlignment:
                                WrapCrossAlignment.center,

                            children: [
                              Text(
                                'ليس لديك حساب؟',

                                style: _textStyle(
                                  13,
                                  color: _muted,
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,

                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },

                                child: Text(
                                  'إنشاء حساب جديد',

                                  style: _textStyle(
                                    13,
                                    color: _green,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
