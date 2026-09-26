import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountInformationScreen extends StatefulWidget {
  final String name;
  final String email;

  const AccountInformationScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState
    extends State<AccountInformationScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.name,
    );

    emailController = TextEditingController(
      text: widget.email,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ==========================================
  // رسالة للمستخدم
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
  // حفظ التغييرات
  // ==========================================
  void _saveChanges() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    // نرجع البيانات الجديدة إلى صفحة حسابي
    Navigator.pop(
      context,
      {
        'name': name,
        'email': email,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),

      // مهم:
      // يمنع النافقيشن السفلي من الارتفاع فوق الكيبورد
      resizeToAvoidBottomInset: false,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scaleX = width / 360;
            final scaleY = height / 800;

            // ارتفاع الكيبورد
            final keyboardHeight =
                MediaQuery.of(context).viewInsets.bottom;

            return Stack(
              children: [
                // ==========================================
                // محتوى الصفحة
                // ==========================================
                Positioned.fill(
                  bottom: 72 * scaleY,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),

                    // إذا فتح الكيبورد نعطي المحتوى مساحة
                    // حتى نقدر نسكرول بدون Overflow
                    padding: EdgeInsets.only(
                      left: 24 * scaleX,
                      right: 24 * scaleX,
                      bottom: keyboardHeight > 0
                          ? keyboardHeight + (20 * scaleY)
                          : 25 * scaleY,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        SizedBox(height: 28 * scaleY),

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
                              Icons.chevron_left_rounded,
                              color: const Color(0xFF315B32),
                              size: 31 * scaleX,
                            ),
                          ),
                        ),

                        SizedBox(height: 10 * scaleY),

                        // ==================================
                        // عنوان الصفحة
                        // ==================================
                        Text(
                          'معلومات الحساب',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,

                          style: GoogleFonts.cairo(
                            color: const Color(0xFF234525),
                            fontSize: 27 * scaleX,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 3 * scaleY),

                        Text(
                          'عرض وتعديل بيانات حسابك',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,

                          style: GoogleFonts.cairo(
                            color: const Color(0xFF7D8079),
                            fontSize: 14 * scaleX,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: 32 * scaleY),

                        // ==================================
                        // الاسم الكامل
                        // ==================================
                        _informationCard(
                          title: 'الاسم الكامل',
                          controller: nameController,
                          icon: Icons.person_outline_rounded,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          keyboardType: TextInputType.name,
                        ),

                        SizedBox(height: 14 * scaleY),

                        // ==================================
                        // البريد الإلكتروني
                        // ==================================
                        _informationCard(
                          title: 'البريد الإلكتروني',
                          controller: emailController,
                          icon: Icons.mail_outline_rounded,
                          scaleX: scaleX,
                          scaleY: scaleY,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 14 * scaleY),

                        // ==================================
                        // كلمة المرور
                        // ==================================
                        _passwordCard(
                          scaleX: scaleX,
                          scaleY: scaleY,
                        ),

                        SizedBox(height: 24 * scaleY),

                        // ==================================
                        // زر حفظ التغييرات
                        // ==================================
                        SizedBox(
                          height: 52 * scaleY,

                          child: ElevatedButton(
                            onPressed: _saveChanges,

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

                            child: Text(
                              'حفظ التغييرات',
                              textDirection: TextDirection.rtl,

                              style: GoogleFonts.cairo(
                                fontSize: 16 * scaleX,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10 * scaleY),

                        // ==================================
                        // زر إلغاء
                        // ==================================
                        SizedBox(
                          height: 48 * scaleY,

                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            style: ButtonStyle(
                              elevation:
                                  const WidgetStatePropertyAll(0),

                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (states) {
                                  if (states.contains(
                                    WidgetState.pressed,
                                  )) {
                                    return const Color(0xFFD9E6D5);
                                  }

                                  if (states.contains(
                                    WidgetState.hovered,
                                  )) {
                                    return const Color(0xFFE0EBDD);
                                  }

                                  return const Color(0xFFE8F0E4);
                                },
                              ),

                              foregroundColor:
                                  const WidgetStatePropertyAll(
                                Color(0xFF234525),
                              ),

                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                            ),

                            child: Text(
                              'إلغاء',
                              textDirection: TextDirection.rtl,

                              style: GoogleFonts.cairo(
                                color: const Color(0xFF234525),
                                fontSize: 15 * scaleX,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 25 * scaleY),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // شريط التنقل السفلي
                //
                // ثابت في أسفل الشاشة.
                // عندما يظهر الكيبورد سيغطيه بدل ما يرفعه.
                // ==========================================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,

                  child: Container(
                    height: 72 * scaleY,

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFDCE4D8),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // كرت الاسم والبريد الإلكتروني
  // ==========================================
  Widget _informationCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required double scaleX,
    required double scaleY,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        13 * scaleX,
        13 * scaleY,
        13 * scaleX,
        14 * scaleY,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFDCE4D8),
          width: 1.2,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2 * scaleX,
            ),

            child: Text(
              title,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,

              style: GoogleFonts.cairo(
                color: const Color(0xFF292D28),
                fontSize: 14 * scaleX,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 8 * scaleY),

          SizedBox(
            height: 46 * scaleY,

            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,

              style: GoogleFonts.cairo(
                color: const Color(0xFF6F736D),
                fontSize: 14 * scaleX,
              ),

              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE8F0E4),

                suffixIcon: Icon(
                  icon,
                  color: const Color(0xFF315B32),
                  size: 23 * scaleX,
                ),

                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14 * scaleX,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),

                  borderSide: const BorderSide(
                    color: Color(0xFF6F8F64),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // كرت كلمة المرور
  // ==========================================
  Widget _passwordCard({
    required double scaleX,
    required double scaleY,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        13 * scaleX,
        13 * scaleY,
        13 * scaleX,
        14 * scaleY,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFDCE4D8),
          width: 1.2,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2 * scaleX,
            ),

            child: Text(
              'كلمة المرور',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,

              style: GoogleFonts.cairo(
                color: const Color(0xFF292D28),
                fontSize: 14 * scaleX,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 8 * scaleY),

          Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: () {
                _showMessage(
                  'سيتم إضافة تغيير كلمة المرور لاحقاً',
                );
              },

              borderRadius: BorderRadius.circular(12),

              child: Container(
                height: 46 * scaleY,

                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scaleX,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E4),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  textDirection: TextDirection.rtl,

                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: const Color(0xFF315B32),
                      size: 24 * scaleX,
                    ),

                    SizedBox(width: 11 * scaleX),

                    Expanded(
                      child: Text(
                        'تغيير كلمة المرور',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,

                        style: GoogleFonts.cairo(
                          color: const Color(0xFF7D8079),
                          fontSize: 13 * scaleX,
                        ),
                      ),
                    ),

                    Text(
                      '••••••••',
                      textDirection: TextDirection.ltr,

                      style: GoogleFonts.cairo(
                        color: const Color(0xFF292D28),
                        fontSize: 15 * scaleX,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // عناصر النافقيشن السفلي
  // ==========================================
  Widget _navItem({
    required IconData icon,
    required String text,
    required bool selected,
    required double scaleX,
  }) {
    final color = selected
        ? const Color(0xFF315B32)
        : const Color(0xFF7D8079);

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
                  selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}