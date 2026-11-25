import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The same animated top notice used by Ruwa's Plant Details screen.
/// It is attached to the root navigator so it can remain visible when a
/// successful account change redirects the user to Log In.
class RuwaNotice {
  RuwaNotice._();

  static OverlayEntry? _entry;
  static AnimationController? _controller;
  static Timer? _timer;
  static bool _closing = false;

  static const _green = Color(0xFF315B32);
  static const _darkGreen = Color(0xFF234525);
  static const _lightSage = Color(0xFFE8F0E4);
  // Warning / error colours: one calm terracotta palette used by the
  // notice and by every field-level error in the app.
  static const warnBg = Color(0xFFFCF1EB);
  static const warnBorder = Color(0xFFEFD3C4);
  static const warnAccent = Color(0xFFC8765A);
  static const warnText = Color(0xFF6E3B28);

  static void show(
    BuildContext context,
    String message, {
    bool success = true,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _clearImmediately();
    if (!context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay ?? Overlay.of(context, rootOverlay: true);
    final controller = AnimationController(
      vsync: navigator,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _controller = controller;
    _closing = false;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final top = MediaQuery.paddingOf(context).top + 68 + 8;

    final entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: top,
        left: 18,
        right: 18,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.35),
                end: Offset.zero,
              ).animate(animation),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: success ? _lightSage : warnBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: success
                          ? const Color(0xFFC7DCC2)
                          : warnBorder,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 8, 9),
                    child: Row(
                      children: [
                        Icon(
                          success
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: success ? _green : warnAccent,
                          size: 23,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              color: success ? _darkGreen : warnText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                          ),
                        ),
                        if (actionLabel != null && onAction != null) ...[
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () {
                              _hide();
                              onAction();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFC7DCC2)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              actionLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'إغلاق التنبيه',
                          onPressed: _hide,
                          icon: const Icon(Icons.close_rounded, size: 21),
                          color: _darkGreen,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    controller.forward();
    _timer = Timer(duration, _hide);
  }

  /// Closes the current notice immediately (used when a screen is replaced).
  static void dismiss() => _clearImmediately();

  static Future<void> _hide() async {
    final controller = _controller;
    if (controller == null || _closing) return;
    _closing = true;
    _timer?.cancel();
    _timer = null;
    await controller.reverse();
    if (identical(controller, _controller)) _clearImmediately();
  }

  static void _clearImmediately() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _controller?.dispose();
    _controller = null;
    _closing = false;
  }
}
