
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _green = Color(0xFF315B32);
  static const _dark = Color(0xFF234525);
  static const _bg = Color(0xFFFAF9F4);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  PositionedDirectional(
                    top: 55,
                    end: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/top_leaves.png',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/bottom_decoration.png',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 56,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),

                          Image.asset(
                            'assets/images/ruwa_logo.png',
                            width: 210,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 26),

                          Text(
                            'منازل أكثر خضرة، حياة أكثر سعادة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _green,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 48),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SignupScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _green,
                                backgroundColor: _bg,
                                side: const BorderSide(
                                  color: _green,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'إنشاء حساب جديد',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _dark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
