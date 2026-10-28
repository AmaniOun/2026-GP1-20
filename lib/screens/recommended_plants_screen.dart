
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/recommendation_engine.dart';
import 'plant_details_screen.dart';
import '../services/plant_translation_service.dart';
import '../utils/plant_display_formatter.dart';

class RecommendedPlantsScreen extends StatefulWidget {
  const RecommendedPlantsScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
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
          backgroundColor: backgroundColor,
          foregroundColor: darkGreenColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'النباتات المقترحة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
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
              return _buildEmptyState(
                'تعذر تحميل النباتات حاليًا.',
              );
            }

            return RefreshIndicator(
              color: greenColor,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _buildIntro(),

                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    title: 'النباتات المقاومة لمناخ الرياض',
                    subtitle:
                    'نباتات مصنّفة على أنها مقاومة، مرتبة حسب توافقها مع حديقتك.',
                    count: results.tolerantPlants.length,
                    icon: Icons.check_circle_outline,
                    color: greenColor,
                  ),

                  const SizedBox(height: 12),

                  if (results.tolerantPlants.isEmpty)
                    _buildSectionEmpty(
                      'لا توجد نباتات مقاومة مطابقة للشروط الحالية.',
                    )
                  else
                    ...results.tolerantPlants.map(
                          (recommendation) => _buildPlantCard(
                        recommendation.plant,
                        recommendation.score,
                        isSensitive: false,
                      ),
                    ),

                  const SizedBox(height: 28),

                  _buildSectionHeader(
                    title: 'النباتات الحساسة',
                    subtitle:
                    'نباتات مصنّفة على أنها حساسة لمناخ الرياض. اعرضيها للمقارنة فقط.',
                    count: results.sensitivePlants.length,
                    icon: Icons.info_outline,
                    color: const Color(0xFF9A6A32),
                  ),

                  const SizedBox(height: 12),

                  if (results.sensitivePlants.isEmpty)
                    _buildSectionEmpty(
                      'لا توجد نباتات حساسة مطابقة للشروط الحالية.',
                    )
                  else
                    ...results.sensitivePlants.map(
                          (recommendation) => _buildPlantCard(
                        recommendation.plant,
                        recommendation.score,
                        isSensitive: true,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightSageColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco_outlined,
                color: greenColor,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'اختيارات تناسب حديقتك',
                  style: TextStyle(
                    color: darkGreenColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'تُرتّب النباتات حسب توافق متطلبات الري والإضاءة '
                'ومستوى العناية مع بيانات حديقتك.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required int count,
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
                style: const TextStyle(
                  color: darkGreenColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(
      Plant plant,
      double score, {
        required bool isSensitive,
      }) {
    final Color statusColor = isSensitive
        ? const Color(0xFF9A6A32)
        : greenColor;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlantDetailsScreen(plant: plant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: lightSageColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_florist_outlined,
                  color: greenColor,
                  size: 30,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.displayName,
                      style: const TextStyle(
                        color: darkGreenColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (plant.scientificName.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plant.scientificName,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildInfoChip(
                          icon: Icons.water_drop_outlined,
                          label: 'الري: ${PlantDisplayFormatter.water(plant.wateringRequirement)}',
                        ),
                        _buildInfoChip(
                          icon: Icons.wb_sunny_outlined,
                          label: 'الإضاءة: ${PlantDisplayFormatter.light(plant.lightRequirement)}',
                        ),
                        _buildInfoChip(
                          icon: Icons.spa_outlined,
                          label: 'العناية: ${PlantDisplayFormatter.care(plant.careLevel)}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          isSensitive
                              ? Icons.info_outline
                              : Icons.check_circle_outline,
                          color: statusColor,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isSensitive
                                ? 'مصنّف كنبات حساس'
                                : 'مصنّف كنبات مقاوم',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${score.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: lightSageColor,
                        color: statusColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'اضغطي لعرض التفاصيل',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: sageColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
              ),
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
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 13,
          height: 1.6,
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
              style: const TextStyle(
                color: secondaryTextColor,
                height: 1.6,
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
            const Text(
              'تعذّر تحميل التوصيات. تأكدي من اتصالك بالإنترنت وحاولي مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(_loadRecommendations);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
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
