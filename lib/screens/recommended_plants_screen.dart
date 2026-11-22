import '../widgets/ruwa_saved_badge.dart';
import '../widgets/ruwa_plant_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/recommendation_engine.dart';
import '../utils/plant_display_formatter.dart';
import 'plant_details_screen.dart';

class RecommendedPlantsScreen extends StatefulWidget {
  const RecommendedPlantsScreen({super.key, this.initialResults});

  // Supplied by Home when already available; refresh still uses the engine.
  final RecommendationResults? initialResults;

  @override
  State<RecommendedPlantsScreen> createState() =>
      _RecommendedPlantsScreenState();
}

class _RecommendedPlantsScreenState
    extends State<RecommendedPlantsScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F4);
  static const Color greenColor = Color(0xFF315B32);
  static const Color darkGreenColor = Color(0xFF234525);
  static const Color sageColor = Color(0xFF6F8F64);
  static const Color lightSageColor = Color(0xFFE8F0E4);
  static const Color borderColor = Color(0xFFDCE4D8);
  static const Color secondaryTextColor = Color(0xFF555A52);

  late Future<RecommendationResults> _recommendationsFuture;
  String _filter = 'all'; // all, tolerant, sensitive

  @override
  void initState() {
    super.initState();
    if (widget.initialResults != null) {
      _recommendationsFuture = Future.value(widget.initialResults!);
    } else {
      _loadRecommendations();
    }
  }

  void _loadRecommendations() {
    _recommendationsFuture =
        RecommendationEngine.instance.getRecommendations();
  }

  Future<void> _refresh() async {
    setState(_loadRecommendations);
    try {
      await _recommendationsFuture;
    } catch (_) {
      // The FutureBuilder below displays the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          toolbarHeight: 68,
          backgroundColor: backgroundColor,
          surfaceTintColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          title: Text(
            'النباتات الموصى بها لك',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: darkGreenColor,
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
                          color: lightSageColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Directionality(
                          textDirection: TextDirection.ltr,
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: greenColor,
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
        body: FutureBuilder<RecommendationResults>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: greenColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final results = snapshot.data;

            if (results == null) {
              return _buildEmptyState('تعذر تحميل النباتات حاليًا.');
            }

            // Build only the cards that enter the viewport; avoids queuing
            // image API requests for all 137 plants at once.
            final items = [
              if (_filter != 'sensitive')
                ...results.tolerantPlants.map(
                  (r) => (recommendation: r, sensitive: false),
                ),
              if (_filter != 'tolerant')
                ...results.sensitivePlants.map(
                  (r) => (recommendation: r, sensitive: true),
                ),
            ]..sort((a, b) => b.recommendation.score
                .compareTo(a.recommendation.score));

            return RefreshIndicator(
              color: greenColor,
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: 4 + (items.isEmpty ? 1 : items.length),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 4, 6),
                      child: Text(
                        'نباتات تناسب ظروف حديقتك بناءً على موقعك وإعداداتك.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    );
                  }
                  if (index == 1) return const SizedBox(height: 12);
                  if (index == 2) return _filterTabs();
                  if (index == 3) return const SizedBox(height: 20);
                  if (items.isEmpty) {
                    return _buildSectionEmpty(
                      _filter == 'tolerant'
                          ? 'لا توجد نباتات مقاومة مطابقة حاليًا.'
                          : _filter == 'sensitive'
                              ? 'لا توجد نباتات حساسة مطابقة حاليًا.'
                              : 'لا توجد نباتات موصى بها لك حاليًا.',
                    );
                  }
                  final item = items[index - 4];
                  return _buildPlantCard(
                    item.recommendation.plant,
                    item.recommendation.score,
                    matchedFactors: item.recommendation.matchedFactors,
                    partiallyMatchedFactors:
                        item.recommendation.partiallyMatchedFactors,
                    isSensitive: item.sensitive,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filterTabs() {
    const options = [
      ('all', 'الكل'),
      ('tolerant', 'مقاوم'),
      ('sensitive', 'حساس'),
    ];
    return Row(
      children: options.map((option) {
        final selected = _filter == option.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => _filter = option.$1),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? greenColor : backgroundColor,
                  border: Border.all(color: selected ? greenColor : borderColor, width: 1.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(option.$2, style: GoogleFonts.cairo(
                  color: selected ? Colors.white : darkGreenColor,
                  fontSize: 14, fontWeight: FontWeight.w700,
                )),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // دائرة واحدة للعدد، محسوبة من آخر نتائج RecommendationEngine.
  Widget _selectedFilterCount(RecommendationResults results) {
    final tolerantCount = results.tolerantPlants.length;
    final sensitiveCount = results.sensitivePlants.length;
    final count = switch (_filter) {
      'tolerant' => tolerantCount,
      'sensitive' => sensitiveCount,
      _ => tolerantCount + sensitiveCount,
    };
    final title = switch (_filter) {
      'tolerant' => 'عدد النباتات المقاومة',
      'sensitive' => 'عدد النباتات الحساسة',
      _ => 'إجمالي النباتات الموصى بها لك',
    };
    return Row(
      children: [
        Expanded(
          child: Text(title,
            style: GoogleFonts.cairo(
              color: darkGreenColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: lightSageColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
            style: GoogleFonts.cairo(
              color: greenColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }


  Widget _cachedPlantPhoto(String scientificName) =>
      RuwaPlantImage(scientificName: scientificName);

  Widget _plantPhoto(Plant plant) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 112,
      height: 112,
      child: _cachedPlantPhoto(plant.scientificName),
    ),
  );

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightSageColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                color: greenColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'اختيارات تناسب حديقتك',
                  style: GoogleFonts.cairo(
                    color: darkGreenColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تُرتّب النباتات حسب توافق متطلبات الري والإضاءة '
            'ومستوى العناية مع بيانات حديقتك.',
            style: GoogleFonts.cairo(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: darkGreenColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  color: secondaryTextColor,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(
    Plant plant,
    double score, {
    required bool isSensitive,
    required List<String> matchedFactors,
    required List<String> partiallyMatchedFactors,
  }) {
    // Keep RecommendationEngine scores and factor lists unchanged.
    final statusColor = isSensitive
        ? const Color(0xFF98691F)
        : greenColor;
    final statusBackground = isSensitive
        ? const Color(0xFFFFF0D7)
        : const Color(0xFFE1F2DE);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _plantPhoto(plant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: darkGreenColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    if (plant.scientificName.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        plant.scientificName,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RuwaSavedBadge(plantId: plant.id),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.thermostat_outlined,
                                size: 17, color: statusColor),
                            const SizedBox(width: 5),
                            Text(isSensitive ? 'حساس' : 'مقاوم',
                              style: GoogleFonts.cairo(
                                color: statusColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.spa_outlined,
                label: PlantDisplayFormatter.care(plant.careLevel),
              ),
              _buildInfoChip(
                icon: Icons.water_drop_outlined,
                label: PlantDisplayFormatter.water(plant.wateringRequirement),
              ),
              _buildInfoChip(
                icon: Icons.wb_sunny_outlined,
                label: PlantDisplayFormatter.light(plant.lightRequirement),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: borderColor, thickness: 1, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('نسبة التوافق',
                style: GoogleFonts.cairo(
                  color: secondaryTextColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: lightSageColor,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Text('${score.toStringAsFixed(0)}%',
                textDirection: TextDirection.ltr,
                style: GoogleFonts.cairo(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('العوامل المتوافقة',
            style: GoogleFonts.cairo(
              color: darkGreenColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (matchedFactors.isEmpty)
            Text('لا يوجد توافق كامل',
              style: GoogleFonts.cairo(color: secondaryTextColor, fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: matchedFactors.map((factor) =>
                _factorChip(factor),
              ).toList(),
            ),
          if (partiallyMatchedFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('توافق جزئي في',
              style: GoogleFonts.cairo(
                color: secondaryTextColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: partiallyMatchedFactors.map((factor) =>
                _factorChip(factor, partial: true),
              ).toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantDetailsScreen(plant: plant),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: lightSageColor,
                foregroundColor: darkGreenColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('عرض التفاصيل',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: greenColor),
          const SizedBox(width: 5),
          Text(label,
            style: GoogleFonts.cairo(
              color: darkGreenColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Factor labels come directly from RecommendationEngine; only their appearance changes.
  IconData _factorIcon(String factor) {
    final normalized = factor.trim().toLowerCase();
    if (normalized.contains('ري') || normalized.contains('ماء') ||
        normalized.contains('سقي') || normalized.contains('water')) {
      return Icons.water_drop_outlined;
    }
    if (normalized.contains('إضاءة') || normalized.contains('اضاءة') ||
        normalized.contains('شمس') || normalized.contains('ضوء') ||
        normalized.contains('light') || normalized.contains('sun')) {
      return Icons.wb_sunny_outlined;
    }
    if (normalized.contains('عناية') || normalized.contains('care') ||
        normalized.contains('صيانة')) {
      return Icons.spa_outlined;
    }
    return Icons.check_circle_outline_rounded;
  }

  Widget _factorChip(String factor, {bool partial = false}) {
    final accent = partial ? const Color(0xFF8D702B) : greenColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: partial ? const Color(0xFFFFF7E8) : const Color(0xFFF0F5ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: partial ? const Color(0xFFEADDBB) : borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_factorIcon(factor), size: 17, color: accent),
          const SizedBox(width: 5),
          Text(factor,
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: partial ? const Color(0xFF765C25) : darkGreenColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          color: secondaryTextColor,
          fontSize: 13,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.eco_outlined,
              size: 52,
              color: sageColor,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: secondaryTextColor,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFF9A6A32),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذّر تحميل التوصيات. تأكدي من اتصالك بالإنترنت وحاولي مرة أخرى.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: secondaryTextColor,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(_loadRecommendations);
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: greenColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
