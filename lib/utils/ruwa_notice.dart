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

  static void show(
    BuildContext context,
    String message, {
    bool success = true,
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
                    color: success ? _lightSage : const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: success
                          ? const Color(0xFFC7DCC2)
                          : const Color(0xFFE7CEAA),
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
                              : Icons.info_outline_rounded,
                          color: success ? _green : const Color(0xFF8B6029),
                          size: 23,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              color: _darkGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                          ),
                        ),
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
    _timer = Timer(const Duration(seconds: 3), _hide);
  }

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
