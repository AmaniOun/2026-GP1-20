
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
  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _bg = Color(0xFFFAF9F4);
  static const Color _light = Color(0xFFE8F0E4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF7D8079);

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
  // توحيد الخط
  // ==========================================

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
  // الرسائل الحالية
  // ==========================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
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

    // المحافظة على طريقة الحفظ الحالية:
    // إعادة البيانات إلى الصفحة السابقة فقط.
    Navigator.pop(
      context,
      {
        'name': name,
        'email': email,
      },
    );
  }

  // ==========================================
  // AppBar مطابق لصفحة تفاصيل النبات
  // ==========================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,

      title: Text(
        'معلومات الحساب',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.cairo(
          color: _dark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),

      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 12,
        ),
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
                      color: _light,
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
    );
  }

  // ==========================================
  // بطاقة الاسم أو البريد الإلكتروني
  // ==========================================

  Widget _informationCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    final isEmail =
        keyboardType == TextInputType.emailAddress;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: _style(
              14,
              weight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,

            // البريد يُكتب بالإنجليزية، لكن
            // يبقى بمحاذاة اليمين.
            textDirection: isEmail
                ? TextDirection.ltr
                : TextDirection.rtl,
            textAlign: TextAlign.right,

            autocorrect: !isEmail,
            enableSuggestions: !isEmail,

            style: _style(
              14,
              weight: FontWeight.w500,
            ),

            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: _green,
                size: 23,
              ),

              filled: true,
              fillColor: _light,

              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _green,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // بطاقة كلمة المرور
  // ==========================================

  Widget _passwordCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'كلمة المرور',
            textAlign: TextAlign.right,
            style: _style(
              14,
              weight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          Material(
            color: _light,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showMessage(
                'سيتم إضافة تغيير كلمة المرور لاحقاً',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // الأيقونة في اليمين
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: _green,
                      size: 23,
                    ),

                    const SizedBox(width: 12),

                    // نقاط كلمة المرور بعد الأيقونة
                    Text(
                      '••••••••',
                      textDirection: TextDirection.ltr,
                      style: _style(
                        14,
                        weight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    // تغيير كلمة المرور في اليسار
                    Text(
                      'تغيير كلمة المرور',
                      textAlign: TextAlign.left,
                      style: _style(
                        13,
                        color: _muted,
                        weight: FontWeight.w500,
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
  // واجهة الصفحة
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,

        // الشريط العلوي الموحّد
        appBar: _buildAppBar(),

        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // ==================================
                // عنوان الصفحة
                // ==================================

                Text(
                  'معلومات الحساب',
                  textAlign: TextAlign.right,
                  style: _style(
                    26,
                    weight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'عرض وتعديل بيانات حسابك',
                  textAlign: TextAlign.right,
                  style: _style(
                    14,
                    color: _muted,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================
                // الاسم الكامل
                // ==================================

                _informationCard(
                  title: 'الاسم الكامل',
                  controller: nameController,
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),

                const SizedBox(height: 14),

                // ==================================
                // البريد الإلكتروني
                // ==================================

                _informationCard(
                  title: 'البريد الإلكتروني',
                  controller: emailController,
                  icon: Icons.mail_outline_rounded,
                  keyboardType:
                      TextInputType.emailAddress,
                ),

                const SizedBox(height: 14),

                // ==================================
                // كلمة المرور
                // ==================================

                _passwordCard(),

                const SizedBox(height: 26),

                // ==================================
                // زر حفظ التغييرات
                // ==================================

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'حفظ التغييرات',
                      style: _style(
                        16,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================
                // زر إلغاء
                // ==================================

                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      backgroundColor: _light,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: _style(
                        15,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
