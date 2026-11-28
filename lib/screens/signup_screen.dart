

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/ruwa_page_header.dart';
import 'activation_screen.dart';
import 'login_screen.dart';
import '../utils/ruwa_notice.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF7D8079);
  static const Color _lightGreen = Color(0xFFE8F0E4);
  static const Color _red = RuwaNotice.warnAccent;

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isCreatingAccount = false;

  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _showErrors = false;


  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  TextStyle _style(
    double size, {
    Color color = _dark,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.5,
    );
  }

  // ==========================================
  // التنبيه العائم مثل صفحة تفاصيل النبات
  // ==========================================
  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: success);
  }

  // ==========================================
  // شروط كلمة المرور
  // ==========================================
  bool get _minLength =>
      passwordController.text.length >= 6;

  bool get _hasLetter => RegExp(
        r'[A-Za-z\u0621-\u064A]',
      ).hasMatch(passwordController.text);

  bool get _hasNumber => RegExp(
        r'[0-9\u0660-\u0669\u06F0-\u06F9]',
      ).hasMatch(passwordController.text);

  bool get _hasSymbol => RegExp(
        r'[^A-Za-z0-9\u0600-\u06FF\s]',
      ).hasMatch(passwordController.text);

  bool get _validPassword =>
      _minLength &&
      _hasLetter &&
      _hasNumber &&
      _hasSymbol;

  bool get _passwordsMatch =>
      confirmPasswordController.text.isNotEmpty &&
      passwordController.text ==
          confirmPasswordController.text;

  bool get _validEmail => RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(emailController.text.trim());

  // ==========================================
  // إنشاء الحساب - Firebase
  // ==========================================
  Future<void> _createAccount() async {
    if (_isCreatingAccount) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _showErrors = true;
        _passwordTouched = true;
        _confirmTouched = true;
      });

      _showMessage(
        'حقول غير مكتملة، يرجى تعبئة جميع الحقول',
      );
      return;
    }

    if (!_validEmail) {
      setState(() => _showErrors = true);

      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    if (!_validPassword) {
      setState(() {
        _showErrors = true;
        _passwordTouched = true;
      });

      _showMessage(
        'كلمة المرور غير مكتملة المتطلبات، '
        'يرجى استيفاء جميع الشروط',
      );
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _showErrors = true;
        _confirmTouched = true;
      });

      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isCreatingAccount = true);

    try {
      final userCredential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!
          .updateDisplayName(name);

      await userCredential.user!
          .sendEmailVerification();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ActivationScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        _showMessage(
          'هذا البريد الإلكتروني مستخدم بالفعل',
        );
      } else if (e.code == 'weak-password') {
        _showMessage('كلمة المرور ضعيفة جدًا');
      } else if (e.code == 'invalid-email') {
        _showMessage('صيغة البريد الإلكتروني غير صحيحة');
      } else {
        _showMessage('حدث خطأ: ${e.message}');
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'حدث خطأ غير متوقع، حاول مرة أخرى',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingAccount = false);
      }
    }
  }

  // ==========================================
  // عناوين الحقول
  // ==========================================
  Widget _label(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: _style(
        14,
        weight: FontWeight.w700,
      ),
    );
  }

  // ==========================================
  // تصميم الحقول
  // ==========================================
  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    bool error = false,
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: _style(13, color: _muted),
      prefixIcon: Icon(
        icon,
        color: error ? _red : _green,
        size: 23,
      ),
      suffixIcon: trailing,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: error ? _red : _border,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: error ? _red : _green,
          width: 1.8,
        ),
      ),
    );
  }

  // ==========================================
  // الحقول العادية
  // ==========================================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType type,
    bool error = false,
  }) {
    final isEmail = type == TextInputType.emailAddress;

    return TextField(
      controller: controller,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      textDirection: isEmail
          ? TextDirection.ltr
          : TextDirection.rtl,
      textAlign: TextAlign.right,
      autocorrect: !isEmail,
      enableSuggestions: !isEmail,
      style: _style(14),
      onChanged: (_) {
        if (_showErrors) setState(() {});
      },
      decoration: _decoration(
        hint: hint,
        icon: icon,
        error: error,
      ),
    );
  }

  // ==========================================
  // حقول كلمات المرور
  // ==========================================
  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onEyePressed,
    required ValueChanged<String> onChanged,
    bool error = false,
    bool last = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      textInputAction: last
          ? TextInputAction.done
          : TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onSubmitted: last
          ? (_) => _createAccount()
          : null,
      style: _style(14),
      decoration: _decoration(
        hint: hint,
        icon: Icons.lock_outline_rounded,
        error: error,
        trailing: IconButton(
          tooltip: obscure
              ? 'إظهار كلمة المرور'
              : 'إخفاء كلمة المرور',
          onPressed: onEyePressed,
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _muted,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // شروط كلمة المرور التفاعلية
  // ==========================================
  Widget _rule(String text, bool completed) {
    final untouched = !_passwordTouched;

    // Neutral grey before typing, strong green when met, red when missing.
    final Color color = untouched
        ? const Color(0xFF8A9688)
        : completed
            ? _green
            : _red;

    final bool met = !untouched && completed;

    // One single circle: empty before typing, filled green with a check when
    // met, red outline with a cross when missing.
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: met ? _green : Colors.transparent,
            shape: BoxShape.circle,
            border: met ? null : Border.all(color: color, width: 1.4),
          ),
          child: untouched
              ? null
              : Icon(
                  met ? Icons.check_rounded : Icons.close_rounded,
                  color: met ? Colors.white : color,
                  size: 13,
                ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: _style(
              12.5,
              color: untouched ? _dark : color,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Compact 2x2 grid, kept directly under the password field.
  Widget _passwordRequirements() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _rule('6 خانات على الأقل', _minLength)),
              const SizedBox(width: 10),
              Expanded(child: _rule('حرف واحد على الأقل', _hasLetter)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _rule('رقم واحد على الأقل', _hasNumber)),
              const SizedBox(width: 10),
              Expanded(child: _rule('رمز خاص (@ # !)', _hasSymbol)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // واجهة الصفحة
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final keyboardVisible =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    final nameError =
        _showErrors &&
        nameController.text.trim().isEmpty;

    final emailError =
        _showErrors && !_validEmail;

    final passwordError =
        _showErrors && !_validPassword;

    final confirmError =
        (_confirmTouched || _showErrors) &&
        confirmPasswordController.text.isNotEmpty &&
        !_passwordsMatch;

    final confirmMissing =
        _showErrors &&
        confirmPasswordController.text.isEmpty;

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
                  ),
                ),
              ),

            // ==================================
            // محتوى إنشاء الحساب
            // ==================================
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const RuwaPageHeader(),
                    const SizedBox(height: 12),

                    Center(
                      child: Image.asset(
                        'assets/images/ruwa_logo.png',
                        width: 145,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: _style(
                        25,
                        weight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'ابدأ رحلتك مع رُوى وكن جزءًا '
                      'من مجتمع محبي النباتات',
                      textAlign: TextAlign.center,
                      style: _style(
                        13,
                        color: _muted,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // الاسم الكامل
                    _label('الاسم الكامل'),
                    const SizedBox(height: 8),

                    _inputField(
                      controller: nameController,
                      hint: 'أدخل اسمك الكامل',
                      icon: Icons.person_outline_rounded,
                      type: TextInputType.name,
                      error: nameError,
                    ),

                    const SizedBox(height: 17),

                    // البريد الإلكتروني
                    _label('البريد الإلكتروني'),
                    const SizedBox(height: 8),

                    _inputField(
                      controller: emailController,
                      hint: 'أدخل بريدك الإلكتروني',
                      icon: Icons.mail_outline_rounded,
                      type: TextInputType.emailAddress,
                      error: emailError,
                    ),

                    const SizedBox(height: 17),

                    // كلمة المرور
                    _label('كلمة المرور'),
                    const SizedBox(height: 8),

                    _passwordField(
                      controller: passwordController,
                      hint: 'أدخل كلمة المرور',
                      obscure: obscurePassword,
                      error: passwordError,
                      onEyePressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                      onChanged: (_) {
                        setState(() {
                          _passwordTouched = true;
                        });
                      },
                    ),

                    const SizedBox(height: 11),
                    _passwordRequirements(),
                    const SizedBox(height: 19),

                    // تأكيد كلمة المرور
                    _label('تأكيد كلمة المرور'),
                    const SizedBox(height: 8),

                    _passwordField(
                      controller:
                          confirmPasswordController,
                      hint: 'أعد إدخال كلمة المرور',
                      obscure: obscureConfirmPassword,
                      error: confirmError || confirmMissing,
                      last: true,
                      onEyePressed: () {
                        setState(() {
                          obscureConfirmPassword =
                              !obscureConfirmPassword;
                        });
                      },
                      onChanged: (_) {
                        setState(() {
                          _confirmTouched = true;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    // زر إنشاء الحساب
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isCreatingAccount
                            ? null
                            : _createAccount,
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
                        child: _isCreatingAccount
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
                                    'جارٍ إنشاء الحساب...',
                                    style: _style(
                                      14,
                                      color: Colors.white,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'إنشاء الحساب',
                                style: _style(
                                  16,
                                  color: Colors.white,
                                  weight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 19),

                    // الانتقال إلى تسجيل الدخول
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟',
                          style: _style(
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
                                    const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'تسجيل الدخول',
                            style: _style(
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
            ),
          ],
        ),
      ),
    );
  }
}
