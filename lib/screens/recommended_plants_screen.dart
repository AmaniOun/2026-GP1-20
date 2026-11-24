// Widgets used to show a plant image and its saved-to-My-Plants state.
import '../widgets/ruwa_saved_badge.dart';
import '../widgets/ruwa_plant_image.dart';

// Flutter UI components and the Cairo typeface used throughout the screen.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// App data models, recommendation logic, display formatting, and navigation.
import '../models/plant.dart';
import '../services/recommendation_engine.dart';
import '../utils/plant_display_formatter.dart';
import 'plant_details_screen.dart';

/// Displays personalized plant recommendations and explains each suitability score.
/// The screen supports filtering by climate tolerance without recalculating scores.
class RecommendedPlantsScreen extends StatefulWidget {
  const RecommendedPlantsScreen({super.key, this.initialResults});

  // Supplied by Home when already available; refresh still uses the engine.
  final RecommendationResults? initialResults;

  @override
  State<RecommendedPlantsScreen> createState() =>
      _RecommendedPlantsScreenState();
}

/// Holds the current filter and the asynchronous recommendation results.
class _RecommendedPlantsScreenState
    extends State<RecommendedPlantsScreen> {
  // Shared design colors keep the cards, labels, and buttons consistent.
  static const Color backgroundColor = Color(0xFFFAF9F4);
  static const Color greenColor = Color(0xFF315B32);
  static const Color darkGreenColor = Color(0xFF234525);
  static const Color sageColor = Color(0xFF6F8F64);
  static const Color lightSageColor = Color(0xFFE8F0E4);
  static const Color borderColor = Color(0xFFDCE4D8);
  static const Color secondaryTextColor = Color(0xFF555A52);

  // The future is reused by FutureBuilder and replaced when results are refreshed.
  late Future<RecommendationResults> _recommendationsFuture;
  String _filter = 'all'; // 'all', 'tolerant', or 'sensitive'.

  // Use preloaded Home results if supplied; otherwise request fresh results.
  @override
  void initState() {
    super.initState();
    if (widget.initialResults != null) {
      _recommendationsFuture = Future.value(widget.initialResults!);
    } else {
      _loadRecommendations();
    }
  }

  // Ask the shared engine to evaluate plants against the saved garden profile.
  void _loadRecommendations() {
    _recommendationsFuture =
        RecommendationEngine.instance.getRecommendations();
  }

  // Pull-to-refresh replaces the future and lets FutureBuilder redraw the UI.
  Future<void> _refresh() async {
    setState(_loadRecommendations);
    try {
      await _recommendationsFuture;
    } catch (_) {
      // The FutureBuilder below displays the error state.
    }
  }

  // Build a right-to-left layout for the Arabic application interface.
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        // Keep navigation and the page heading visible above the plant list.
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
                    // Return to the previous screen without altering any plant data.
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
        // Render loading, error, empty, or populated states from the future.
        body: FutureBuilder<RecommendationResults>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            // Avoid displaying stale content while the engine is loading.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: greenColor,
                ),
              );
            }

            // The user can retry when recommendation retrieval fails.
            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final results = snapshot.data;

            // Handle an unexpectedly missing result without crashing the screen.
            if (results == null) {
              return _buildEmptyState('تعذر تحميل النباتات حاليًا.');
            }

            // Combine the selected climate groups and rank all visible plants by score.
            // ListView.builder creates cards lazily, limiting simultaneous image requests.
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

            // Allow the user to request fresh recommendations by swiping down.
            return RefreshIndicator(
              color: greenColor,
              onRefresh: _refresh,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                // Reserve four slots for the introduction, spacing, and filter tabs.
                itemCount: 4 + (items.isEmpty ? 1 : items.length),
                itemBuilder: (context, index) {
                  // Explain why these plants appear in the personalized list.
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
                  // Insert the header spacing and climate-tolerance filter tabs.
                  if (index == 1) return const SizedBox(height: 12);
                  if (index == 2) return _filterTabs();
                  if (index == 3) return const SizedBox(height: 20);
                  // Show a filter-specific message when no matching plants remain.
                  if (items.isEmpty) {
                    return _buildSectionEmpty(
                      _filter == 'tolerant'
                          ? 'لا توجد نباتات مقاومة مطابقة حاليًا.'
                          : _filter == 'sensitive'
                              ? 'لا توجد نباتات حساسة مطابقة حاليًا.'
                              : 'لا توجد نباتات موصى بها لك حاليًا.',
                    );
                  }
                  // Convert the list index to a recommendation after header slots.
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

  // Switch between all plants, climate-tolerant plants, and climate-sensitive plants.
  Widget _filterTabs() {
    const options = [
      ('all', 'الكل'),
      ('tolerant', 'مقاوم'),
      ('sensitive', 'حساس'),
    ];
    return Row(
      children: options.map((option) {
        // Highlight the active filter; only the displayed items change.
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

  // Calculate the count for the active filter from the latest engine results.
  Widget _selectedFilterCount(RecommendationResults results) {
    final tolerantCount = results.tolerantPlants.length;
    final sensitiveCount = results.sensitivePlants.length;
    final count = switch (_filter) {
      'tolerant' => tolerantCount,
      'sensitive' => sensitiveCount,
      _ => tolerantCount + sensitiveCount,
    };
    // Select a localized count label matching the active climate group.
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


  // Delegate image retrieval and caching to the existing plant image widget.
  Widget _cachedPlantPhoto(String scientificName) =>
      RuwaPlantImage(scientificName: scientificName);

  // Crop each plant image to a consistent rounded square in the card.
  Widget _plantPhoto(Plant plant) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 112,
      height: 112,
      child: _cachedPlantPhoto(plant.scientificName),
    ),
  );

  // Optional introductory panel describing the recommendation criteria.
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

  // Optional reusable heading with an icon and an explanatory subtitle.
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

  // Render one plant, its climate group, suitability score, and explanation.
  Widget _buildPlantCard(
    Plant plant,
    double score, {
    required bool isSensitive,
    required List<String> matchedFactors,
    required List<String> partiallyMatchedFactors,
  }) {
    // The engine already calculates each factor; this screen only classifies
    // the labels for display and never changes the engine score or weights.
    final matchedOrPartiallyMatched = <String>{
      ...matchedFactors,
      ...partiallyMatchedFactors,
    };
    // Distinguish missing plant attributes from confirmed incompatibility.
    final factorsWithoutPlantData = <String>{
      if (plant.wateringRequirement.trim().isEmpty) 'الري',
      if (plant.lightRequirement.trim().isEmpty) 'الإضاءة',
      if (plant.careLevel.trim().isEmpty) 'العناية',
    };
    // A non-matching factor is neither matched nor partially matched,
    // and its plant-side requirement is present.
    final unmatchedFactors = <String>[
      for (final factor in const ['الري', 'الإضاءة', 'العناية'])
        if (!matchedOrPartiallyMatched.contains(factor) &&
            !factorsWithoutPlantData.contains(factor))
          factor,
    ];
    // Explain factors that could not be assessed due to missing plant data.
    final unavailableFactors = <String>[
      for (final factor in const ['الري', 'الإضاءة', 'العناية'])
        if (!matchedOrPartiallyMatched.contains(factor) &&
            factorsWithoutPlantData.contains(factor))
          factor,
    ];

    // Climate tolerance affects the badge styling, not the suitability score.
    final statusColor = isSensitive
        ? const Color(0xFF98691F)
        : greenColor;
    final statusBackground = isSensitive
        ? const Color(0xFFFFF0D7)
        : const Color(0xFFE1F2DE);

    return Container(
      // Keep recommended-plant cards visually separated in the scroll list.
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
              // Show the plant photo next to the name and climate label.
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
                    // Scientific names are shown only when available.
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
                      // Indicate whether the plant already belongs to My Plants.
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
          // Display the plant's own care, watering, and sunlight requirements.
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
              // Display the suitability percentage calculated by the engine.
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
                  // Convert the 0–100 score to a progress value between 0 and 1.
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
          // List factors that matched the garden requirements completely.
          Text('العوامل المتوافقة',
            style: GoogleFonts.cairo(
              color: darkGreenColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // A recommendation can have partial matches without full matches.
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
          // Present partial matches separately to avoid implying a full match.
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
          // Explain why a recommendation did not receive a perfect score.
          if (unmatchedFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('العوامل غير المتوافقة',
              style: GoogleFonts.cairo(
                color: const Color(0xFF8D443A),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: unmatchedFactors.map((factor) =>
                _factorChip(factor, unmatched: true),
              ).toList(),
            ),
          ],
          // Avoid treating unavailable source data as an explicit mismatch.
          if (unavailableFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('عوامل لا تتوفر بياناتها',
              style: GoogleFonts.cairo(
                color: secondaryTextColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: unavailableFactors.map((factor) =>
                _factorChip(factor, unavailable: true),
              ).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Open the existing plant-details screen for full plant information.
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

  // Build a compact chip for the plant's displayed characteristics.
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

  // Map each engine-provided factor label to an appropriate visual icon.
  IconData _factorIcon(String factor) {
    // Handle the Arabic labels used by Ruwa and optional English variants.
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

  // Render a compatibility factor using visual styles for its outcome.
  Widget _factorChip(
    String factor, {
    bool partial = false,
    bool unmatched = false,
    bool unavailable = false,
  }) {
    // Select colors for unavailable, incompatible, partial, or full matches.
    final Color accent = unavailable
        ? secondaryTextColor
        : unmatched
            ? const Color(0xFF9E493F)
            : partial
                ? const Color(0xFF8D702B)
                : greenColor;
    final Color chipBackground = unavailable
        ? const Color(0xFFF3F3F1)
        : unmatched
            ? const Color(0xFFFFF0ED)
            : partial
                ? const Color(0xFFFFF7E8)
                : const Color(0xFFF0F5ED);
    final Color chipBorder = unavailable
        ? const Color(0xFFE2E2DE)
        : unmatched
            ? const Color(0xFFF0D4CE)
            : partial
                ? const Color(0xFFEADDBB)
                : borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: chipBorder),
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
              color: unavailable || unmatched || partial
                  ? accent
                  : darkGreenColor,
            ),
          ),
        ],
      ),
    );
  }

  // Show an empty-results message without changing the current filter.
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

  // Show a generic empty state if no recommendation data is available.
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

  // Inform the user of loading failures and provide a retry action.
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
              // Retry by requesting a new future and rebuilding the screen.
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
