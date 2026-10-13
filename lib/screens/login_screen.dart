import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // إظهار رسالة للمستخدم
  // ==========================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // تسجيل الدخول
  // ==========================================
  Future<void> _login() async {
    if (_isLoggingIn) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    // إذا كانت الحقول فارغة
    if (email.isEmpty || password.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول');
      return;
    }
    // التحقق المبدئي من البريد
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
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // جلب الاسم الحقيقي من Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final name = (doc.data()?['full_name'] as String?) ?? 'مستخدم رُوى';
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            name: name,
            email: email,
            initialIndex: 4,
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        _showMessage('لا يوجد حساب بهذا البريد الإلكتروني');
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showMessage('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else if (e.code == 'invalid-email') {
        _showMessage('صيغة البريد الإلكتروني غير صحيحة');
      } else {
        _showMessage('حدث خطأ: ${e.message}');
      }
    } catch (e) {
      if (mounted) _showMessage('حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scaleX = width / 360;
            final scaleY = height / 800;
            return Stack(
              children: [
                // ==========================================
                // الزخرفة السفلية
                // ==========================================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/bottom_decoration.png',
                      width: width,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // ==========================================
                // محتوى الصفحة
                // ==========================================
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 24 * scaleX,
                    right: 24 * scaleX,
                    top: 18 * scaleY,
                    bottom: 35 * scaleY,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: height - (53 * scaleY),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==================================
                        // زر الرجوع
                        // ==================================
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.arrow_back,
                              color: const Color(0xFF315B32),
                              size: 28 * scaleX,
                            ),
                          ),
                        ),
                        SizedBox(height: 28 * scaleY),
                        // ==================================
                        // الشعار
                        // ==================================
                        Center(
                          child: Image.asset(
                            'assets/images/ruwa_logo.png',
                            width: 190 * scaleX,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 27 * scaleY),
                        // ==================================
                        // العنوان
                        // ==================================
                        Text(
                          'تسجيل الدخول',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF234525),
                            fontSize: 27 * scaleX,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5 * scaleY),
                        // ==================================
                        // النص الترحيبي
                        // ==================================
                        Text(
                          'مرحباً بعودتك،\nسجل دخولك للمتابعة',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF7D8079),
                            fontSize: 14 * scaleX,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 23 * scaleY),
                        // ==================================
                        // البريد الإلكتروني
                        // ==================================
                        Text(
                          'البريد الإلكتروني',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF315B32),
                            fontSize: 13 * scaleX,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6 * scaleY),
                        SizedBox(
                          height: 52 * scaleY,
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF234525),
                              fontSize: 13 * scaleX,
                            ),
                            decoration: InputDecoration(
                              hintText: 'أدخل بريدك الإلكتروني',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: GoogleFonts.cairo(
                                color: const Color(0xFF8A8D87),
                                fontSize: 13 * scaleX,
                              ),
                              suffixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: const Color(0xFF315B32),
                                size: 24 * scaleX,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * scaleX,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDCE4D8),
                                  width: 1.3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF315B32),
                                  width: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 17 * scaleY),
                        // ==================================
                        // كلمة المرور
                        // ==================================
                        Text(
                          'كلمة المرور',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF315B32),
                            fontSize: 13 * scaleX,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6 * scaleY),
                        SizedBox(
                          height: 52 * scaleY,
                          child: TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF234525),
                              fontSize: 13 * scaleX,
                            ),
                            decoration: InputDecoration(
                              hintText: 'أدخل كلمة المرور',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: GoogleFonts.cairo(
                                color: const Color(0xFF8A8D87),
                                fontSize: 13 * scaleX,
                              ),
                              // القفل على اليمين
                              suffixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: const Color(0xFF315B32),
                                size: 25 * scaleX,
                              ),
                              // العين على اليسار
                              prefixIcon: IconButton(
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
                                  color: const Color(0xFF8A8D87),
                                  size: 23 * scaleX,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * scaleX,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDCE4D8),
                                  width: 1.3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF315B32),
                                  width: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4 * scaleY),
                        // ==================================
                        // نسيت كلمة المرور؟
                        // ==================================
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: 5 * scaleY,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'نسيت كلمة المرور؟',
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF315B32),
                                fontSize: 13 * scaleX,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 18 * scaleY),
                        // ==================================
                        // زر تسجيل الدخول
                        // ==================================
                        SizedBox(
                          height: 52 * scaleY,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : _login,
                            style: ButtonStyle(
                              elevation:
                                  const WidgetStatePropertyAll(0),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(
                                    WidgetState.pressed,
                                  )) {
                                    return const Color(0xFF234525);
                                  }
                                  if (states.contains(
                                    WidgetState.hovered,
                                  )) {
                                    return const Color(0xFF3D6A3E);
                                  }
                                  return const Color(0xFF315B32);
                                },
                              ),
                              foregroundColor:
                                  const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              overlayColor:
                                  WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(
                                    WidgetState.pressed,
                                  )) {
                                    return Colors.white.withValues(
                                      alpha: 0.10,
                                    );
                                  }
                                  return null;
                                },
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Text(
                                    _isLoggingIn
                                        ? 'جارٍ تسجيل الدخول...'
                                        : 'تسجيل الدخول',
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17 * scaleX,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _isLoggingIn
                                      ? SizedBox(
                                          width: 22 * scaleX,
                                          height: 22 * scaleX,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_back,
                                          size: 23 * scaleX,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 26 * scaleY),
                        // ==================================
                        // إنشاء حساب جديد
                        // ==================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              'ليس لديك حساب؟ ',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF333333),
                                fontSize: 12 * scaleX,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SignupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'إنشاء حساب جديد',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF315B32),
                                  fontSize: 12 * scaleX,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 65 * scaleY),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
