import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF9F4);
  static const Color darkGreen = Color(0xFF234525);
  static const Color mainGreen = Color(0xFF315B32);
  static const Color softGreen = Color(0xFFE8F0E4);
  static const Color borderColor = Color(0xFFDCE4D8);
  static const Color grayText = Color(0xFF7D8079);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // تصميم المشروع الأساسي 360 × 800
            final scaleX = width / 360;
            final scaleY = height / 800;

            return Column(
              children: [
                // ==========================================
                // محتوى الصفحة
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),

                    padding: EdgeInsets.only(
                      left: 24 * scaleX,
                      right: 24 * scaleX,
                      top: 26 * scaleY,
                      bottom: 25 * scaleY,
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
                              color: mainGreen,
                              size: 28 * scaleX,
                            ),
                          ),
                        ),

                        SizedBox(height: 18 * scaleY),

                        // ==================================
                        // العنوان
                        // ==================================
                        Text(
                          'الإعدادات',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            color: darkGreen,
                            fontSize: 29 * scaleX,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: 7 * scaleY),

                        Text(
                          'خصص تجربتك في رُوى',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            color: grayText,
                            fontSize: 14 * scaleX,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: 27 * scaleY),

                        // ==================================
                        // التطبيق
                        // ==================================
                        _sectionTitle(
                          text: 'التطبيق',
                          scaleX: scaleX,
                        ),

                        SizedBox(height: 10 * scaleY),

                        // ==================================
                        // كرت التطبيق
                        // ==================================
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),

                          child: Column(
                            children: [
                              _settingsItem(
                                context: context,
                                icon: Icons.language_rounded,
                                title: 'اللغة',
                                subtitle: 'اختر لغة التطبيق',
                                trailingText: 'العربية',
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onTap: () {
                                  _showMessage(
                                    context,
                                    'التطبيق يستخدم اللغة العربية حالياً',
                                  );
                                },
                              ),

                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: borderColor,
                              ),

                              _settingsItem(
                                context: context,
                                icon:
                                    Icons.notifications_none_rounded,
                                title: 'الإشعارات',
                                subtitle:
                                    'إدارة الإشعارات والصوت',
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onTap: () {
                                  _showMessage(
                                    context,
                                    'سنضيف إعدادات الإشعارات لاحقاً',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 26 * scaleY),

                        // ==================================
                        // الدعم والمساعدة
                        // ==================================
                        _sectionTitle(
                          text: 'الدعم والمساعدة',
                          scaleX: scaleX,
                        ),

                        SizedBox(height: 10 * scaleY),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),

                          child: _settingsItem(
                            context: context,
                            icon: Icons.help_outline_rounded,
                            title: 'مركز المساعدة',
                            subtitle:
                                'الأسئلة الشائعة ودعم المستخدم',
                            scaleX: scaleX,
                            scaleY: scaleY,
                            onTap: () {
                              _showMessage(
                                context,
                                'سنضيف مركز المساعدة لاحقاً',
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 26 * scaleY),

                        // ==================================
                        // معلومات التطبيق
                        // ==================================
                        _sectionTitle(
                          text: 'معلومات التطبيق',
                          scaleX: scaleX,
                        ),

                        SizedBox(height: 10 * scaleY),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),

                          child: Column(
                            children: [
                              _settingsItem(
                                context: context,
                                icon: Icons.info_outline_rounded,
                                title: 'حول التطبيق',
                                subtitle: 'معلومات عن رُوى',
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onTap: () {
                                  _showMessage(
                                    context,
                                    'سنضيف معلومات التطبيق لاحقاً',
                                  );
                                },
                              ),

                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: borderColor,
                              ),

                              _settingsItem(
                                context: context,
                                icon:
                                    Icons.shield_outlined,
                                title: 'سياسة الخصوصية',
                                subtitle:
                                    'اطلع على كيفية استخدام بياناتك',
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onTap: () {
                                  _showMessage(
                                    context,
                                    'سنضيف سياسة الخصوصية لاحقاً',
                                  );
                                },
                              ),

                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: borderColor,
                              ),

                              _settingsItem(
                                context: context,
                                icon:
                                    Icons.description_outlined,
                                title: 'الشروط والأحكام',
                                subtitle:
                                    'اطلع على شروط استخدام التطبيق',
                                scaleX: scaleX,
                                scaleY: scaleY,
                                onTap: () {
                                  _showMessage(
                                    context,
                                    'سنضيف الشروط والأحكام لاحقاً',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 25 * scaleY),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // Navigation Bar
                // ==========================================
                Container(
                  height: 72 * scaleY,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _navItem(
                        icon: Icons.home_outlined,
                        text: 'الرئيسية',
                        selected: false,
                        scaleX: scaleX,
                      ),
                      _navItem(
                        icon: Icons.search_rounded,
                        text: 'البحث',
                        selected: false,
                        scaleX: scaleX,
                      ),
                      _navItem(
                        icon: Icons.eco_outlined,
                        text: 'حديقتي',
                        selected: false,
                        scaleX: scaleX,
                      ),
                      _navItem(
                        icon: Icons.notifications_none_rounded,
                        text: 'الإشعارات',
                        selected: false,
                        scaleX: scaleX,
                      ),
                      _navItem(
                        icon: Icons.person_outline_rounded,
                        text: 'حسابي',
                        selected: true,
                        scaleX: scaleX,
                      ),
                    ],
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
  // عنوان القسم
  // ==========================================
  Widget _sectionTitle({
    required String text,
    required double scaleX,
  }) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        color: darkGreen,
        fontSize: 16 * scaleX,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ==========================================
  // عنصر من عناصر الإعدادات
  // ==========================================
  Widget _settingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required double scaleX,
    required double scaleY,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,

        child: SizedBox(
          height: 72 * scaleY,

          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scaleX,
            ),

            child: Row(
              textDirection: TextDirection.rtl,

              children: [
                // ==================================
                // الأيقونة
                // ==================================
                Container(
                  width: 44 * scaleX,
                  height: 44 * scaleX,

                  decoration: const BoxDecoration(
                    color: softGreen,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    color: mainGreen,
                    size: 25 * scaleX,
                  ),
                ),

                SizedBox(width: 12 * scaleX),

                // ==================================
                // العنوان والوصف
                // ==================================
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.end,

                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,

                        style: GoogleFonts.cairo(
                          color: const Color(0xFF292D28),
                          fontSize: 14 * scaleX,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 1 * scaleY),

                      Text(
                        subtitle,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: GoogleFonts.cairo(
                          color: grayText,
                          fontSize: 11.5 * scaleX,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 10 * scaleX),

                // ==================================
                // العربية - تظهر فقط في اللغة
                // ==================================
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    textDirection: TextDirection.rtl,

                    style: GoogleFonts.cairo(
                      color: grayText,
                      fontSize: 12 * scaleX,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(width: 7 * scaleX),
                ],

                // ==================================
                // السهم
                // ==================================
                Icon(
                  Icons.chevron_left_rounded,
                  color: mainGreen,
                  size: 25 * scaleX,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Navigation item
  // ==========================================
  Widget _navItem({
    required IconData icon,
    required String text,
    required bool selected,
    required double scaleX,
  }) {
    final color = selected
        ? mainGreen
        : grayText;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            icon,
            color: color,
            size: 24 * scaleX,
          ),

          const SizedBox(height: 2),

          Text(
            text,
            textDirection: TextDirection.rtl,

            style: GoogleFonts.cairo(
              color: color,
              fontSize: 10 * scaleX,
              fontWeight:
                  selected
                      ? FontWeight.w700
                      : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // رسالة مؤقتة
  // ==========================================
  void _showMessage(
    BuildContext context,
    String message,
  ) {
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
}