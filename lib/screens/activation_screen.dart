
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ruwa_page_header.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import '../utils/ruwa_notice.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  static Future<String> ensureUserDocument(User user) async {
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await ref.get();
    final fallback = user.displayName ?? 'مستخدم رُوى';

    if (doc.exists) {
      return (doc.data()?['full_name'] as String?) ?? fallback;
    }

    await ref.set({
      'full_name': fallback,
      'email': user.email,
    });

    return fallback;
  }

  @override
  State<ActivationScreen> createState() =>
      _ActivationScreenState();
}

enum _CheckStatus {
  verified,
  unverified,
  pendingEmail,
  needsAuthentication,
}

class _ActivationScreenState extends State<ActivationScreen> {
  static const _green = Color(0xFF315B32);
  static const _dark = Color(0xFF234525);
  static const _background = Color(0xFFFAF9F4);
  static const _lightGreen = Color(0xFFE8F0E4);
  static const _border = Color(0xFFDCE4D8);
  static const _muted = Color(0xFF7D8079);
  static const _amber = Color(0xFF8B6029);

  Timer? _pollTimer;
  Timer? _cooldownTimer;

  Future<_CheckStatus>? _ongoingCheck;

  bool _manualChecking = false;
  bool _sending = false;
  bool _updatingEmail = false;
  bool _resuming = false;
  bool _leaving = false;
  bool _navigating = false;
  bool _needsAuthentication = false;

  String? _pendingNewEmail;
  String? _confirmedNewEmail;
  late String _lastKnownEmail;

  DateTime? _activationResendAt;
  DateTime? _changeResendAt;

  int _activationSeconds = 0;
  int _changeSeconds = 0;

  @override
  void initState() {
    super.initState();

    _lastKnownEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';

    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!_leaving &&
            !_navigating &&
            !_needsAuthentication &&
            !_updatingEmail &&
            !_resuming &&
            !_manualChecking) {
          _checkActivation(silent: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

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
  // التنبيه العائم الموحّد
  // ==========================================

  void _showNotice(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: success);
  }

  // ==========================================
  // مؤقتان مستقلان لإعادة الإرسال
  // ==========================================

  void _beginCooldown({
    required bool emailChange,
  }) {
    final endsAt = DateTime.now().add(
      const Duration(seconds: 60),
    );

    setState(() {
      if (emailChange) {
        _changeResendAt = endsAt;
      } else {
        _activationResendAt = endsAt;
      }
    });

    _cooldownTimer?.cancel();
    _refreshCooldowns();

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _refreshCooldowns();

        if (_activationSeconds == 0 &&
            _changeSeconds == 0) {
          timer.cancel();
        }
      },
    );
  }

  void _refreshCooldowns() {
    if (!mounted) return;

    int remaining(DateTime? until) {
      if (until == null) return 0;

      final milliseconds =
          until.difference(DateTime.now()).inMilliseconds;

      return milliseconds <= 0
          ? 0
          : (milliseconds / 1000).ceil();
    }

    setState(() {
      _activationSeconds =
          remaining(_activationResendAt);
      _changeSeconds = remaining(_changeResendAt);
    });
  }

  // ==========================================
  // التعامل مع طلب مصادقة جديدة
  // ==========================================

  bool _requiresNewCredentials(
    FirebaseAuthException error,
  ) {
    return const {
      'user-token-expired',
      'invalid-user-token',
      'user-not-found',
      'user-disabled',
      'requires-recent-login',
    }.contains(error.code);
  }

  void _requestAuthentication() {
    if (!mounted) return;

    _pollTimer?.cancel();

    setState(() {
      _needsAuthentication = true;
    });
  }

  // ==========================================
  // التحقق من حالة الحساب
  // ==========================================

  Future<_CheckStatus> _performCheck() async {
    final oldUser =
        FirebaseAuth.instance.currentUser;

    if (oldUser == null) {
      return _CheckStatus.needsAuthentication;
    }

    try {
      await oldUser.reload().timeout(
        const Duration(seconds: 15),
      );
    } on FirebaseAuthException catch (error) {
      if (_requiresNewCredentials(error)) {
        return _CheckStatus.needsAuthentication;
      }
      rethrow;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _CheckStatus.needsAuthentication;
    }

    if (!mounted) return _CheckStatus.unverified;

    final updatedEmail = user.email ?? '';
    _lastKnownEmail = updatedEmail;

    // اكتشاف تأكيد تغيير البريد.
    if (_pendingNewEmail != null &&
        updatedEmail.toLowerCase() ==
            _pendingNewEmail!.toLowerCase()) {
      setState(() {
        _confirmedNewEmail = updatedEmail;
        _pendingNewEmail = null;
      });
    }

    // تأكيد تغيير البريد وتفعيل الحساب
    // ليسا بالضرورة العملية نفسها.
    if (!user.emailVerified) {
      return _pendingNewEmail != null
          ? _CheckStatus.pendingEmail
          : _CheckStatus.unverified;
    }

    try {
      await user.getIdToken(true).timeout(
        const Duration(seconds: 15),
      );
    } on FirebaseAuthException catch (error) {
      if (_requiresNewCredentials(error)) {
        return _CheckStatus.needsAuthentication;
      }
      rethrow;
    }

    final name =
        await ActivationScreen.ensureUserDocument(user)
            .timeout(const Duration(seconds: 15));

    if (!mounted || _navigating || _leaving) {
      return _CheckStatus.verified;
    }

    setState(() {
      _navigating = true;
    });

    _pollTimer?.cancel();
    RuwaNotice.dismiss();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(
          name: name,
          email: user.email ?? '',
          initialIndex: 0,
        ),
      ),
      (_) => false,
    );

    return _CheckStatus.verified;
  }

  // ==========================================
  // الفحص اليدوي والتلقائي
  // ==========================================

  Future<void> _checkActivation({
    bool silent = false,
  }) async {
    if (!mounted ||
        _leaving ||
        _navigating ||
        _resuming ||
        _updatingEmail) {
      return;
    }

    if (_needsAuthentication) {
      if (!silent) {
        await _resumeInsidePage();
      }
      return;
    }

    if (!silent) {
      setState(() {
        _manualChecking = true;
      });
    }

    final check =
        _ongoingCheck ??= _performCheck();

    try {
      final status = await check;

      if (!mounted || _navigating || _leaving) return;

      if (status == _CheckStatus.needsAuthentication) {
        _requestAuthentication();

        if (!silent) {
          _showNotice(
            'للمتابعة، أكّد كلمة مرور حسابك مرة واحدة.',
          );
        }
      } else if (!silent &&
          status == _CheckStatus.pendingEmail) {
        _showNotice(
          'إذا أكّدت بريدك الجديد، '
          'اضغط «متابعة التأكيد» أدناه.',
        );
      } else if (!silent &&
          status == _CheckStatus.unverified) {
        _showNotice(
          'لم يكتمل تفعيل البريد بعد. '
          'تحقّق من الرابط المرسل.',
        );
      }
    } on TimeoutException {
      if (!silent && mounted) {
        _showNotice(
          'استغرق التحقق وقتًا طويلًا. '
          'حاول مرة أخرى.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (_requiresNewCredentials(error)) {
        _requestAuthentication();

        if (!silent) {
          _showNotice(
            'للمتابعة، أكّد كلمة مرور حسابك مرة واحدة.',
          );
        }
      } else if (!silent && mounted) {
        _showNotice(
          error.code == 'network-request-failed'
              ? 'تحقّق من اتصال الإنترنت ثم حاول مجددًا.'
              : 'تعذّر التحقق الآن. حاول مجددًا.',
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        _showNotice(
          'تعذّر إكمال التحقق. حاول مجددًا.',
        );
      }
    } finally {
      if (identical(_ongoingCheck, check)) {
        _ongoingCheck = null;
      }

      if (!silent && mounted) {
        setState(() {
          _manualChecking = false;
        });
      }
    }
  }

  // ==========================================
  // نافذة إدخال كلمة المرور داخل الصفحة
  // ==========================================

  Future<String?> _askForPassword({
    required String title,
  }) {
    String password = '';
    bool obscured = true;
    String? error;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, updateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: _background,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                title: Text(
                  title,
                  style: _style(
                    17,
                    weight: FontWeight.w800,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'لإكمال التسجيل بأمان، أدخل كلمة '
                      'المرور التي أنشأت بها الحساب.',
                      style: _style(
                        12.5,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      autofocus: true,
                      obscureText: obscured,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      onChanged: (value) {
                        password = value;

                        if (error != null) {
                          updateDialog(() => error = null);
                        }
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          Navigator.pop(dialogContext, value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        hintTextDirection:
                            TextDirection.rtl,
                        errorText: error,
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          onPressed: () {
                            updateDialog(
                              () => obscured = !obscured,
                            );
                          },
                          icon: Icon(
                            obscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _green,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: Text(
                      'إلغاء',
                      style: _style(
                        13,
                        color: _muted,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (password.isEmpty) {
                        updateDialog(() {
                          error = 'أدخل كلمة المرور';
                        });
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        password,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'متابعة',
                      style: _style(
                        13,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // استكمال المصادقة دون مغادرة التفعيل
  // ==========================================

  Future<void> _resumeInsidePage() async {
    if (_resuming || _navigating || _leaving) return;

    final email = _pendingNewEmail ??
        _confirmedNewEmail ??
        _lastKnownEmail;

    if (email.isEmpty) {
      _showNotice(
        'لم نتمكن من معرفة البريد. '
        'ارجع لتسجيل الدخول.',
      );
      return;
    }

    final password = await _askForPassword(
      title: 'متابعة تأكيد الحساب',
    );

    if (!mounted || password == null) return;

    setState(() {
      _resuming = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        _needsAuthentication = false;
      });

      await _checkAfterResume();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        _showNotice(
          'تعذّر التأكيد. راجع البريد وكلمة المرور.',
        );
      } else if (error.code == 'user-not-found') {
        _showNotice(
          'لم يُفعَّل تغيير البريد بعد. '
          'تحقّق من الرابط.',
        );
      } else if (error.code == 'network-request-failed') {
        _showNotice(
          'تحقّق من اتصال الإنترنت وحاول مجددًا.',
        );
      } else {
        _showNotice(
          'تعذّر المتابعة الآن. حاول مرة أخرى.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        _showNotice(
          'تأخر الاتصال. حاول مرة أخرى.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNotice(
          'تعذّر المتابعة الآن. حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _resuming = false;
        });
      }
    }
  }

  Future<void> _checkAfterResume() async {
    try {
      final status = await _performCheck();

      if (!mounted || _navigating) return;

      if (status == _CheckStatus.needsAuthentication) {
        _requestAuthentication();

        _showNotice(
          'يلزم تأكيد كلمة المرور للمتابعة.',
        );
      } else if (status == _CheckStatus.unverified) {
        _showNotice(
          'تم تحديث البريد، لكن تفعيل الحساب '
          'لم يكتمل بعد.',
        );
      } else if (status == _CheckStatus.pendingEmail) {
        _showNotice(
          'تحقّق من رابط تأكيد بريدك الجديد.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNotice(
          'تعذّر التحقق من الحساب الآن.',
        );
      }
    }
  }

  // ==========================================
  // نافذة تعديل البريد
  // ==========================================

  Future<String?> _askForEmail(
    String original,
  ) {
    String enteredEmail = original;
    String? error;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, updateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: _background,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                title: Text(
                  'تعديل البريد الإلكتروني',
                  style: _style(
                    18,
                    weight: FontWeight.w800,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أدخل البريد الصحيح لنرسل إليه '
                      'رابط التأكيد.',
                      style: _style(
                        13,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: original,
                      autofocus: true,
                      keyboardType:
                          TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (value) {
                        enteredEmail = value;

                        if (error != null) {
                          updateDialog(
                            () => error = null,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            'البريد الإلكتروني الجديد',
                        hintTextDirection:
                            TextDirection.rtl,
                        errorText: error,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: _green,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: _green,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: Text(
                      'إلغاء',
                      style: _style(
                        13,
                        color: _muted,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final value = enteredEmail.trim();

                      final valid = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value);

                      if (!valid) {
                        updateDialog(() {
                          error =
                              'أدخل بريدًا إلكترونيًا صحيحًا';
                        });
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        value,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'إرسال الرابط',
                      style: _style(
                        13,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // تغيير البريد الإلكتروني
  // ==========================================

  Future<void> _editEmail() async {
    if (_updatingEmail ||
        _leaving ||
        _navigating ||
        _resuming) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _needsAuthentication) {
      await _resumeInsidePage();
      return;
    }

    final shown = _pendingNewEmail ??
        user.email ??
        _lastKnownEmail;

    final newEmail = await _askForEmail(shown);

    if (!mounted || newEmail == null) return;

    if (newEmail.toLowerCase() ==
        shown.toLowerCase()) {
      _showNotice(
        'هذا هو البريد المعروض حاليًا.',
      );
      return;
    }

    setState(() {
      _updatingEmail = true;
    });

    try {
      await user.verifyBeforeUpdateEmail(newEmail)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        _pendingNewEmail = newEmail;
        _confirmedNewEmail = null;
      });

      _beginCooldown(emailChange: true);

      _showNotice(
        'أرسلنا رابط تأكيد البريد الجديد.',
        success: true,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      if (_requiresNewCredentials(error)) {
        _requestAuthentication();

        _showNotice(
          'لتعديل البريد، أكّد كلمة مرور حسابك أولًا.',
        );
      } else if (error.code == 'email-already-in-use') {
        _showNotice(
          'هذا البريد مستخدم في حساب آخر.',
        );
      } else if (error.code == 'too-many-requests') {
        _showNotice(
          'طلبات كثيرة. حاول بعد قليل.',
        );
      } else {
        _showNotice(
          'تعذّر إرسال رابط تغيير البريد.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNotice(
          'تعذّر إرسال الرابط. حاول مجددًا.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingEmail = false;
        });
      }
    }
  }

  // ==========================================
  // إعادة إرسال رابط التفعيل أو تغيير البريد
  // ==========================================

  Future<void> _resendLink() async {
    if (_sending ||
        _updatingEmail ||
        _leaving ||
        _resuming ||
        _needsAuthentication) {
      return;
    }

    final changing = _pendingNewEmail != null;

    if (changing
        ? _changeSeconds > 0
        : _activationSeconds > 0) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _requestAuthentication();
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      if (changing) {
        await user
            .verifyBeforeUpdateEmail(_pendingNewEmail!)
            .timeout(const Duration(seconds: 15));
      } else {
        await user.sendEmailVerification().timeout(
          const Duration(seconds: 15),
        );
      }

      if (!mounted) return;

      _beginCooldown(emailChange: changing);

      _showNotice(
        changing
            ? 'أعدنا إرسال رابط تأكيد البريد الجديد.'
            : 'أعدنا إرسال رابط تفعيل الحساب.',
        success: true,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      if (_requiresNewCredentials(error)) {
        _requestAuthentication();

        _showNotice(
          'للمتابعة، أكّد كلمة مرور حسابك مرة واحدة.',
        );
      } else if (error.code == 'too-many-requests') {
        _showNotice(
          'طلبات كثيرة. حاول بعد قليل.',
        );
      } else {
        _showNotice(
          'تعذّر إرسال الرابط. حاول مجددًا.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showNotice(
          'تعذّر إرسال الرابط. حاول مجددًا.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ==========================================
  // العودة إلى تسجيل الدخول
  // ==========================================

  Future<void> _backToLogin() async {
    if (_leaving) return;

    setState(() {
      _leaving = true;
    });

    _pollTimer?.cancel();

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      RuwaNotice.dismiss();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _leaving = false;
        });

        _showNotice(
          'تعذّرت العودة الآن. حاول مجددًا.',
        );
      }
    }
  }

  // ==========================================
  // الزر الأساسي
  // ==========================================

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _green,
          disabledBackgroundColor:
              _green.withValues(alpha: 0.75),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: _style(
                      14,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: _style(
                  16,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ==========================================
  // واجهة صفحة التفعيل
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final shownEmail = _pendingNewEmail ??
        _confirmedNewEmail ??
        user?.email ??
        _lastKnownEmail;

    final pending = _pendingNewEmail != null;

    final busy = _manualChecking ||
        _resuming ||
        _navigating ||
        _updatingEmail;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _backToLogin();
          }
        },
        child: Scaffold(
          backgroundColor: _background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        RuwaPageHeader(
                          onBack: _backToLogin,
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Image.asset(
                            'assets/images/ruwa_logo.png',
                            height: 95,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 26),

                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: _lightGreen,
                              borderRadius:
                                  BorderRadius.circular(26),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              color: _green,
                              size: 49,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          'تحقّق من بريدك الإلكتروني',
                          textAlign: TextAlign.center,
                          style: _style(
                            23,
                            weight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _needsAuthentication
                              ? 'لإكمال التسجيل، أكّد كلمة مرور حسابك.'
                              : pending
                                  ? 'أرسلنا رابط تأكيد تغيير البريد إلى العنوان الجديد.'
                                  : 'افتح رابط التفعيل المرسل إلى بريدك.',
                          textAlign: TextAlign.center,
                          style: _style(
                            13.5,
                            color: _muted,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // البريد الإلكتروني الحالي أو الجديد.
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: _border,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            shownEmail,
                            textDirection:
                                TextDirection.ltr,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: _style(
                              14,
                              color: _green,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (pending &&
                            !_needsAuthentication) ...[
                          const SizedBox(height: 9),
                          Text(
                            'بانتظار تأكيد تغيير البريد',
                            textAlign: TextAlign.center,
                            style: _style(
                              12,
                              color: _amber,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ] else if (_confirmedNewEmail !=
                            null) ...[
                          const SizedBox(height: 9),
                          Text(
                            'تم تأكيد تغيير البريد الإلكتروني',
                            textAlign: TextAlign.center,
                            style: _style(
                              12,
                              color: _green,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        if (!_needsAuthentication)
                          TextButton.icon(
                            onPressed:
                                busy ? null : _editEmail,
                            icon: _updatingEmail
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _green,
                                    ),
                                  )
                                : const Icon(
                                    Icons.edit_outlined,
                                    size: 19,
                                  ),
                            label: Text(
                              _updatingEmail
                                  ? 'جارٍ إرسال الرابط...'
                                  : 'تعديل البريد الإلكتروني',
                              style: _style(
                                13,
                                color: _green,
                                weight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _green,
                            ),
                          ),

                        const SizedBox(height: 12),

                        Text(
                          'لم تصلك الرسالة؟ '
                          'تحقّق من مجلد البريد المزعج.',
                          textAlign: TextAlign.center,
                          style: _style(
                            12,
                            color: _muted,
                          ),
                        ),

                        const SizedBox(height: 25),

                        _primaryButton(
                          label: _resuming
                              ? 'جارٍ استكمال التسجيل...'
                              : _manualChecking ||
                                      _navigating
                                  ? 'جارٍ التحقق...'
                                  : _needsAuthentication
                                      ? 'متابعة التأكيد'
                                      : 'التحقق من التفعيل',
                          loading: _resuming ||
                              _manualChecking ||
                              _navigating,
                          onTap: busy || _leaving
                              ? null
                              : _needsAuthentication
                                  ? _resumeInsidePage
                                  : () =>
                                      _checkActivation(),
                        ),

                        const SizedBox(height: 12),

                        if (!_needsAuthentication)
                          TextButton(
                            onPressed: busy ||
                                    _sending ||
                                    _leaving ||
                                    (pending
                                        ? _changeSeconds > 0
                                        : _activationSeconds >
                                            0)
                                ? null
                                : _resendLink,
                            child: _sending
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _green,
                                    ),
                                  )
                                : Text(
                                    pending
                                        ? _changeSeconds > 0
                                            ? 'إعادة إرسال رابط تأكيد البريد بعد $_changeSeconds ثانية'
                                            : 'إعادة إرسال رابط تأكيد البريد'
                                        : _activationSeconds >
                                                0
                                            ? 'إعادة إرسال رابط التفعيل بعد $_activationSeconds ثانية'
                                            : 'إعادة إرسال رابط التفعيل',
                                    textAlign:
                                        TextAlign.center,
                                    style: _style(
                                      13,
                                      color: (pending
                                              ? _changeSeconds >
                                                  0
                                              : _activationSeconds >
                                                  0)
                                          ? _muted
                                          : _green,
                                      weight:
                                          FontWeight.w700,
                                    ),
                                  ),
                          ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: _leaving
                              ? null
                              : _backToLogin,
                          child: Text(
                            'العودة إلى تسجيل الدخول',
                            style: _style(
                              14,
                              color: _muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
