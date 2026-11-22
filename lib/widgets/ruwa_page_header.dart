
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RuwaPageHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;

  const RuwaPageHeader({
    super.key,
    this.title,
    this.onBack,
  });

  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _light = Color(0xFFE8F0E4);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Material(
                  color: _light,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onBack ??
                        () => Navigator.maybePop(context),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 25,
                        color: _green,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: _dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
