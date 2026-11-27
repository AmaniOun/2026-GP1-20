import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/garden_profile.dart';
import '../models/plant.dart';
import '../models/saved_plant.dart';
import 'plant_service.dart';

// ==========================================
// MyPlantService
// ==========================================
class MyPlantService {
  MyPlantService._();
  static final MyPlantService instance = MyPlantService._();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول حالياً');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _savedPlants =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('savedPlants');

  Future<bool> isAlreadySaved(Plant plant) async {
    final snapshot = await _savedPlants
        .where('plantId', isEqualTo: plant.id)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> addPlant(Plant plant) async {
    if (await isAlreadySaved(plant)) return false;

    final saved = SavedPlant(
      savedPlantId: '',
      plantId: plant.id,
      addedAt: DateTime.now(),
    );
    await _savedPlants.add(saved.toMap());
    return true;
  }

  Future<List<Plant>> getMyPlants() async {
    final snapshot =
        await _savedPlants.orderBy('addedAt', descending: true).get();
    final allPlants = await PlantService.instance.loadPlants();

    final result = <Plant>[];
    for (final doc in snapshot.docs) {
      final saved = SavedPlant.fromMap(doc.id, doc.data());
      for (final plant in allPlants) {
        if (plant.id == saved.plantId) {
          result.add(plant);
          break;
        }
      }
    }
    return result;
  }

  // حذف النبتة من نباتاتي (يحذف سجل SavedPlant الخاص بها).
  Future<void> removePlant(Plant plant) async {
    final snapshot =
        await _savedPlants.where('plantId', isEqualTo: plant.id).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Checks garden-specific constraints using the same matching rules as
  /// RecommendationEngine. Climate tolerance is deliberately excluded: it
  /// describes general adaptation to Riyadh rather than this garden's fit.
  ///
  /// Missing watering, light, care, or spread information is not presented as
  /// a confirmed mismatch. Optional watering preference is also skipped.
  List<String> unsuitableReasons(Plant plant, GardenProfile garden) {
    final reasons = <String>[];

    // The engine compares mature spread with the smaller garden dimension.
    // A missing or unparseable spread cannot establish a space mismatch.
    final availableSpace = garden.lengthMeters < garden.widthMeters
        ? garden.lengthMeters
        : garden.widthMeters;
    final spread = _parseNumber(plant.matureSpread);
    if (spread != null && spread > availableSpace) {
      reasons.add('انتشار النبات عند النضج يتجاوز مساحة الزراعة المتاحة');
    }

    // Check watering compatibility using exact category matching.
if (_hasKnownValue(plant.wateringRequirement) &&
    !_sameCategory(
      plant.wateringRequirement,
      garden.wateringLevel.name,
      low: const ['low', 'low watering', 'low water', 'منخفض', 'قليل', 'قليلة'],
      medium: const ['medium', 'moderate', 'moderate watering', 'متوسط', 'متوسطة'],
      high: const ['high', 'high watering', 'high water', 'مرتفع', 'عالي', 'عالية'],
    )) {
  reasons.add('متطلبات الري لا تتوافق مع مستوى الري المفضل لحديقتك');
}

    // Use the same facade-to-sunlight mapping as RecommendationEngine.
    // Do not treat missing plant light information as a confirmed mismatch.
    if (_hasKnownValue(plant.lightRequirement)) {
      final expectedLight = switch (garden.facadeDirection) {
        FacadeDirection.north => 'shade',
        FacadeDirection.south || FacadeDirection.west => 'fullsun',
        FacadeDirection.east => 'partialsun',
      };
      if (_normalizeLight(plant.lightRequirement) != expectedLight) {
        reasons.add('احتياجات الإضاءة لا تتوافق مع اتجاه واجهة حديقتك');
      }
    }

    // Match care categories exactly as the recommendation engine does.
    // Lower care requirements are not automatically scored as a full match.
    if (_hasKnownValue(plant.careLevel) &&
        !_sameCategory(
          plant.careLevel,
          garden.careLevel.name,
          low: const ['low', 'easy', 'low maintenance', 'قليل', 'قليلة'],
          medium: const ['medium', 'moderate', 'متوسط', 'متوسطة'],
          high: const ['high', 'difficult', 'high maintenance', 'مرتفع', 'عالية'],
        )) {
      reasons.add('متطلبات العناية لا تتوافق مع مستوى العناية المفضل لحديقتك');
    }

    return reasons;
  }

  /// A general climate caution, not proof that the plant is unsuitable for
  /// a particular garden. The UI displays this separately from garden issues.
  bool isClimateSensitive(Plant plant) {
    final value = _normalize(plant.climateToleranceClass ?? '');
    return value == 'sensitive' ||
        value == 'غيرمقاوم' ||
        value == 'حساس' ||
        value == 'حساسة';
  }

  /// Do not invent a mismatch when the source has no usable information.
  bool _hasKnownValue(String value) {
    final normalized = _normalize(value);
    return normalized.isNotEmpty &&
        !const {'na', 'null', 'unknown', 'notavailable', 'غيرمتوفر'}
            .contains(normalized);
  }

  /// Mirrors the engine's low / medium / high category aliases.
  bool _sameCategory(
    String first,
    String second, {
    required List<String> low,
    required List<String> medium,
    required List<String> high,
  }) {
    String? category(String value) {
      final normalized = _normalize(value);
      if (low.any((v) => _normalize(v) == normalized)) return 'low';
      if (medium.any((v) => _normalize(v) == normalized)) return 'medium';
      if (high.any((v) => _normalize(v) == normalized)) return 'high';
      return null;
    }

    final firstCategory = category(first);
    return firstCategory != null && firstCategory == category(second);
  }

  /// Mirrors the engine's normalization of Full Sun / Partial Shade / Shade.
  String _normalizeLight(String value) {
    final light = _normalize(value);
    if (const ['shade', 'fullshade', 'ظل', 'ظليل'].contains(light)) {
      return 'shade';
    }
    if (const [
      'partialsun', 'partialshade', 'partialsunlight', 'شمسجزئية', 'ظلجزئي'
    ].contains(light)) {
      return 'partialsun';
    }
    if (const [
      'fullsun', 'directsun', 'fullsunlight', 'شمسكاملة', 'شمس'
    ].contains(light)) {
      return 'fullsun';
    }
    return light;
  }

  /// The same basic text normalization used by RecommendationEngine.
  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .replaceAll('/', '');

  /// Supports values such as "2.5 m", "2.5m", or "2.5".
  double? _parseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(value.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }
}
