import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'welcome_screen.dart';
import 'account_information_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatefulWidget {
  final String name;
  final String email;

  const AccountScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();

    currentName = widget.name;
    currentEmail = widget.email;
  }

  // ==========================================
  // فتح صفحة معلومات الحساب
  // ==========================================
  Future<void> _openAccountInformation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountInformationScreen(
          name: currentName,
          email: currentEmail,
        ),
      ),
    );

    // إذا المستخدم ضغط "حفظ التغييرات"
    if (result != null && result is Map) {
      setState(() {
        currentName = result['name'] ?? currentName;
        currentEmail = result['email'] ?? currentEmail;
      });
    }
  }

  // ==========================================
  // تسجيل الخروج + نافذة التأكيد
  // ==========================================
  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF9F4),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          titlePadding: const EdgeInsets.fromLTRB(
            24,
            25,
            24,
            5,
          ),

          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            15,
          ),

          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),

          // ======================================
          // عنوان النافذة
          // ======================================
          title: Text(
            'تسجيل الخروج',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: const Color(0xFF234525),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ======================================
          // السؤال
          // ======================================
          content: Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: const Color(0xFF7D8079),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),

          actionsAlignment: MainAxisAlignment.center,

          actions: [
            // ======================================
            // زر إلغاء
            // ======================================
            SizedBox(
              height: 43,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                style: ButtonStyle(
                  foregroundColor: const WidgetStatePropertyAll(
                    Color(0xFF315B32),
                  ),
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFFE0EBDD);
                      }

                      if (states.contains(WidgetState.hovered)) {
                        return const Color(0xFFF0F5ED);
                      }

                      return const Color(0xFFFAF9F4);
                    },
                  ),
                  side: const WidgetStatePropertyAll(
                    BorderSide(
                      color: Color(0xFF315B32),
                      width: 1.2,
                    ),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // ======================================
            // زر نعم
            // ======================================
            SizedBox(
              height: 43,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),

                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return const Color(0xFF234525);
                      }

                      if (states.contains(WidgetState.hovered)) {
                        return const Color(0xFF3D6A3E);
                      }

                      return const Color(0xFF315B32);
                    },
                  ),

                  foregroundColor: const WidgetStatePropertyAll(
                    Colors.white,
                  ),

                  overlayColor:
                      WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white.withValues(
                          alpha: 0.10,
                        );
                      }

                      return null;
                    },
                  ),

                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  'نعم، تسجيل الخروج',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // إذا ضغط إلغاء لا نسوي أي شيء
    if (shouldLogout != true) {
      return;
    }

    if (!mounted) return;

    // ==========================================
    // يرجع إلى Welcome Screen
    // ويحذف جميع الصفحات السابقة
    // ==========================================
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scaleX = width / 360;
            final scaleY = height / 800;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),

              padding: EdgeInsets.symmetric(
                horizontal: 24 * scaleX,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 38 * scaleY),

                  // ==================================
                  // عنوان الصفحة
                  // ==================================
                  Text(
                    'حسابي',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF234525),
                      fontSize: 32 * scaleX,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 6 * scaleY),

                  Text(
                    'إدارة حسابك وتخصيص تجربتك في رُوى',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF7D8079),
                      fontSize: 14 * scaleX,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 30 * scaleY),

                  // ==================================
                  // صورة الحساب
                  // ==================================
                  Center(
                    child: Container(
                      width: 92 * scaleX,
                      height: 92 * scaleX,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0E4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: const Color(0xFF6F8F64),
                        size: 48 * scaleX,
                      ),
                    ),
                  ),

                  SizedBox(height: 14 * scaleY),

                  // ==================================
                  // اسم المستخدم
                  // ==================================
                  Text(
                    currentName,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF234525),
                      fontSize: 23 * scaleX,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 3 * scaleY),

                  // ==================================
                  // البريد الإلكتروني
                  // ==================================
                  Text(
                    currentEmail,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF7D8079),
                      fontSize: 14 * scaleX,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 30 * scaleY),

                  // ==================================
                  // معلومات الحساب
                  // ==================================
                  _buildCard(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    icon: Icons.person_outline_rounded,
                    title: 'معلومات الحساب',
                    subtitle: 'عرض وتعديل بيانات حسابك',
                    onTap: _openAccountInformation,
                  ),

                  SizedBox(height: 15 * scaleY),

                  // ==================================
                  // الإعدادات
                  // ==================================
                  _buildCard(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    subtitle: 'تخصيص التطبيق والتفضيلات',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 26 * scaleY),

                  const Divider(
                    color: Color(0xFFDCE4D8),
                    thickness: 1,
                  ),

                  SizedBox(height: 20 * scaleY),

                  // ==================================
                  // زر تسجيل الخروج
                  // ==================================
                  SizedBox(
                    height: 52 * scaleY,
                    child: ElevatedButton(
                      onPressed: _logout,

                      style: ButtonStyle(
                        elevation: const WidgetStatePropertyAll(0),

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
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      child: Text(
                        'تسجيل الخروج',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 17 * scaleX,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 28 * scaleY),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // كروت الصفحة
  // ==========================================
  Widget _buildCard({
    required double scaleX,
    required double scaleY,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 18 * scaleX,
            vertical: 18 * scaleY,
          ),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFDCE4D8),
              width: 1.2,
            ),
          ),

          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // الأيقونة
              Container(
                width: 48 * scaleX,
                height: 48 * scaleX,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E4),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF315B32),
                  size: 27 * scaleX,
                ),
              ),

              SizedBox(width: 14 * scaleX),

              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF292D28),
                        fontSize: 16 * scaleX,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 2 * scaleY),

                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF7D8079),
                        fontSize: 12 * scaleX,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8 * scaleX),

              // السهم
              Icon(
                Icons.chevron_left_rounded,
                color: const Color(0xFF315B32),
                size: 27 * scaleX,
              ),
            ],
          ),
        ),
      ),
    );
  }
}