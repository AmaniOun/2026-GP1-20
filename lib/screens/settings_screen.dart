import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Settings page. It uses the same header as the other Ruwa pages
/// (sage back button on the right + page title at the top).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _background = Color(0xFFFAF9F4);
  static const Color _darkGreen = Color(0xFF234525);
  static const Color _green = Color(0xFF315B32);
  static const Color _lightSage = Color(0xFFE8F0E4);
  static const Color _muted = Color(0xFF656E62);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: _background,
          surfaceTintColor: _background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          title: Text(
            'الإعدادات',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: _darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _lightSage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _green,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _lightSage,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: _green,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'لا توجد إعدادات متاحة حالياً',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
