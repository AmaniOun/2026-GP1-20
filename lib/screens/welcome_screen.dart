import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scaleX = width / 360;
            final scaleY = height / 800;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ==========================================
                // الأوراق العلوية
                // ==========================================
                Positioned(
                  left: 0,
                  top: 102 * scaleY,
                  child: Image.asset(
                    'assets/images/top_leaves.png',
                    width: 124 * scaleX,
                    fit: BoxFit.contain,
                  ),
                ),

                // ==========================================
                // الشعار
                // ==========================================
                Positioned(
                  left: 0,
                  right: 0,
                  top: 335 * scaleY,
                  child: Center(
                    child: Image.asset(
                      'assets/images/ruwa_logo.png',
                      width: 205 * scaleX,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ==========================================
                // العبارة
                // ==========================================
                Positioned(
                  left: 20 * scaleX,
                  right: 20 * scaleX,
                  top: 492 * scaleY,
                  child: Text(
                    'منازل أكثر خضرة، حياة أكثر سعادة',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF315B32),
                      fontSize: 15 * scaleX,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ),

                // ==========================================
                // الأزرار
                // ==========================================
                Positioned(
                  left: 24 * scaleX,
                  right: 24 * scaleX,
                  top: 550 * scaleY,
                  child: Column(
                    children: [
                      // ====================================
                      // زر تسجيل الدخول
                      // ====================================
                      SizedBox(
                        width: double.infinity,
                        height: 50 * scaleY,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                                ),
                                 );
                                 },

                          style: ButtonStyle(
                            elevation:
                                const WidgetStatePropertyAll(0),

                            // اللون الطبيعي + Hover + Pressed
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                              (states) {
                                // عند الضغط بالماوس أو اللمس
                                if (states.contains(
                                  WidgetState.pressed,
                                )) {
                                  return const Color(0xFF234525);
                                }

                                // عند مرور الماوس
                                if (states.contains(
                                  WidgetState.hovered,
                                )) {
                                  return const Color(0xFF3D6A3E);
                                }

                                // اللون الطبيعي
                                return const Color(0xFF315B32);
                              },
                            ),

                            foregroundColor:
                                const WidgetStatePropertyAll(
                              Colors.white,
                            ),

                            // تأثير بسيط أثناء الضغط
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

                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: 20 * scaleX,
                              ),
                            ),

                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                          ),

                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'تسجيل الدخول',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15 * scaleX,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 22 * scaleX,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 14 * scaleY),

                      // ====================================
                      // زر إنشاء حساب جديد
                      // ====================================
                      SizedBox(
                        width: double.infinity,
                        height: 50 * scaleY,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                                ),
                                );
                                },

                          style: ButtonStyle(
                            elevation:
                                const WidgetStatePropertyAll(0),

                            // لون خلفية الزر حسب حالته
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                              (states) {
                                // عند الضغط
                                if (states.contains(
                                  WidgetState.pressed,
                                )) {
                                  return const Color(0xFFE8F0E4);
                                }

                                // عند مرور الماوس
                                if (states.contains(
                                  WidgetState.hovered,
                                )) {
                                  return const Color(0xFFF0F4ED);
                                }

                                // اللون الطبيعي
                                return Colors.transparent;
                              },
                            ),

                            // لون النص والسهم
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(
                                  WidgetState.pressed,
                                )) {
                                  return const Color(0xFF234525);
                                }

                                return const Color(0xFF315B32);
                              },
                            ),

                            // الإطار الأخضر
                            side: WidgetStateProperty.resolveWith<
                                BorderSide>(
                              (states) {
                                if (states.contains(
                                  WidgetState.pressed,
                                )) {
                                  return const BorderSide(
                                    color: Color(0xFF234525),
                                    width: 1.7,
                                  );
                                }

                                return const BorderSide(
                                  color: Color(0xFF315B32),
                                  width: 1.5,
                                );
                              },
                            ),

                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(
                                  WidgetState.pressed,
                                )) {
                                  return const Color(0x14315B32);
                                }

                                return null;
                              },
                            ),

                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: 20 * scaleX,
                              ),
                            ),

                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                          ),

                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'إنشاء حساب جديد',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15 * scaleX,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 22 * scaleX,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // الزخرفة السفلية
                // ==========================================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/bottom_decoration.png',
                    width: width,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
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