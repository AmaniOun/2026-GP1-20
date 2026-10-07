import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_profile.dart';
import '../services/garden_service.dart';

// ==========================================
// شاشة إعداد / تعديل الحديقة
//
// - لو existingGarden == null:
//   وضع "إعداد جديد"
//
// - لو existingGarden != null:
//   وضع "تعديل" وتُعبّأ الحقول تلقائياً
//
// عند إنشاء حديقة جديدة، تستقبل الشاشة
// بيانات الموقع بعد التحقق منها في My Garden.
// ==========================================

class SetupGardenScreen extends StatefulWidget {
  final GardenProfile? existingGarden;

  // ========================================
  // بيانات الموقع المتحقق منها
  // ========================================
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

    // بيانات الموقع
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

  final lengthController = TextEditingController();
  final widthController = TextEditingController();

  bool isSaving = false;

  bool get isEditMode =>
      widget.existingGarden != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingGarden;

    if (existing != null) {
      selectedDirection =
          existing.facadeDirection;

      selectedCareLevel =
          existing.careLevel;

      lengthController.text =
          _formatNumber(
        existing.lengthMeters,
      );

      widthController.text =
          _formatNumber(
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

  // ========================================
  // إظهار رسالة للمستخدم
  // ========================================
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
              TextDirection.rtl,
          textAlign:
              TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================
  // حدود منطقية لأبعاد مساحة الزراعة
  // ========================================
  static const double _minDimension = 0.5;
  static const double _maxDimension = 500;

  // ========================================
  // حفظ الحديقة
  // ========================================
  Future<void> _saveGarden() async {
    // --------------------------------------
    // اتجاه الواجهة
    // --------------------------------------
    if (selectedDirection == null) {
      _showMessage(
        'يرجى تحديد اتجاه واجهة الحديقة',
      );

      return;
    }

    // --------------------------------------
    // قراءة الطول والعرض
    // --------------------------------------
    final lengthText =
        lengthController.text.trim();

    final widthText =
        widthController.text.trim();

    if (lengthText.isEmpty ||
        widthText.isEmpty) {
      _showMessage(
        'يرجى إدخال طول وعرض مساحة الزراعة',
      );

      return;
    }

    final length =
        double.tryParse(lengthText);

    final width =
        double.tryParse(widthText);

    // --------------------------------------
    // التحقق من الطول
    // --------------------------------------
    if (length == null) {
      _showMessage(
        'قيمة الطول غير صحيحة، يرجى إدخال رقم فقط',
      );

      return;
    }

    // --------------------------------------
    // التحقق من العرض
    // --------------------------------------
    if (width == null) {
      _showMessage(
        'قيمة العرض غير صحيحة، يرجى إدخال رقم فقط',
      );

      return;
    }

    if (length <= 0) {
      _showMessage(
        'يجب أن تكون قيمة الطول أكبر من صفر',
      );

      return;
    }

    if (width <= 0) {
      _showMessage(
        'يجب أن تكون قيمة العرض أكبر من صفر',
      );

      return;
    }

    if (length < _minDimension ||
        length > _maxDimension) {
      _showMessage(
        'قيمة الطول يجب أن تكون بين '
        '${_minDimension.toInt()} و '
        '${_maxDimension.toInt()} متر',
      );

      return;
    }

    if (width < _minDimension ||
        width > _maxDimension) {
      _showMessage(
        'قيمة العرض يجب أن تكون بين '
        '${_minDimension.toInt()} و '
        '${_maxDimension.toInt()} متر',
      );

      return;
    }

    // --------------------------------------
    // مستوى العناية
    // --------------------------------------
    if (selectedCareLevel == null) {
      _showMessage(
        'يرجى تحديد مستوى العناية المفضل',
      );

      return;
    }

    setState(() => isSaving = true);

    // ======================================
    // تحديد بيانات الموقع التي سيتم حفظها
    //
    // في وضع التعديل:
    // نحتفظ بموقع الحديقة المحفوظ سابقاً.
    //
    // في وضع الإنشاء:
    // نستخدم الموقع الذي تم التحقق منه
    // قبل فتح هذه الشاشة.
    // ======================================

    final existing =
        widget.existingGarden;

    final double? latitude =
        isEditMode
            ? existing!.latitude
            : widget.latitude;

    final double? longitude =
        isEditMode
            ? existing!.longitude
            : widget.longitude;

    final String? city =
        isEditMode
            ? existing!.city
            : widget.city;

    final String? state =
        isEditMode
            ? existing!.state
            : widget.state;

    final String? country =
        isEditMode
            ? existing!.country
            : widget.country;

    final String? formattedAddress =
        isEditMode
            ? existing!.formattedAddress
            : widget.formattedAddress;

    final bool locationVerified =
        isEditMode
            ? existing!.locationVerified
            : widget.locationVerified;

    // ======================================
    // إنشاء Garden Profile
    // ======================================
    final garden = GardenProfile(
      facadeDirection:
          selectedDirection!,

      lengthMeters:
          length,

      widthMeters:
          width,

      careLevel:
          selectedCareLevel!,

      // بيانات الموقع
      latitude:
          latitude,

      longitude:
          longitude,

      city:
          city,

      state:
          state,

      country:
          country,

      formattedAddress:
          formattedAddress,

      locationVerified:
          locationVerified,

      updatedAt:
          DateTime.now(),
    );

    // ======================================
    // حفظ / تحديث
    // ======================================
    if (isEditMode) {
      await GardenService.instance
          .updateGarden(garden);
    } else {
      await GardenService.instance
          .saveGarden(garden);
    }

    if (!mounted) return;

    setState(() => isSaving = false);

    _showMessage(
      isEditMode
          ? 'تم تحديث بيانات الحديقة'
          : 'تم حفظ بيانات الحديقة',
    );

    Navigator.pop(context, garden);
  }

  // ========================================
  // واجهة الشاشة
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFAF9F4),
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

            final scaleX =
                width / 360;

            final scaleY =
                height / 800;

            return SingleChildScrollView(
              physics:
                  const ClampingScrollPhysics(),

              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    24 * scaleX,
                vertical:
                    18 * scaleY,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // ==================================
                  // زر الرجوع
                  // ==================================
                  Align(
                    alignment:
                        Alignment.centerLeft,

                    child: IconButton(
                      onPressed: () =>
                          Navigator.pop(
                        context,
                      ),

                      padding:
                          EdgeInsets.zero,

                      constraints:
                          const BoxConstraints(),

                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            const Color(
                          0xFF315B32,
                        ),
                        size:
                            28 * scaleX,
                      ),
                    ),
                  ),

                  SizedBox(
                    height:
                        10 * scaleY,
                  ),

                  // ==================================
                  // العنوان
                  // ==================================
                  Text(
                    isEditMode
                        ? 'تعديل بيانات الحديقة'
                        : 'إعداد حديقتي',

                    textDirection:
                        TextDirection.rtl,

                    textAlign:
                        TextAlign.right,

                    style:
                        GoogleFonts.cairo(
                      color:
                          const Color(
                        0xFF234525,
                      ),
                      fontSize:
                          26 * scaleX,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  SizedBox(
                    height:
                        5 * scaleY,
                  ),

                  Text(
                    'هذه المعلومات تساعد رُوى يرشح لك نباتات تناسب حديقتك',

                    textDirection:
                        TextDirection.rtl,

                    textAlign:
                        TextAlign.right,

                    style:
                        GoogleFonts.cairo(
                      color:
                          const Color(
                        0xFF7D8079,
                      ),
                      fontSize:
                          13 * scaleX,
                      fontWeight:
                          FontWeight.w400,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(
                    height:
                        24 * scaleY,
                  ),

                  // ==================================
                  // اتجاه واجهة الحديقة
                  // ==================================
                  _sectionLabel(
                    'اتجاه واجهة الحديقة',
                    scaleX,
                  ),

                  SizedBox(
                    height:
                        10 * scaleY,
                  ),

                  Wrap(
                    alignment:
                        WrapAlignment.end,

                    spacing:
                        10 * scaleX,

                    runSpacing:
                        10 * scaleY,

                    children:
                        FacadeDirection
                            .values
                            .map(
                      (direction) {
                        final isSelected =
                            selectedDirection ==
                                direction;

                        return _choiceChip(
                          label:
                              direction
                                  .arabicLabel,

                          selected:
                              isSelected,

                          scaleX:
                              scaleX,

                          onTap: () {
                            setState(
                              () =>
                                  selectedDirection =
                                      direction,
                            );
                          },
                        );
                      },
                    ).toList(),
                  ),

                  SizedBox(
                    height:
                        24 * scaleY,
                  ),

                  // ==================================
                  // مساحة الزراعة
                  // ==================================
                  _sectionLabel(
                    'مساحة الزراعة المتاحة (بالمتر)',
                    scaleX,
                  ),

                  SizedBox(
                    height:
                        10 * scaleY,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _numberField(
                          controller:
                              widthController,
                          hint:
                              'العرض',
                          scaleX:
                              scaleX,
                          scaleY:
                              scaleY,
                        ),
                      ),

                      SizedBox(
                        width:
                            12 * scaleX,
                      ),

                      Expanded(
                        child:
                            _numberField(
                          controller:
                              lengthController,
                          hint:
                              'الطول',
                          scaleX:
                              scaleX,
                          scaleY:
                              scaleY,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height:
                        24 * scaleY,
                  ),

                  // ==================================
                  // مستوى العناية
                  // ==================================
                  _sectionLabel(
                    'مستوى العناية المفضل',
                    scaleX,
                  ),

                  SizedBox(
                    height:
                        10 * scaleY,
                  ),

                  Wrap(
                    alignment:
                        WrapAlignment.end,

                    spacing:
                        10 * scaleX,

                    runSpacing:
                        10 * scaleY,

                    children:
                        CareLevel.values.map(
                      (level) {
                        final isSelected =
                            selectedCareLevel ==
                                level;

                        return _choiceChip(
                          label:
                              level
                                  .arabicLabel,

                          selected:
                              isSelected,

                          scaleX:
                              scaleX,

                          onTap: () {
                            setState(
                              () =>
                                  selectedCareLevel =
                                      level,
                            );
                          },
                        );
                      },
                    ).toList(),
                  ),

                  SizedBox(
                    height:
                        32 * scaleY,
                  ),

                  // ==================================
                  // زر الحفظ
                  // ==================================
                  SizedBox(
                    height:
                        52 * scaleY,

                    child:
                        ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : _saveGarden,

                      style:
                          ButtonStyle(
                        elevation:
                            const WidgetStatePropertyAll(
                          0,
                        ),

                        backgroundColor:
                            WidgetStateProperty
                                .resolveWith<
                                    Color>(
                          (states) {
                            if (states
                                .contains(
                              WidgetState
                                  .pressed,
                            )) {
                              return const Color(
                                0xFF234525,
                              );
                            }

                            if (states
                                .contains(
                              WidgetState
                                  .hovered,
                            )) {
                              return const Color(
                                0xFF3D6A3E,
                              );
                            }

                            return const Color(
                              0xFF315B32,
                            );
                          },
                        ),

                        foregroundColor:
                            const WidgetStatePropertyAll(
                          Colors.white,
                        ),

                        shape:
                            WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),

                      child:
                          isSaving
                              ? SizedBox(
                                  width:
                                      22 *
                                          scaleX,
                                  height:
                                      22 *
                                          scaleX,
                                  child:
                                      const CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                    strokeWidth:
                                        2.5,
                                  ),
                                )
                              : Text(
                                  isEditMode
                                      ? 'حفظ التعديلات'
                                      : 'حفظ الحديقة',

                                  textDirection:
                                      TextDirection
                                          .rtl,

                                  style:
                                      GoogleFonts
                                          .cairo(
                                    fontSize:
                                        17 *
                                            scaleX,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                    ),
                  ),

                  SizedBox(
                    height:
                        20 * scaleY,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================
  // عنوان القسم
  // ========================================
  Widget _sectionLabel(
    String text,
    double scaleX,
  ) {
    return Text(
      text,
      textDirection:
          TextDirection.rtl,
      textAlign:
          TextAlign.right,

      style: GoogleFonts.cairo(
        color:
            const Color(0xFF292D28),
        fontSize:
            14 * scaleX,
        fontWeight:
            FontWeight.w700,
      ),
    );
  }

  // ========================================
  // Choice Chip
  // ========================================
  Widget _choiceChip({
    required String label,
    required bool selected,
    required double scaleX,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 150,
        ),

        padding:
            EdgeInsets.symmetric(
          horizontal:
              18 * scaleX,
          vertical:
              10 * scaleX,
        ),

        decoration:
            BoxDecoration(
          color:
              selected
                  ? const Color(
                      0xFF315B32,
                    )
                  : Colors.white,

          borderRadius:
              BorderRadius.circular(
            30,
          ),

          border: Border.all(
            color:
                selected
                    ? const Color(
                        0xFF315B32,
                      )
                    : const Color(
                        0xFFDCE4D8,
                      ),
            width: 1.3,
          ),
        ),

        child: Text(
          label,

          textDirection:
              TextDirection.rtl,

          style:
              GoogleFonts.cairo(
            color:
                selected
                    ? Colors.white
                    : const Color(
                        0xFF292D28,
                      ),

            fontSize:
                13 * scaleX,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ========================================
  // حقل رقم
  // ========================================
  Widget _numberField({
    required TextEditingController
        controller,
    required String hint,
    required double scaleX,
    required double scaleY,
  }) {
    return SizedBox(
      height:
          52 * scaleY,

      child: TextField(
        controller:
            controller,

        keyboardType:
            const TextInputType
                .numberWithOptions(
          decimal: true,
        ),

        textDirection:
            TextDirection.rtl,

        textAlign:
            TextAlign.right,

        style:
            GoogleFonts.cairo(
          color:
              const Color(
            0xFF234525,
          ),
          fontSize:
              13 * scaleX,
        ),

        decoration:
            InputDecoration(
          hintText:
              hint,

          hintTextDirection:
              TextDirection.rtl,

          hintStyle:
              GoogleFonts.cairo(
            color:
                const Color(
              0xFF8A8D87,
            ),
            fontSize:
                13 * scaleX,
          ),

          suffixText:
              'م',

          suffixStyle:
              GoogleFonts.cairo(
            color:
                const Color(
              0xFF8A8D87,
            ),
            fontSize:
                12 * scaleX,
          ),

          filled:
              true,

          fillColor:
              Colors.white,

          contentPadding:
              EdgeInsets.symmetric(
            horizontal:
                16 * scaleX,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(
                0xFFDCE4D8,
              ),
              width:
                  1.3,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color:
                  Color(
                0xFF315B32,
              ),
              width:
                  1.7,
            ),
          ),
        ),
      ),
    );
  }
}