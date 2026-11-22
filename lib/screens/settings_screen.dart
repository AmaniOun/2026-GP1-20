
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF9F4);
  static const Color darkGreen = Color(0xFF234525);
  static const Color mainGreen = Color(0xFF315B32);
  static const Color softGreen = Color(0xFFE8F0E4);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // زر الرجوع
              PositionedDirectional(
                top: 16,
                start: 20,
                child: Material(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: mainGreen,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),

              // عنوان الإعدادات في منتصف الشاشة
              Center(
                child: Text(
                  'الإعدادات',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
