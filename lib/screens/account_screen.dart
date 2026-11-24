
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/ruwa_notice.dart';

import 'welcome_screen.dart';
import 'account_information_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatefulWidget {
  final String name;
  final String email;
  final bool active;
  final void Function(String name, String email)? onProfileChanged;

  const AccountScreen({
    super.key,
    required this.name,
    required this.email,
    this.active = true,
    this.onProfileChanged,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ==========================================
  // ألوان رُوى الموحّدة
  // ==========================================

  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _light = Color(0xFFE8F0E4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF4E604D);

  late String currentName;
  late String currentEmail;

  @override
  void initState() {
    super.initState();

    currentName = widget.name;
    currentEmail = widget.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) _refreshAccountFromFirebase();
    });
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _refreshAccountFromFirebase();
    }
  }

  // ==========================================
  // نظام الخطوط الموحّد مع Home وMy Garden
  // ==========================================

  TextStyle _style(
    double size, {
    Color color = _dark,
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  Widget _label(
    String value, {
    double size = 14,
    Color color = _dark,
    FontWeight weight = FontWeight.w500,
    TextAlign align = TextAlign.right,
    int? maxLines,
  }) {
    return Text(
      value,
      textDirection: TextDirection.rtl,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null
          ? null
          : TextOverflow.ellipsis,
      style: _style(
        size,
        color: color,
        weight: weight,
      ),
    );
  }

  // ==========================================
  // الانتقال إلى معلومات الحساب
  // ==========================================

  // Refresh confirmed email changes (e.g. after the user opens the
  // verification link), and keep the Firestore email in sync with Firebase Auth.
  Future<void> _refreshAccountFromFirebase() async {
    try {
      final previous = FirebaseAuth.instance.currentUser;
      if (previous == null) return;
      await previous.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted || user == null) return;

      final email = user.email ?? currentEmail;
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!mounted) return;
      final name = (snapshot.data()?['full_name'] as String?)?.trim().isNotEmpty == true
          ? (snapshot.data()!['full_name'] as String).trim()
          : (user.displayName?.trim().isNotEmpty == true ? user.displayName! : currentName);

      // Only sync an authenticated, verified email after its change was confirmed.
      if (user.emailVerified && snapshot.data()?['email'] != email) {
        await docRef.set({'email': email}, SetOptions(merge: true));
      }
      if (!mounted) return;
      if (currentName != name || currentEmail != email) {
        setState(() { currentName = name; currentEmail = email; });
        widget.onProfileChanged?.call(name, email);
      }
    } catch (_) {
      // Keep the last displayed values if the network is unavailable.
    }
  }

  Future<void> _openAccountInformation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountInformationScreen(
          name: currentName,
          email: currentEmail,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      // An update may have partially succeeded before a later API error.
      await _refreshAccountFromFirebase();
      return;
    }
    final updatedName = (result['name'] as String?) ?? currentName;
    final updatedEmail = (result['email'] as String?) ?? currentEmail;
    setState(() {
      currentName = updatedName;
      currentEmail = updatedEmail;
    });
    widget.onProfileChanged?.call(updatedName, updatedEmail);
    RuwaNotice.show(context, 'تم تحديث معلومات الحساب بنجاح', success: true);
  }

  // ==========================================
  // تسجيل الخروج - دون تغيير وظيفته الحالية
  // ==========================================

  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: _label(
            'تسجيل الخروج',
            size: 19,
            weight: FontWeight.w800,
            align: TextAlign.center,
          ),
          content: _label(
            'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
            size: 14,
            color: _muted,
            align: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          actions: [
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(82, 44),
                foregroundColor: _green,
                side: const BorderSide(
                  color: _green,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _label(
                'إلغاء',
                size: 14,
                color: _green,
                weight: FontWeight.w700,
                align: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _label(
                'نعم، تسجيل الخروج',
                size: 14,
                color: Colors.white,
                weight: FontWeight.w700,
                align: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseException catch (_) {
      if (mounted) RuwaNotice.show(context,
        'تعذّر تسجيل الخروج. يرجى المحاولة مجددًا.', success: false);
    } catch (_) {
      if (mounted) RuwaNotice.show(context,
        'تعذّر تسجيل الخروج. يرجى المحاولة مجددًا.', success: false);
    }
  }

  // ==========================================
  // عنوان الصفحة
  // ==========================================

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(
          'حسابي',
          size: 25,
          weight: FontWeight.w800,
        ),
        const SizedBox(height: 3),
        _label(
          'إدارة حسابك وتخصيص تجربتك في رُوى',
          size: 14,
          color: _muted,
        ),
      ],
    );
  }

  // ==========================================
  // معلومات المستخدم في أعلى الصفحة
  // ==========================================

  Widget _userProfile() {
    return Column(
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: const BoxDecoration(
            color: _light,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: _green,
            size: 49,
          ),
        ),

        const SizedBox(height: 15),

        // الاسم
        Text(
          currentName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _style(
            22,
            weight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 4),

        // البريد الإلكتروني
        Text(
          currentEmail,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _style(
            14,
            color: _muted,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // البطاقات الموحّدة
  // ==========================================

  Widget _accountOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _border,
              width: 1.1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // أيقونة البطاقة
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _green,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              // عنوان ووصف البطاقة
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    _label(
                      title,
                      size: 16,
                      weight: FontWeight.w800,
                    ),
                    const SizedBox(height: 3),
                    _label(
                      subtitle,
                      size: 14,
                      color: _muted,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // سهم الانتقال
              const Icon(
                Icons.chevron_left_rounded,
                color: _green,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // زر تسجيل الخروج
  // ==========================================

  Widget _logoutButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _label(
          'تسجيل الخروج',
          size: 16,
          color: Colors.white,
          weight: FontWeight.w700,
          align: TextAlign.center,
        ),
      ),
    );
  }

  // ==========================================
  // واجهة حسابي
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 22,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // عنوان الصفحة
                _pageHeader(),

                const SizedBox(height: 27),

                // صورة المستخدم واسمه وبريده
                _userProfile(),

                const SizedBox(height: 30),

                // معلومات الحساب
                _accountOption(
                  icon: Icons.person_outline_rounded,
                  title: 'معلومات الحساب',
                  subtitle: 'عرض وتعديل بيانات حسابك',
                  onTap: _openAccountInformation,
                ),

                const SizedBox(height: 13),

                // الإعدادات
                _accountOption(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  subtitle: 'تخصيص التطبيق والتفضيلات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Divider(
                  color: _border,
                  height: 1,
                ),

                const SizedBox(height: 22),

                // تسجيل الخروج
                _logoutButton(),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
