import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant.dart';
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
    switch (value.toLowerCase()) {
      case 'full sun':
        return 'شمس كاملة';
      case 'part shade':
      case 'partial shade':
        return 'ظل جزئي';
      case 'full shade':
        return 'ظل كامل';
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
  // تعريب فاصل المدى القادم من قاعدة البيانات دون تغيير القيمة الأصلية.
  String _arabicRange(String value) {
    return value
        .replaceAll(RegExp(r'\bto\b', caseSensitive: false), 'إلى')
        .replaceAll(RegExp(r'\bm\b', caseSensitive: false), 'م');
  }

  // عزل كل درجة باتجاه LTR يبقي الأرقام ووحدة °C سليمة داخل واجهة RTL.
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _darkGreen,
        ),
      ),
    );
  }
  Widget _requirementCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lightSage),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _lightSage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _imageSection() {
    return Container(
      height: 245,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _lightSage,
        borderRadius: BorderRadius.circular(24),
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
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.local_florist_outlined, size: 85, color: _sage),
              );
            },
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
                  fontSize: 13,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          surfaceTintColor: _background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تفاصيل النبات',
            style: GoogleFonts.cairo(
              color: _darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _darkGreen,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _careFuture,
          builder: (context, snapshot) {
            final guides = snapshot.data ?? <Map<String, dynamic>>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                _imageSection(),
                const SizedBox(height: 20),
                Text(
                  plant.displayName,
                  style: GoogleFonts.cairo(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
                Text(
                  plant.scientificName,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _sage,
                  ),
                ),
                const SizedBox(height: 26),
                _sectionTitle('متطلبات النبات'),
                _requirementCard(
                  icon: Icons.water_drop_outlined,
                  label: 'احتياج الري',
                  value: PlantDisplayFormatter.water(plant.wateringRequirement),
                ),
                const SizedBox(height: 10),
                _requirementCard(
                  icon: Icons.wb_sunny_outlined,
                  label: 'احتياج الإضاءة',
                  value: _translateLight(
                    plant.lightRequirement,
                  ),
                ),
                const SizedBox(height: 10),
                _requirementCard(
                  icon: Icons.spa_outlined,
                  label: 'مستوى العناية',
                  value: PlantDisplayFormatter.care(plant.careLevel),
                ),
                if (plant.climateToleranceClass != null) ...[
                  const SizedBox(height: 10),
                  _requirementCard(
                    icon: Icons.thermostat_outlined,
                    label: 'تحمل المناخ',
                    value: PlantDisplayFormatter.tolerance(plant.climateToleranceClass),
                  ),
                ],
                if (plant.matureHeight != null ||
                    plant.matureSpread != null ||
                    plant.minTemperatureC != null ||
                    plant.maxTemperatureC != null) ...[
                  const SizedBox(height: 26),
                  _sectionTitle('معلومات إضافية'),
                  if (plant.matureHeight != null)
                    _requirementCard(
                      icon: Icons.height,
                      label: 'الارتفاع عند النضج',
                      value: _arabicRange(plant.matureHeight!),
                    ),
                  if (plant.matureSpread != null) ...[
                    const SizedBox(height: 10),
                    _requirementCard(
                      icon: Icons.open_in_full,
                      label: 'الانتشار عند النضج',
                      value: _arabicRange(plant.matureSpread!),
                    ),
                  ],
                  if (plant.minTemperatureC != null ||
                      plant.maxTemperatureC != null) ...[
                    const SizedBox(height: 10),
                    _requirementCard(
                      icon: Icons.device_thermostat,
                      label: 'درجات الحرارة',
                      value: _temperatureRange(plant),
                    ),
                  ],
                ],
                const SizedBox(height: 28),
                _sectionTitle('إرشادات العناية'),
                if (snapshot.connectionState == ConnectionState.waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: _green),
                        const SizedBox(height: 12),
                        Text(
                          'جارٍ جلب إرشادات العناية بالنبات...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: _sage,
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _lightSage),
                    ),
                    child: Text(
                      'لا توجد إرشادات عناية متوفرة لهذا النبات حاليًا.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: _sage,
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: Text(
                      'معاينة في حديقتي',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _lightSage,
                      disabledForegroundColor: _sage,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      'إضافة إلى نباتاتي',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
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
