import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const RuwaApp());
}

class RuwaApp extends StatelessWidget {
  const RuwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF9F4),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // بعد 4 ثوانٍ ينتقل تلقائيًا إلى صفحة الترحيب
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),

          // الصفحة التي ستظهر بعد الـ Splash
          pageBuilder: (context, animation, secondaryAnimation) {
            return const WelcomeScreen();
          },

          // حركة الانتقال الناعمة
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // التصميم الأصلي في Figma هو 360 × 800
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scaleX = width / 360;
            final scaleY = height / 800;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // الأوراق العلوية
                Positioned(
                  left: 0,
                  top: 102 * scaleY,
                  child: Image.asset(
                    'assets/images/top_leaves.png',
                    width: 124 * scaleX,
                    fit: BoxFit.contain,
                  ),
                ),

                // الشعار
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

                // العبارة
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

                // الزخرفة السفلية
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