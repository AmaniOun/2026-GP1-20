import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
  // إنشاء الحساب
  // ==========================================
  void _createAccount() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // التأكد من تعبئة الحقول
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول');
      return;
    }

    // التحقق المبدئي من البريد
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    // التحقق من طول كلمة المرور
    if (password.length < 6) {
      _showMessage(
        'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل',
      );
      return;
    }

    // التأكد من تطابق كلمتي المرور
    if (password != confirmPassword) {
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    // ==========================================
    // مؤقتًا:
    // ننقل الاسم والإيميل إلى MainNavigationScreen.
    //
    // initialIndex = 4
    // يعني فتح صفحة "حسابي" بعد إنشاء الحساب.
    //
    // لاحقًا سيتم ربط إنشاء الحساب
    // بـ Authentication + Database.
    // ==========================================
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
                // الزخرفة السفلية - بالخلف
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

                        SizedBox(height: 14 * scaleY),

                        // ==================================
                        // الشعار
                        // ==================================
                        Center(
                          child: Image.asset(
                            'assets/images/ruwa_logo.png',
                            width: 150 * scaleX,
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: 15 * scaleY),

                        // ==================================
                        // العنوان
                        // ==================================
                        Text(
                          'إنشاء حساب جديد',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF234525),
                            fontSize: 26 * scaleX,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 5 * scaleY),

                        Text(
                          'ابدأ رحلتك مع رُوى\nوكن جزءاً من مجتمع محبي النباتات',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF7D8079),
                            fontSize: 13.5 * scaleX,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 20 * scaleY),

                        // ==================================
                        // الاسم الكامل
                        // ==================================
                        _buildLabel(
                          'الاسم الكامل',
                          scaleX,
                        ),

                        SizedBox(height: 6 * scaleY),

                        _buildTextField(
                          controller: nameController,
                          hint: 'أدخل اسمك الكامل',
                          icon: Icons.person_outline_rounded,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          keyboardType: TextInputType.name,
                        ),

                        SizedBox(height: 16 * scaleY),

                        // ==================================
                        // البريد الإلكتروني
                        // ==================================
                        _buildLabel(
                          'البريد الإلكتروني',
                          scaleX,
                        ),

                        SizedBox(height: 6 * scaleY),

                        _buildTextField(
                          controller: emailController,
                          hint: 'أدخل بريدك الإلكتروني',
                          icon: Icons.mail_outline_rounded,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 16 * scaleY),

                        // ==================================
                        // كلمة المرور
                        // ==================================
                        _buildLabel(
                          'كلمة المرور',
                          scaleX,
                        ),

                        SizedBox(height: 6 * scaleY),

                        _buildPasswordField(
                          controller: passwordController,
                          hint: 'أدخل كلمة المرور',
                          obscureText: obscurePassword,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          onEyePressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        SizedBox(height: 16 * scaleY),

                        // ==================================
                        // تأكيد كلمة المرور
                        // ==================================
                        _buildLabel(
                          'تأكيد كلمة المرور',
                          scaleX,
                        ),

                        SizedBox(height: 6 * scaleY),

                        _buildPasswordField(
                          controller: confirmPasswordController,
                          hint: 'أعد إدخال كلمة المرور',
                          obscureText: obscureConfirmPassword,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          onEyePressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },
                        ),

                        SizedBox(height: 20 * scaleY),

                        // ==================================
                        // زر إنشاء الحساب
                        // ==================================
                        SizedBox(
                          height: 52 * scaleY,
                          child: ElevatedButton(
                            onPressed: _createAccount,

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
                                    'إنشاء الحساب',
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17 * scaleX,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 23 * scaleX,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 22 * scaleY),

                        // ==================================
                        // لديك حساب بالفعل؟
                        // ==================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟ ',
                              style: GoogleFonts.cairo(
                                color: const Color(0xFF666A64),
                                fontSize: 12 * scaleX,
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginScreen(),
                                  ),
                                );
                              },

                              child: Text(
                                'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF315B32),
                                  fontSize: 12 * scaleX,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 70 * scaleY),
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

  // ==========================================
  // عنوان الحقل
  // ==========================================
  Widget _buildLabel(
    String text,
    double scaleX,
  ) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        color: const Color(0xFF292D28),
        fontSize: 13 * scaleX,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ==========================================
  // حقل نص عادي
  // ==========================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double scaleX,
    required double scaleY,
    required TextInputType keyboardType,
  }) {
    return SizedBox(
      height: 52 * scaleY,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,

        style: GoogleFonts.cairo(
          color: const Color(0xFF234525),
          fontSize: 13 * scaleX,
        ),

        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,

          hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF8A8D87),
            fontSize: 13 * scaleX,
          ),

          suffixIcon: Icon(
            icon,
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
    );
  }

  // ==========================================
  // حقل كلمة المرور
  // ==========================================
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required double scaleX,
    required double scaleY,
    required VoidCallback onEyePressed,
  }) {
    return SizedBox(
      height: 52 * scaleY,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,

        style: GoogleFonts.cairo(
          color: const Color(0xFF234525),
          fontSize: 13 * scaleX,
        ),

        decoration: InputDecoration(
          hintText: hint,
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
            onPressed: onEyePressed,
            icon: Icon(
              obscureText
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
    );
  }
}