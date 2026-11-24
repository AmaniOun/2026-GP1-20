
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/ruwa_notice.dart';
import 'login_screen.dart';

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
  bool _isSaving = false;
  bool _editingPassword = false;
  // Each password field controls its own visibility independently.
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

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
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
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
  // Unified button geometry in editing forms and confirmation dialogs.
  // ==========================================
  ButtonStyle _primaryActionStyle({double height = 52}) {
    return ElevatedButton.styleFrom(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      disabledBackgroundColor: _green.withValues(alpha: 0.72),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  ButtonStyle _secondaryActionStyle({double height = 52}) {
    return OutlinedButton.styleFrom(
      foregroundColor: _green,
      backgroundColor: _light,
      disabledForegroundColor: _green.withValues(alpha: 0.72),
      disabledBackgroundColor: _light,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      side: const BorderSide(color: _green, width: 1.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ==========================================
  // رسائل موحدة مع صفحة تفاصيل النبات
  // ==========================================
  void _showMessage(String message, {bool success = false}) {
    if (mounted) RuwaNotice.show(context, message, success: success);
  }

  String _accountErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'requires-recent-login':
        return 'يلزم تأكيد كلمة مرور الحساب قبل إجراء هذا التغيير.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور الحالية غير صحيحة.';
      case 'email-already-in-use':
        return 'البريد الإلكتروني الجديد مستخدم في حساب آخر.';
      case 'invalid-email':
        return 'يرجى إدخال بريد إلكتروني صحيح.';
      case 'weak-password':
        return 'كلمة المرور الجديدة لا تستوفي متطلبات الأمان.';
      case 'too-many-requests':
        return 'طلبات كثيرة. يرجى المحاولة لاحقًا.';
      case 'network-request-failed':
      case 'unavailable':
        return 'تعذّر الاتصال بالخدمة. يرجى التحقق من اتصال الإنترنت والمحاولة مجددًا.';
      case 'permission-denied':
        return 'لا توجد صلاحية لتحديث بيانات الحساب.';
      default:
        return 'تعذّر إتمام التغيير. يرجى المحاولة مجددًا.';
    }
  }

  Widget _confirmedValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, textAlign: TextAlign.right,
            style: GoogleFonts.cairo(color: _muted, fontSize: 13)),
        const SizedBox(height: 3),
        Text(value, textAlign: TextAlign.right,
            textDirection: label == 'البريد الإلكتروني'
                ? TextDirection.ltr : TextDirection.rtl,
            style: GoogleFonts.cairo(color: _dark,
                fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  Future<bool> _confirmChanges({
    required String title,
    required List<Widget> summary,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(title, textAlign: TextAlign.right,
              style: GoogleFonts.cairo(color: _dark,
                  fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...summary,
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: _dark,
                        fontWeight: FontWeight.w600, height: 1.6)),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: _secondaryActionStyle(height: 48),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('إلغاء',
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: _primaryActionStyle(height: 48),
                    child: Text(confirmText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  // Firebase may require recent authentication to send an email-change link.
  // Ask for the existing password only if Firebase requires it.
  Future<void> _requestEmailChange(
      User user, String oldEmail, String newEmail) async {
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') rethrow;
      if (!mounted) return;
      final password = await _askForCurrentPassword();
      if (password == null) {
        throw StateError('cancelled');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: oldEmail, password: password),
      );
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  Future<String?> _askForCurrentPassword() async {
    String enteredPassword = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('تأكيد الهوية',
              style: GoogleFonts.cairo(color: _dark,
                  fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لإرسال رابط تأكيد تغيير البريد، يرجى إدخال كلمة مرور الحساب الحالية.',
                  style: GoogleFonts.cairo(color: _dark)),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => enteredPassword = value,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: _secondaryActionStyle(height: 48),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, enteredPassword),
                    style: _primaryActionStyle(height: 48),
                    child: Text('تأكيد',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final name = nameController.text.trim();
    final newEmail = emailController.text.trim();
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (name.isEmpty || newEmail.isEmpty) {
      _showMessage('يرجى تعبئة جميع الحقول');
      return;
    }
    if (!emailPattern.hasMatch(newEmail)) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('انتهت جلسة تسجيل الدخول. يرجى تسجيل الدخول مجددًا.');
      return;
    }
    final currentEmail = (user.email ?? widget.email).trim();
    final nameChanged = name != widget.name.trim();
    final emailChanged = newEmail.toLowerCase() != currentEmail.toLowerCase();
    if (!nameChanged && !emailChanged) {
      _showMessage('لم يتم إجراء أي تغييرات');
      return;
    }

    final confirmed = await _confirmChanges(
      title: 'تأكيد تعديل معلومات الحساب',
      summary: [
        _confirmedValue('الاسم الكامل', name),
        const SizedBox(height: 10),
        _confirmedValue('البريد الإلكتروني', newEmail),
      ],
      message: emailChanged
          ? 'هل هذه البيانات صحيحة؟ عند التأكيد، سيُرسل رابط إلى البريد الجديد، '
              'وسيتم تسجيل خروجك. يبقى البريد السابق صالحًا حتى يتم تأكيد الرابط.'
          : 'هل هذه البيانات صحيحة؟ سيتم حفظ الاسم الجديد في حسابك.',
      confirmText: 'نعم، تأكيد',
    );
    if (!confirmed || !mounted) return; // Cancel means edit; no data changes.

    setState(() => _isSaving = true);
    var nameSaved = false;
    var emailLinkSent = false;
    try {
      if (emailChanged) {
        try {
          await _requestEmailChange(user, currentEmail, newEmail);
          emailLinkSent = true;
        } on StateError catch (error) {
          if (error.message == 'cancelled') return;
          rethrow;
        }
      }

      String? nameError;
      if (nameChanged) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid)
              .set({'full_name': name}, SetOptions(merge: true));
          nameSaved = true;
          await user.updateDisplayName(name);
        } on FirebaseException catch (error) {
          nameError = _accountErrorMessage(error);
        } catch (_) {
          nameError = 'تعذّر إكمال تحديث الاسم.';
        }
      }

      if (emailChanged) {
        // The old email remains active until the new email is verified.
        // End the Firebase session before showing Log In.
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        final message = nameError == null
            ? 'أرسلنا رابط تأكيد إلى البريد الجديد. تم تسجيل خروجك. '
                'بعد تأكيد الرابط، يمكن تسجيل الدخول بالبريد الجديد.'
            : 'أرسلنا رابط تأكيد البريد الجديد وتم تسجيل خروجك، '
                'لكن لم يكتمل تحديث الاسم. يمكن تسجيل الدخول بعد تأكيد البريد.';
        RuwaNotice.show(context, message, success: nameError == null);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }

      if (nameError != null) {
        _showMessage(nameError);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        'name': name,
        'email': currentEmail,
      });
    } on FirebaseException catch (error) {
      if (emailLinkSent) {
        _showMessage('أُرسل رابط تأكيد البريد الجديد، لكن تعذّر إكمال تسجيل الخروج. '
            'يرجى إعادة المحاولة أو تسجيل الخروج يدويًا.');
      } else {
        final suffix = nameSaved
            ? ' تم حفظ الاسم، لكن لم يكتمل تغيير البريد.' : '';
        _showMessage('${_accountErrorMessage(error)}$suffix');
      }
    } catch (_) {
      _showMessage(emailLinkSent
          ? 'أُرسل رابط تأكيد البريد الجديد، لكن لم يكتمل تسجيل الخروج.'
          : nameSaved
              ? 'تم حفظ الاسم، لكن تعذّر إكمال تغيير البريد.'
              : 'تعذّر إتمام التغيير. يرجى المحاولة مجددًا.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelPasswordEditing() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    setState(() {
      _editingPassword = false;
      _showCurrentPassword = false;
      _showNewPassword = false;
      _showConfirmPassword = false;
    });
  }

  Future<void> _changePassword() async {
    if (_isSaving) return;
    final current = currentPasswordController.text;
    final fresh = newPasswordController.text;
    final repeated = confirmPasswordController.text;

    if (current.isEmpty || fresh.isEmpty || repeated.isEmpty) {
      _showMessage('يرجى تعبئة جميع حقول كلمة المرور');
      return;
    }
    final valid = fresh.length >= 6 &&
        RegExp(r'[A-Za-z\u0621-\u064A]').hasMatch(fresh) &&
        RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]').hasMatch(fresh) &&
        RegExp(r'[^A-Za-z0-9\u0600-\u06FF\s]').hasMatch(fresh);
    if (!valid) {
      _showMessage('يجب أن تتضمن كلمة المرور 6 أحرف على الأقل، وحرفًا، ورقمًا، ورمزًا.');
      return;
    }
    if (fresh != repeated) {
      _showMessage('كلمتا المرور الجديدتان غير متطابقتين');
      return;
    }
    if (fresh == current) {
      _showMessage('يجب أن تختلف كلمة المرور الجديدة عن الحالية');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showMessage('انتهت جلسة تسجيل الدخول. يرجى تسجيل الدخول مجددًا.');
      return;
    }

    setState(() => _isSaving = true);
    var passwordUpdated = false;
    try {
      // Firebase لا يتيح قراءة كلمة المرور المحفوظة. نتحقق من
      // كلمة المرور الحالية عن طريق إعادة المصادقة قبل إظهار التأكيد.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: current),
      );
      if (!mounted) return;

      // لا يظهر التأكيد إذا كانت كلمة المرور الحالية غير صحيحة.
      final confirmed = await _confirmChanges(
        title: 'تأكيد تغيير كلمة المرور',
        summary: [
          _confirmedValue('التغيير', 'تعيين كلمة مرور جديدة'),
        ],
        message: 'عند التأكيد، ستُحفظ كلمة المرور الجديدة، ثم '
            'سيتم تسجيل الخروج. يمكن بعد ذلك تسجيل الدخول '
            'باستخدام كلمة المرور الجديدة.',
        confirmText: 'نعم، تغيير',
      );
      if (!confirmed || !mounted) return;

      await user.updatePassword(fresh);
      passwordUpdated = true;
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      RuwaNotice.show(context,
          'تم تغيير كلمة المرور وتسجيل الخروج. يرجى تسجيل الدخول بكلمة المرور الجديدة.',
          success: true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      // عند فشل إعادة المصادقة، لا نغير كلمة المرور ولا نعرض التأكيد.
      final invalidCurrentPassword = !passwordUpdated &&
          (error.code == 'wrong-password' ||
           error.code == 'invalid-credential' ||
           error.code == 'invalid-login-credentials');
      _showMessage(passwordUpdated
          ? 'تم تغيير كلمة المرور، لكن تعذّر تسجيل الخروج. '
              'يرجى تسجيل الخروج يدويًا ثم الدخول بكلمة المرور الجديدة.'
          : invalidCurrentPassword
              ? 'كلمة المرور الحالية غير صحيحة. يرجى المحاولة مجددًا.'
              : _accountErrorMessage(error));
    } on FirebaseException catch (error) {
      _showMessage(passwordUpdated
          ? 'تم تغيير كلمة المرور، لكن تعذّر تسجيل الخروج. '
              'يرجى تسجيل الخروج يدويًا ثم الدخول بكلمة المرور الجديدة.'
          : _accountErrorMessage(error));
    } catch (_) {
      _showMessage(passwordUpdated
          ? 'تم تغيير كلمة المرور، لكن تعذّر تسجيل الخروج.'
          : 'تعذّر تغيير كلمة المرور. يرجى المحاولة مجددًا.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _passwordInput(
    String label,
    TextEditingController controller, {
    required bool visible,
    required VoidCallback onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, textAlign: TextAlign.right,
              style: _style(13, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: !visible,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            enabled: !_isSaving,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: _light,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                tooltip: visible ? 'إخفاء $label' : 'إظهار $label',
                onPressed: _isSaving ? null : onToggleVisibility,
                icon: Icon(visible
                    ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _green),
              ),
            ),
          ),
        ],
      ),
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
                onTap: _isSaving ? null : () => Navigator.of(context).pop(),
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
            enabled: !_isSaving,
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
              onTap: _isSaving ? null : () {
                if (_editingPassword) {
                  _cancelPasswordEditing();
                } else {
                  // عند فتح نموذج تغيير كلمة المرور، تُخفى الحقول الثلاثة.
                  // يبقى زر العين لكل حقل مستقلاً وبأيقونته الأصلية.
                  setState(() {
                    _showCurrentPassword = false;
                    _showNewPassword = false;
                    _showConfirmPassword = false;
                    _editingPassword = true;
                  });
                }
              },
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
          if (_editingPassword) ...[
            const SizedBox(height: 12),
            Text('يرجى إدخال كلمة المرور الحالية، ثم كلمة مرور جديدة. '
                'يجب أن تحتوي الجديدة على 6 أحرف على الأقل، وحرف، ورقم، ورمز.',
                style: _style(13, color: _muted)),
            _passwordInput(
              'كلمة المرور الحالية',
              currentPasswordController,
              visible: _showCurrentPassword,
              onToggleVisibility: () => setState(
                  () => _showCurrentPassword = !_showCurrentPassword),
            ),
            _passwordInput(
              'كلمة المرور الجديدة',
              newPasswordController,
              visible: _showNewPassword,
              onToggleVisibility: () => setState(
                  () => _showNewPassword = !_showNewPassword),
            ),
            _passwordInput(
              'تأكيد كلمة المرور الجديدة',
              confirmPasswordController,
              visible: _showConfirmPassword,
              onToggleVisibility: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _isSaving ? null : _cancelPasswordEditing,
                style: _secondaryActionStyle(),
                child: Text('إلغاء', style: _style(13, weight: FontWeight.w700)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: _primaryActionStyle(),
                child: Text('تغيير كلمة المرور',
                    textAlign: TextAlign.center,
                    style: _style(13, color: Colors.white, weight: FontWeight.w700)),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // واجهة الصفحة
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Directionality(
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
                    onPressed: _isSaving ? null : _saveChanges,
                    style: _primaryActionStyle(),
                    child: Text(
                      _isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
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
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: _secondaryActionStyle(),
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
      ),
    );
  }
}
