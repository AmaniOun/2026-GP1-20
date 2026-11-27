
import '../models/garden_profile.dart';
import '../models/plant.dart';
import 'garden_service.dart';
import 'plant_service.dart';

class PlantRecommendation {
  final Plant plant;
  final double score;
  final List<String> matchedFactors;

  const PlantRecommendation({
    required this.plant,
    required this.score,
    this.matchedFactors = const [],
  });
}

class RecommendationResults {
  final List<PlantRecommendation> tolerantPlants;
  final List<PlantRecommendation> sensitivePlants;

  const RecommendationResults({
    required this.tolerantPlants,
    required this.sensitivePlants,
  });
}

class RecommendationEngine {
  RecommendationEngine._();

  static final RecommendationEngine instance =
      RecommendationEngine._();

  Future<RecommendationResults> getRecommendations() async {
    // Read the saved garden profile.
    final GardenProfile? garden =
        await GardenService.instance.getGarden();

    if (garden == null) {
      throw Exception('لم يتم العثور على بيانات الحديقة.');
    }

    // Load plants from Firestore through PlantService.
    final List<Plant> plants =
        await PlantService.instance.loadPlants();

    final double availableSpace =
        garden.lengthMeters < garden.widthMeters
            ? garden.lengthMeters
            : garden.widthMeters;

    final List<PlantRecommendation> tolerant = [];
    final List<PlantRecommendation> sensitive = [];

    for (final Plant plant in plants) {
      // Exclude plants that exceed the available garden dimension.
      final double? spread =
          _parseNumber(plant.matureSpread);

      if (spread != null && spread > availableSpace) {
        continue;
      }

      // Evaluate the three compatibility factors.
      final bool wateringCompatibility =
          _wateringCompatibility(plant, garden);

      final bool sunlightCompatibility =
          _sunlightCompatibility(plant, garden);

      final bool careCompatibility =
          _careCompatibility(plant, garden);

      // All three factors have equal weight.
      final double score = (
        (
          (wateringCompatibility ? 1 : 0) +
          (sunlightCompatibility ? 1 : 0) +
          (careCompatibility ? 1 : 0)
        ) / 3
      ) * 100;

      // Exclude plants with zero suitability.
      if (score <= 0) {
        continue;
      }

      // Record matching factors for the recommendation explanation.
      final matchedFactors = <String>[
        if (wateringCompatibility) 'الري',
        if (sunlightCompatibility) 'الإضاءة',
        if (careCompatibility) 'العناية',
      ];

      final recommendation = PlantRecommendation(
        plant: plant,
        score: score,
        matchedFactors: matchedFactors,
      );

      // Group recommendations by climate tolerance.
      final String climateClass =
          _normalize(plant.climateToleranceClass ?? '');

      if (_isTolerant(climateClass)) {
        tolerant.add(recommendation);
      } else if (_isSensitive(climateClass)) {
        sensitive.add(recommendation);
      }
    }

    // Highest score first in both groups.
    tolerant.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    sensitive.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return RecommendationResults(
      tolerantPlants: tolerant,
      sensitivePlants: sensitive,
    );
  }

  bool _wateringCompatibility(
    Plant plant,
    GardenProfile garden,
  ) {
    final String plantWatering =
        _normalize(plant.wateringRequirement);

    final String gardenWatering =
        _normalize(garden.wateringLevel.name);

    if (plantWatering.isEmpty) return false;

    return _sameCategory(
      plantWatering,
      gardenWatering,
      low: const [
        'low',
        'low watering',
        'low water',
        'منخفض',
        'قليل',
        'قليلة',
      ],
      medium: const [
        'medium',
        'moderate',
        'moderate watering',
        'متوسط',
        'متوسطة',
      ],
      high: const [
        'high',
        'high watering',
        'high water',
        'مرتفع',
        'عالي',
        'عالية',
      ],
    );
  }

  bool _sunlightCompatibility(
    Plant plant,
    GardenProfile garden,
  ) {
    final String plantLight =
        _normalize(plant.lightRequirement);

    if (plantLight.isEmpty) return false;

    final String expectedLight;

    switch (garden.facadeDirection) {
      case FacadeDirection.north:
        expectedLight = 'shade';
        break;

      case FacadeDirection.south:
      case FacadeDirection.west:
        expectedLight = 'fullsun';
        break;

      case FacadeDirection.east:
        expectedLight = 'partialsun';
        break;
    }

    final String normalizedLight =
        _normalizeLight(plantLight);

    return normalizedLight == expectedLight;
  }

  bool _careCompatibility(
    Plant plant,
    GardenProfile garden,
  ) {
    final String plantCare =
        _normalize(plant.careLevel);

    final String gardenCare =
        _normalize(garden.careLevel.name);

    if (plantCare.isEmpty) return false;

    return _sameCategory(
      plantCare,
      gardenCare,
      low: const [
        'low',
        'easy',
        'low maintenance',
        'قليل',
        'قليلة',
      ],
      medium: const [
        'medium',
        'moderate',
        'متوسط',
        'متوسطة',
      ],
      high: const [
        'high',
        'difficult',
        'high maintenance',
        'مرتفع',
        'عالية',
      ],
    );
  }

  bool _sameCategory(
    String first,
    String second, {
    required List<String> low,
    required List<String> medium,
    required List<String> high,
  }) {
    String? category(String value) {
      if (low.any((v) => _normalize(v) == value)) {
        return 'low';
      }

      if (medium.any((v) => _normalize(v) == value)) {
        return 'medium';
      }

      if (high.any((v) => _normalize(v) == value)) {
        return 'high';
      }

      return null;
    }

    final firstCategory = category(first);
    final secondCategory = category(second);

    return firstCategory != null &&
        firstCategory == secondCategory;
  }

  String _normalizeLight(String value) {
    final String light = _normalize(value);

    if ([
      'shade',
      'fullshade',
      'ظل',
      'ظليل',
    ].contains(light)) {
      return 'shade';
    }

    if ([
      'partialsun',
      'partialshade',
      'partialsunlight',
      'شمسجزئية',
      'ظلجزئي',
    ].contains(light)) {
      return 'partialsun';
    }

    if ([
      'fullsun',
      'directsun',
      'fullsunlight',
      'شمسكاملة',
      'شمس',
    ].contains(light)) {
      return 'fullsun';
    }

    return light;
  }

  bool _isTolerant(String value) {
    return value == 'tolerant' ||
        value == 'resistant' ||
        value == 'مقاوم' ||
        value == 'مقاومة';
  }

  bool _isSensitive(String value) {
    return value == 'sensitive' ||
        value == 'غيرمقاوم' ||
        value == 'حساس' ||
        value == 'حساسة';
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('/', '');
  }

  double? _parseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'-?\d+(\.\d+)?')
        .firstMatch(value.trim());

    if (match == null) return null;

    return double.tryParse(match.group(0)!);
  }
}
