
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/ruwa_page_header.dart';
import '../utils/ruwa_notice.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  // ==========================================
  // ألوان رُوى
  // ==========================================
  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF7D8079);

  // ==========================================
  // متحكم البريد الإلكتروني
  // ==========================================
  final TextEditingController emailController =
      TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    emailController.dispose();
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
  // إظهار الرسائل للمستخدم
  // ==========================================
  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: success);
  }

  // ==========================================
  // إرسال رابط إعادة تعيين كلمة المرور
  // ==========================================
  Future<void> _sendResetLink() async {
    // منع إرسال طلبين في الوقت نفسه
    if (_isSending) return;

    final email = emailController.text.trim();

    // التأكد من تعبئة البريد
    if (email.isEmpty) {
      _showMessage('يرجى إدخال البريد الإلكتروني');
      return;
    }

    // التحقق المبدئي من البريد
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    // إظهار حالة التحميل
    setState(() => _isSending = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'تم إرسال رابط إعادة التعيين إلى بريدك',
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        _showMessage(
          'لا يوجد حساب بهذا البريد الإلكتروني',
        );
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
        setState(() => _isSending = false);
      }
    }
  }

  // ==========================================
  // تصميم حقل البريد الإلكتروني
  // ==========================================
  InputDecoration _emailDecoration() {
    return InputDecoration(
      hintText: 'أدخل بريدك الإلكتروني',

      // اتجاه عبارة التلميح عربي
      hintTextDirection: TextDirection.rtl,

      hintStyle: _textStyle(
        13,
        color: _muted,
      ),

      // الأيقونة على يمين الحقل
      prefixIcon: const Icon(
        Icons.mail_outline_rounded,
        color: _green,
        size: 23,
      ),

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
  // واجهة الصفحة
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
            // المحتوى
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
                          // شريط الرجوع الموحد
                          // ==========================
                          const RuwaPageHeader(),

                          const SizedBox(height: 45),

                          // ==========================
                          // شعار رُوى
                          // ==========================
                          Center(
                            child: Image.asset(
                              'assets/images/ruwa_logo.png',
                              width: 185,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 34),

                          // ==========================
                          // عنوان الصفحة
                          // ==========================
                          Text(
                            'نسيت كلمة المرور؟',
                            textAlign: TextAlign.center,
                            style: _textStyle(
                              26,
                              weight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==========================
                          // وصف الصفحة
                          // ==========================
                          Text(
                            'أدخل بريدك الإلكتروني وسنرسل لك '
                            'رابطًا لإعادة تعيين كلمة المرور.',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: _textStyle(
                              14,
                              color: _muted,
                            ),
                          ),

                          const SizedBox(height: 34),

                          // ==========================
                          // عنوان البريد الإلكتروني
                          // ==========================
                          Text(
                            'البريد الإلكتروني',
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: _textStyle(
                              14,
                              weight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ==========================
                          // حقل البريد الإلكتروني
                          // ==========================
                          TextField(
                            controller: emailController,

                            keyboardType:
                                TextInputType.emailAddress,

                            textInputAction:
                                TextInputAction.done,

                            // يحافظ على ترتيب رموز البريد
                            textDirection: TextDirection.ltr,

                            // محاذاة ثابتة إلى اليمين
                            textAlign: TextAlign.right,

                            autocorrect: false,
                            enableSuggestions: false,

                            onSubmitted: (_) {
                              if (!_isSending) {
                                _sendResetLink();
                              }
                            },

                            style: _textStyle(14),

                            decoration: _emailDecoration(),
                          ),

                          const SizedBox(height: 26),

                          // ==========================
                          // زر إرسال رابط الاستعادة
                          // ==========================
                          SizedBox(
                            height: 52,

                            child: ElevatedButton(
                              onPressed: _isSending
                                  ? null
                                  : _sendResetLink,

                              style: ElevatedButton.styleFrom(
                                elevation: 0,

                                backgroundColor: _green,

                                disabledBackgroundColor:
                                    _green.withValues(
                                  alpha: 0.7,
                                ),

                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),

                              child: _isSending
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
                                          'جارٍ إرسال الرابط...',
                                          style: _textStyle(
                                            14,
                                            color: Colors.white,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'إرسال رابط إعادة التعيين',
                                      style: _textStyle(
                                        16,
                                        color: Colors.white,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==========================
                          // العودة إلى تسجيل الدخول
                          // ==========================
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              child: Text(
                                'العودة إلى تسجيل الدخول',
                                textAlign: TextAlign.center,
                                style: _textStyle(
                                  14,
                                  color: _green,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
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
