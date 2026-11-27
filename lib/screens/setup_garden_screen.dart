
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_profile.dart';
import '../services/garden_service.dart';
import '../utils/ruwa_notice.dart';

// ==========================================
// شاشة إعداد الحديقة
// ==========================================

class SetupGardenScreen extends StatefulWidget {
  final GardenProfile? existingGarden;

  // بيانات الموقع المتحقق منها
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? formattedAddress;
  final bool locationVerified;

  const SetupGardenScreen({
    super.key,
    this.existingGarden,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.formattedAddress,
    this.locationVerified = false,
  });

  @override
  State<SetupGardenScreen> createState() =>
      _SetupGardenScreenState();
}

class _SetupGardenScreenState
    extends State<SetupGardenScreen> {
  FacadeDirection? selectedDirection;
  CareLevel? selectedCareLevel;
  WateringLevel? selectedWateringLevel;

  final lengthController = TextEditingController();
  final widthController = TextEditingController();

  bool isSaving = false;

  bool get isEditMode => widget.existingGarden != null;

  // ==========================================
  // ألوان التصميم
  // ==========================================

  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _darkGreen = _dark;
  static const Color _muted = Color(0xFF526352);
  static const Color _light = Color(0xFFE8F0E4);
  static const Color _lightSage = _light;
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _border = Color(0xFFDCE4D8);

  // ==========================================
  // تهيئة البيانات عند تعديل حديقة موجودة
  // ==========================================

  @override
  void initState() {
    super.initState();

    final existing = widget.existingGarden;

    if (existing != null) {
      selectedDirection = existing.facadeDirection;
      selectedCareLevel = existing.careLevel;
      selectedWateringLevel = existing.wateringLevel;

      lengthController.text = _formatNumber(
        existing.lengthMeters,
      );

      widthController.text = _formatNumber(
        existing.widthMeters,
      );
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  @override
  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    super.dispose();
  }

  // ==========================================
  // إظهار رسالة للمستخدم
  // ==========================================

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: success);
  }

  // ==========================================
  // حفظ الحديقة
  // ==========================================

  Future<void> _saveGarden() async {
    // التحقق من اتجاه الواجهة
    if (selectedDirection == null) {
      _showMessage(
        'يرجى تحديد اتجاه واجهة الحديقة',
      );
      return;
    }

    // قراءة الطول والعرض
    final lengthText = lengthController.text.trim();
    final widthText = widthController.text.trim();

    if (lengthText.isEmpty || widthText.isEmpty) {
      _showMessage(
        'يرجى إدخال طول وعرض مساحة الزراعة',
      );
      return;
    }

    final length = double.tryParse(lengthText);
    final width = double.tryParse(widthText);

    // التحقق من الطول
    if (length == null) {
      _showMessage(
        'قيمة الطول غير صحيحة، يرجى إدخال رقم فقط',
      );
      return;
    }

    // التحقق من العرض
    if (width == null) {
      _showMessage(
        'قيمة العرض غير صحيحة، يرجى إدخال رقم فقط',
      );
      return;
    }

    if (!length.isFinite || length <= 0) {
      _showMessage(
        'يجب أن تكون قيمة الطول أكبر من صفر',
      );
      return;
    }

    if (!width.isFinite || width <= 0) {
      _showMessage(
        'يجب أن تكون قيمة العرض أكبر من صفر',
      );
      return;
    }

    // التحقق من مستوى العناية
    if (selectedCareLevel == null) {
      _showMessage(
        'يرجى تحديد مستوى العناية المفضل',
      );
      return;
    }

    // التحقق من مستوى الري
    if (selectedWateringLevel == null) {
      _showMessage(
        'يرجى تحديد مستوى الري المفضل',
      );
      return;
    }

    // تأكيد المساحة قبل حفظ البيانات
    final confirmed = await _confirmGardenArea(
      length,
      width,
    );

    if (!mounted || !confirmed) return;

    setState(() => isSaving = true);

    // ======================================
    // بيانات الموقع
    // ======================================

    final existing = widget.existingGarden;

    final double? latitude = isEditMode
        ? existing!.latitude
        : widget.latitude;

    final double? longitude = isEditMode
        ? existing!.longitude
        : widget.longitude;

    final String? city = isEditMode
        ? existing!.city
        : widget.city;

    final String? state = isEditMode
        ? existing!.state
        : widget.state;

    final String? country = isEditMode
        ? existing!.country
        : widget.country;

    final String? formattedAddress = isEditMode
        ? existing!.formattedAddress
        : widget.formattedAddress;

    final bool locationVerified = isEditMode
        ? existing!.locationVerified
        : widget.locationVerified;

    // ======================================
    // إنشاء Garden Profile
    // ======================================

    final garden = GardenProfile(
      facadeDirection: selectedDirection!,
      lengthMeters: length,
      widthMeters: width,
      careLevel: selectedCareLevel!,
      wateringLevel: selectedWateringLevel!,

      // بيانات الموقع
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      country: country,
      formattedAddress: formattedAddress,
      locationVerified: locationVerified,
      updatedAt: DateTime.now(),
    );

    // ======================================
    // الحفظ أو التحديث
    // ======================================

    if (isEditMode) {
      await GardenService.instance.updateGarden(garden);
    } else {
      await GardenService.instance.saveGarden(garden);
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    _showMessage(
      isEditMode
          ? 'تم تحديث بيانات الحديقة'
          : 'تم حفظ بيانات الحديقة',
      success: true,
    );

    Navigator.pop(context, garden);
  }

  // ==========================================
  // نافذة تأكيد مساحة الزراعة
  // ==========================================

  Future<bool> _confirmGardenArea(
    double length,
    double width,
  ) async {
    final area = length * width;

    if (!area.isFinite || area <= 0) {
      _showMessage(
        'المساحة المحسوبة غير صالحة، يرجى تعديل الأبعاد',
      );
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تأكيد مساحة الزراعة',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _areaValue(
                    'العرض',
                    '${_formatNumber(width)} م',
                  ),
                ),
                Expanded(
                  child: _areaValue(
                    'الطول',
                    '${_formatNumber(length)} م',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _areaValue(
              'المساحة المحسوبة',
              '${_formatNumber(area)} م²',
            ),
            const SizedBox(height: 20),
            Text(
              'هل هذه الأبعاد تمثل المساحة المتاحة للزراعة في حديقتك؟',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              backgroundColor: _light,
              side: const BorderSide(
                color: _green,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
            ),
            label: Text(
              'تعديل الأبعاد',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(
              'تأكيد وحفظ',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );

    return result == true;
  }

  Widget _areaValue(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            color: const Color(0xFF7D8079),
          ),
        ),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // تنسيق النصوص
  // ==========================================

  TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _dark,
    double height = 1.45,
  }) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // ==========================================
  // واجهة الشاشة
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: _background,
          surfaceTintColor: _background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          title: Text(
            isEditMode
                ? 'تعديل بيانات الحديقة'
                : 'إعداد حديقتي',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: _darkGreen,
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
                    onTap: () =>
                        Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _lightSage,
                          borderRadius:
                              BorderRadius.circular(12),
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
        ),

        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                const EdgeInsetsDirectional.fromSTEB(
              20, 14, 20, 28,
            ),
            children: [
              _introDescription(),

              const SizedBox(height: 24),

              // ==================================
              // اتجاه واجهة الحديقة
              // ==================================

              _section(
                icon: Icons.explore_outlined,
                title: 'اتجاه واجهة الحديقة',
                subtitle:
                    'اختر الجهة التي تتجه إليها واجهة حديقتك.',
                child: _choiceWrap(
                  children: FacadeDirection.values
                      .map(
                        (direction) => _choiceChip(
                          label: direction.arabicLabel,
                          selected:
                              selectedDirection == direction,
                          onTap: () => setState(
                            () => selectedDirection =
                                direction,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================
              // مساحة الزراعة
              // ==================================

              _section(
                icon: Icons.square_foot_outlined,
                title: 'مساحة الزراعة',
                subtitle:
                    'أدخل الطول والعرض بالمتر لتحديد المساحة المتاحة.',
                child: Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        controller: lengthController,
                        label: 'الطول',
                        hint: 'مثال: 6',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        controller: widthController,
                        label: 'العرض',
                        hint: 'مثال: 4',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================
              // مستوى العناية المفضل
              // ==================================

              _section(
                icon: Icons.spa_outlined,
                title: 'مستوى العناية المفضل',
                subtitle:
                    'اختر مقدار العناية الذي يناسب وقتك.',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    // الترتيب من اليمين إلى اليسار:
                    // قليلة - متوسطة - عالية
                    _choiceWrap(
                      children: CareLevel.values
                          .map(
                            (level) => _choiceChip(
                              label: level.arabicLabel,
                              selected:
                                  selectedCareLevel == level,
                              onTap: () => setState(
                                () => selectedCareLevel =
                                    level,
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 12),

                    _selectionDescription(
                      selectedCareLevel == null
                          ? 'اختر مستوى العناية لعرض وصفه.'
                          : _careDescription(
                              selectedCareLevel!,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================
              // مستوى الري المفضل
              // ==================================

              _section(
                icon: Icons.water_drop_outlined,
                title: 'مستوى الري المفضل',
                subtitle: 'اختر مستوى الري المناسب لك.',
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    // الترتيب من اليمين إلى اليسار:
                    // منخفض - متوسط - مرتفع
                    _choiceWrap(
                      children: WateringLevel.values
                          .map(
                            (level) => _choiceChip(
                              label: level.arabicLabel,
                              selected:
                                  selectedWateringLevel ==
                                      level,
                              onTap: () => setState(
                                () => selectedWateringLevel =
                                    level,
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 12),

                    _selectionDescription(
                      selectedWateringLevel == null
                          ? 'اختر مستوى الري لعرض وصفه.'
                          : _wateringDescription(
                              selectedWateringLevel!,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================
              // زر الحفظ
              // ==================================

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      isSaving ? null : _saveGarden,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _green,
                    disabledBackgroundColor:
                        const Color(0xFF91A58E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isEditMode
                              ? 'حفظ التعديلات'
                              : 'حفظ الحديقة',
                          style: _style(
                            16,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // الوصف الافتتاحي
  // ==========================================

  Widget _introDescription() {
    return Text(
      'تساعد هذه المعلومات رُوى على اقتراح نباتات تناسب ظروف حديقتك.',
      textAlign: TextAlign.right,
      style: _style(
        14,
        color: _muted,
      ),
    );
  }

  // ==========================================
  // تصميم الأقسام
  // ==========================================

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: _light,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _green,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: _style(
                    17,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: _style(
              13.5,
              color: _muted,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ==========================================
  // ترتيب خيارات الاختيار
  // ==========================================

  Widget _choiceWrap({
    required List<Widget> children,
  }) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 10,
      children: children,
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _green : _background,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? _green : _border,
          width: 1.3,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 19,
              vertical: 9,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: _style(
                  14,
                  weight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : _dark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // وصف الخيار المحدد
  // ==========================================

  Widget _selectionDescription(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _light,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: _style(
          14,
          color: _dark,
          height: 1.6,
        ),
      ),
    );
  }

  // ==========================================
  // حقل إدخال الأبعاد
  // ==========================================

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: _style(
            14,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          style: _style(
            16,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _style(
              14,
              color: _muted,
            ),
            suffixText: 'م',
            suffixStyle: _style(
              14,
              color: _muted,
            ),
            filled: true,
            fillColor: _background,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: _border,
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: _green,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // وصف مستويات الري
  // ==========================================

  String _wateringDescription(
    WateringLevel level,
  ) {
    switch (level) {
      case WateringLevel.low:
        return 'الصيف: كل 10 إلى 21 يومًا\n'
            'الشتاء: بدون ري';

      case WateringLevel.medium:
        return 'الصيف: كل 7 إلى 10 أيام\n'
            'الشتاء: كل 14 إلى 21 يومًا';

      case WateringLevel.high:
        return 'الصيف: كل 5 إلى 10 أيام\n'
            'الشتاء: كل 14 إلى 21 يومًا';
    }
  }

  // ==========================================
  // وصف مستويات العناية
  // ==========================================

  String _careDescription(
    CareLevel level,
  ) {
    switch (level) {
      case CareLevel.low:
        return 'التقليم: مرة في السنة\n'
            'التسميد: مرة في السنة';

      case CareLevel.medium:
        return 'التقليم: مرتان في السنة\n'
            'التسميد: مرتان في السنة';

      case CareLevel.high:
        return 'التقليم: 4 مرات في السنة\n'
            'التسميد: 3 مرات في السنة';
    }
  }
}
