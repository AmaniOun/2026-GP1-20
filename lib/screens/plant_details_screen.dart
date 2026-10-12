
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/perenual_service.dart';

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
  static const Color _gold = Color(0xFFE9B84F);

  late final Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = PerenualService.instance.getPlantDetails(
      widget.plant.scientificName,
    );
  }

  String _translateLevel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'low':
      return 'منخفض';
    case 'moderate':
    case 'medium':
      return 'متوسط';
    case 'high':
      return 'مرتفع';
    case 'highly tolerant':
      return 'عالي التحمل';
    case 'moderately tolerant':
      return 'متوسط التحمل';
    case 'poorly tolerant':
      return 'ضعيف التحمل';
    default:
      return value;
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

  Widget _imageSection(String? imageUrl) {
    return Container(
      height: 245,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _lightSage,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.local_florist_outlined,
                size: 85,
                color: _sage,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Icon(
                    Icons.local_florist_outlined,
                    size: 85,
                    color: _sage,
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
          Text(
            description,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.8,
              color: Colors.black87,
            ),
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
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final details = snapshot.data;
            final imageUrl = details?['imageUrl'] as String?;
            final guides =
                (details?['careGuides'] as List?)
                    ?.whereType<Map<String, dynamic>>()
                    .toList() ??
                [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                _imageSection(imageUrl),
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
                  value: _translateLevel(
                    plant.wateringRequirement,
                  ),
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
                  value: _translateLevel(plant.careLevel),
                ),

                if (plant.climateToleranceClass != null) ...[
                  const SizedBox(height: 10),
                  _requirementCard(
                    icon: Icons.thermostat_outlined,
                    label: 'تحمل المناخ',
                    value: _translateLevel(
                      plant.climateToleranceClass!,
                    ),
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
                      value: plant.matureHeight!,
                    ),
                  if (plant.matureSpread != null) ...[
                    const SizedBox(height: 10),
                    _requirementCard(
                      icon: Icons.open_in_full,
                      label: 'الانتشار عند النضج',
                      value: plant.matureSpread!,
                    ),
                  ],
                  if (plant.minTemperatureC != null ||
                      plant.maxTemperatureC != null) ...[
                    const SizedBox(height: 10),
                    _requirementCard(
                      icon: Icons.device_thermostat,
                      label: 'درجات الحرارة',
                      value: [
                        if (plant.minTemperatureC != null)
                          '${plant.minTemperatureC}°C',
                        if (plant.maxTemperatureC != null)
                          '${plant.maxTemperatureC}°C',
                      ].join(' – '),
                    ),
                  ],
                ],

                if (snapshot.connectionState ==
                    ConnectionState.waiting) ...[
                  const SizedBox(height: 28),
                  const Center(
                    child: CircularProgressIndicator(
                      color: _green,
                    ),
                  ),
                ],

                if (guides.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _sectionTitle('إرشادات العناية'),
                  ...guides.map(_careGuideCard),
                ],

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
