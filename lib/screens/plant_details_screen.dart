import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant.dart';
import '../services/garden_service.dart';
import '../utils/confirm_dialog.dart';
import '../utils/ruwa_notice.dart';
import '../services/my_plant_service.dart';
import '../services/perenual_service.dart';
import '../services/plant_translation_service.dart';
import '../services/plant_image_service.dart';
import '../utils/plant_display_formatter.dart';
class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailsScreen({
    super.key,
    required this.plant,
  });
  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}
class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _green = Color(0xFF315B32);
  static const Color _darkGreen = Color(0xFF234525);
  static const Color _sage = Color(0xFF6F8F64);
  static const Color _lightSage = Color(0xFFE8F0E4);
  late final Future<List<Map<String, dynamic>>> _careFuture;
  late final Future<String?> _imageFuture;

  bool _isSavingPlant = false;
  bool _isSaved = false;
  final Map<String, Future<String>> _translationFutures = {};
  Future<String> _translationFor(String description) {
    return _translationFutures.putIfAbsent(
      description,
      () => PlantTranslationService.instance.translateCareDescription(description),
    );
  }
  @override
  void initState() {
    super.initState();
    _imageFuture = PlantImageService.instance.imageFor(widget.plant.scientificName);
    _careFuture = _loadCareGuides();
    _loadSavedState();
  }

  // Restore saved state so the action button shows Add or Remove.
  Future<void> _loadSavedState() async {
    try {
      final saved = await MyPlantService.instance.isAlreadySaved(widget.plant);
      if (mounted) setState(() => _isSaved = saved);
    } catch (_) {}
  }
  /// Checks saved state and suitability warnings before persisting the plant.
  /// Users must explicitly continue when any warning is displayed.
  Future<void> _addToMyPlants() async {
    if (_isSavingPlant) return;
    setState(() => _isSavingPlant = true);
    try {
      // Prevent duplicate entries in the current user's saved plants.
      if (await MyPlantService.instance.isAlreadySaved(widget.plant)) {
        if (!mounted) return;
        setState(() => _isSaved = true);
        _showMessage('هذا النبات موجود في نباتاتي من قبل', success: false);
        return;
      }

      // Evaluate garden compatibility separately from climate sensitivity.
      // The climate class is a caution, not proof of garden incompatibility.
      final garden = await GardenService.instance.getGarden();
      final gardenReasons = garden == null
          ? <String>[]
          : MyPlantService.instance.unsuitableReasons(widget.plant, garden);
      final climateWarning =
          MyPlantService.instance.isClimateSensitive(widget.plant);

      // Show a confirmation dialog if the plant has any known warning.
      // Canceling keeps the plant out of My Plants.
      if (gardenReasons.isNotEmpty || climateWarning) {
        if (!mounted) return;
        final confirmed = await _confirmUnsuitable(
          gardenReasons,
          climateWarning: climateWarning,
        );
        if (confirmed != true) return;
      }

      // Save only after warnings have been accepted (if any).
      final added = await MyPlantService.instance.addPlant(widget.plant);
      if (!mounted) return;
      if (added) setState(() => _isSaved = true);
      _showMessage(
        added
            ? 'تمت إضافة النبات إلى نباتاتي بنجاح'
            : 'هذا النبات موجود في نباتاتي من قبل',
        success: added,
      );
    } catch (error) {
      debugPrint('Add to My Plants error: $error');
      if (!mounted) return;
      _showMessage('تعذرت إضافة النبات، يرجى المحاولة مرة أخرى', success: false);
    } finally {
      if (mounted) setState(() => _isSavingPlant = false);
    }
  }

  // Ask for confirmation, then remove the saved entry from Firestore.
  Future<void> _removeFromMyPlants() async {
    if (_isSavingPlant) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف النبات؟',
      message: 'سيتم حذف ${widget.plant.displayName} من نباتاتي.',
      confirmText: 'حذف',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSavingPlant = true);
    try {
      await MyPlantService.instance.removePlant(widget.plant);
      if (!mounted) return;
      setState(() => _isSaved = false);
      _showRemovedWithUndo();
    } catch (error) {
      debugPrint('Remove from My Plants error: $error');
      if (!mounted) return;
      _showMessage('تعذر حذف النبات، يرجى المحاولة مرة أخرى', success: false);
    } finally {
      if (mounted) setState(() => _isSavingPlant = false);
    }
  }

  // Keep the Undo action at the bottom, but match the shared Ruwa
  // success-notice design (sage background, green icon, Cairo font).
  void _showRemovedWithUndo() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.clearSnackBars();

    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _lightSage,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC7DCC2)),
        ),
        duration: const Duration(seconds: 5),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: _green,
                size: 23,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم حذف النبات من نباتاتي',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: _darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  messenger.hideCurrentSnackBar();
                  try {
                    final added = await MyPlantService.instance
                        .addPlant(widget.plant);
                    if (added && mounted) {
                      setState(() => _isSaved = true);
                    }
                  } catch (_) {}
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
                  'تراجع',
                  style: GoogleFonts.cairo(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Give the user five seconds to undo the deletion.
    Future.delayed(const Duration(seconds: 5), controller.close);
  }

  /// Explains garden mismatches and climate tolerance in separate sections.
  /// A climate-sensitive plant may still suit this particular garden.
  Future<bool?> _confirmUnsuitable(
    List<String> gardenReasons, {
    required bool climateWarning,
  }) {
    final notes = <String>[
      if (gardenReasons.isNotEmpty)
        'عوامل غير متوافقة مع حديقتك:\n'
        '${gardenReasons.map((reason) => '• $reason').join('\n')}',
      if (climateWarning)
        'تنبيه بشأن التحمل المناخي:\n'
        '• هذا النبات مصنف حساسًا لمناخ الرياض، وقد يحتاج إلى عناية إضافية. '
        'هذا التصنيف وحده لا يعني أنه غير مناسب لحديقتك.',
    ];

    return showConfirmDialog(
      context,
      title: gardenReasons.isEmpty
          ? 'تنبيه بشأن التحمل المناخي'
          : 'تنبيه قبل إضافة النبات',
      message:
          '${notes.join('\n\n')}\n\nهل تريد متابعة إضافة النبات إلى نباتاتي؟',
      confirmText: 'متابعة',
    );
  }

  // Use the exact shared top notice for plant and account feedback.
  void _showMessage(String message, {bool success = true}) {
    RuwaNotice.show(context, message, success: success);
  }

  Future<List<Map<String, dynamic>>> _loadCareGuides() async {
    try {
      final plant = await PerenualService.instance.findPlant(
        widget.plant.scientificName,
      );
      final id = plant?['id'];
      if (id is! int) return [];
      return await PerenualService.instance.getCareGuides(id);
    } catch (error) {
      debugPrint('Perenual care guides error: $error');
      return [];
    }
  }
  String _translateLight(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'full sun':
        return 'شمس كاملة';
      case 'part sun':
      case 'partial sun':
      case 'part shade':
      case 'partial shade':
        return 'ظل جزئي';
      case 'full shade':
        return 'ظل كامل';
      case 'medium':
      case 'moderate':
      case 'medium light':
        return 'متوسط';
      case 'low':
      case 'low light':
        return 'منخفض';
      case 'high':
      case 'high light':
        return 'مرتفع';
      default:
        return value;
    }
  }
  String _careTitle(String value) {
    switch (value.toLowerCase()) {
      case 'watering':
        return 'الري';
      case 'sunlight':
        return 'الإضاءة';
      case 'pruning':
        return 'التقليم';
      default:
        return value;
    }
  }
  // Format numeric ranges in Arabic while preserving their original order.
  String _arabicRange(String value) {
    final text = value.trim();
    final range = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*(?:-|–|—|to|إلى)\s*(\d+(?:[.,]\d+)?)\s*(m|meter|meters|م)?\.?$',
      caseSensitive: false,
    ).firstMatch(text);

    if (range != null) {
      final from = range.group(1)!;
      final to = range.group(2)!;
      final unit = range.group(3) == null ? '' : ' م';
      // Directional isolation prevents reversed numbers in the RTL layout.
      return 'من \u2066$from\u2069 إلى \u2066$to\u2069$unit';
    }

    return text
        .replaceAll(RegExp(r'\bto\b', caseSensitive: false), 'إلى')
        .replaceAll(RegExp(r'\bm\b', caseSensitive: false), 'م');
  }

  // Keep temperature values and Celsius units readable inside RTL text.
  String _temperatureRange(Plant plant) {
    final min = plant.minTemperatureC;
    final max = plant.maxTemperatureC;
    if (min != null && max != null) {
      return '\u2066$min°C\u2069 إلى \u2066$max°C\u2069';
    }
    if (min != null) return '\u2066$min°C\u2069';
    if (max != null) return '\u2066$max°C\u2069';
    return '';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _lightSage,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: _green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
              style: GoogleFonts.cairo(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _darkGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCE4D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _lightSage,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _green, size: 21),
          ),
          const SizedBox(height: 9),
          Text(label,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              color: const Color(0xFF596C59),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value,
            softWrap: true,
            style: GoogleFonts.cairo(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: _darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoColumns(List<Widget> cards) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 330;
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      }
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final card in cards)
            SizedBox(width: (constraints.maxWidth - 10) / 2, child: card),
        ],
      );
    });
  }

  Widget _imageSection() {
    return Container(
      height: 228,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _lightSage,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<String?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }
          final imageUrl = snapshot.data;
          if (imageUrl == null || imageUrl.isEmpty) {
            return const Center(
              child: Icon(Icons.local_florist_outlined, size: 85, color: _sage),
            );
          }
          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            maxWidthDiskCache: 1000,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: _green),
            ),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.local_florist_outlined, size: 85, color: _sage),
            ),
          );
        },
      ),
    );
  }
  Widget _careGuideCard(Map<String, dynamic> guide) {
    final type = (guide['type'] ?? '').toString();
    final description = (guide['description'] ?? '').toString();
    if (description.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lightSage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _careTitle(type),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
          const SizedBox(height: 7),
          FutureBuilder<String>(
            future: _translationFor(description),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                );
              }
              final translated = snapshot.data?.trim() ?? '';
              final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(translated);
              if (snapshot.hasError || !hasArabic) {
                return Text(
                  'تعذّر عرض إرشادات العناية بالعربية حاليًا.',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(fontSize: 13, color: _sage),
                );
              }
              return Text(
                translated,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  height: 1.8,
                  color: Colors.black87,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final requirements = <Widget>[
      _requirementCard(
        icon: Icons.water_drop_outlined,
        label: 'احتياج الري',
        value: PlantDisplayFormatter.water(plant.wateringRequirement),
      ),
      _requirementCard(
        icon: Icons.wb_sunny_outlined,
        label: 'احتياج الإضاءة',
        value: _translateLight(plant.lightRequirement),
      ),
      _requirementCard(
        icon: Icons.spa_outlined,
        label: 'مستوى العناية',
        value: PlantDisplayFormatter.care(plant.careLevel),
      ),
      if (plant.climateToleranceClass != null)
        _requirementCard(
          icon: Icons.thermostat_outlined,
          label: 'تحمّل المناخ',
          value: PlantDisplayFormatter.tolerance(plant.climateToleranceClass),
        ),
    ];
    final extras = <Widget>[
      if (plant.matureHeight != null)
        _requirementCard(
          icon: Icons.height_rounded,
          label: 'الارتفاع عند النضج',
          value: _arabicRange(plant.matureHeight!),
        ),
      if (plant.matureSpread != null)
        _requirementCard(
          icon: Icons.open_in_full_rounded,
          label: 'الانتشار عند النضج',
          value: _arabicRange(plant.matureSpread!),
        ),
      if (plant.minTemperatureC != null || plant.maxTemperatureC != null)
        _requirementCard(
          icon: Icons.device_thermostat_outlined,
          label: 'نطاق درجات الحرارة',
          value: _temperatureRange(plant),
        ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: _background,
          surfaceTintColor: _background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          title: Text(
            'تفاصيل النبات',
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
            padding: const EdgeInsetsDirectional.only(start: 12),
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
                          color: _lightSage,
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
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _careFuture,
          builder: (context, snapshot) {
            final guides = snapshot.data ?? <Map<String, dynamic>>[];
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 30),
              children: [
                _imageSection(),
                const SizedBox(height: 18),
                Text(plant.displayName,
                  style: GoogleFonts.cairo(
                    fontSize: 25,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(plant.scientificName,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF596C59),
                  ),
                ),
                const SizedBox(height: 26),
                _sectionTitle('متطلبات النبات', Icons.eco_outlined),
                _twoColumns(requirements),
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: 27),
                  _sectionTitle('معلومات إضافية', Icons.info_outline_rounded),
                  _twoColumns(extras),
                ],
                const SizedBox(height: 27),
                _sectionTitle('إرشادات العناية', Icons.menu_book_outlined),
                if (snapshot.connectionState == ConnectionState.waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: _green),
                        const SizedBox(height: 12),
                        Text('جارٍ جلب إرشادات العناية بالنبات...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: const Color(0xFF596C59),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (guides.isNotEmpty)
                  ...guides.map(_careGuideCard)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0xFFDCE4D8)),
                    ),
                    child: Text('لا توجد إرشادات عناية متوفرة لهذا النبات حاليًا.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: const Color(0xFF596C59),
                      ),
                    ),
                  ),
                const SizedBox(height: 27),
                // The 2D preview is not implemented yet; keep it visibly disabled.
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.view_in_ar_outlined, size: 21),
                    label: Text('معاينة في حديقتي',
                      style: GoogleFonts.cairo(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: const Color(0xFF718271),
                      side: const BorderSide(color: Color(0xFFDCE4D8)),
                      backgroundColor: const Color(0xFFF0F3ED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSavingPlant ? null :
                        (_isSaved ? _removeFromMyPlants : _addToMyPlants),
                    icon: _isSavingPlant
                        ? const SizedBox(width: 19, height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Icon(_isSaved ? Icons.delete_outline_rounded
                            : Icons.add_circle_outline_rounded, size: 22),
                    label: Text(_isSaved ? 'حذف من نباتاتي' : 'إضافة إلى نباتاتي',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isSaved
                          ? const Color(0xFF9F342D) : _green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF819880),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
}
