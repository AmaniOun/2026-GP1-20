
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garden_profile.dart';
import '../models/plant.dart';

class PlantService {
  PlantService._();

  static final PlantService instance = PlantService._();

  List<Plant>? _cache;

  // Load plants from Firestore and cache the results.
  Future<List<Plant>> loadPlants() async {
    if (_cache != null) return _cache!;

    final snapshot = await FirebaseFirestore.instance
        .collection('plants')
        .get();

    _cache = snapshot.docs.map((doc) {
      final raw = doc.data();

      final mapped = {
        'id': raw['Plant_ID'] ?? doc.id,
        'arabicName': raw['Arabic_Name'],
        'scientificName': raw['Scientific_Name'],
        'family': raw['Family'],
        'origin': raw['Origin'],
        'wateringRequirement': raw['Watering_Requirement'],
        'lightRequirement': raw['Light_Requirement'],
        'careLevel': raw['Care_Level'],
        'matureHeight': raw['Mature_Height'],
        'matureSpread': raw['Mature_Spread'],
        'minTemperatureC': raw['Min_Temperature_C'],
        'maxTemperatureC': raw['Max_Temperature_C'],
        'climateToleranceClass':
            raw['Climate_Tolerance'] ??
            raw['Climate_Tolerance_Class'],
        'recordType':
            raw['Recored_Type'] ?? raw['Record_Type'],
      };

      return Plant.fromJson(mapped);
    }).toList();

    return _cache!;
  }

  Future<List<Plant>> recommendForGarden(
    GardenProfile garden, {
    int limit = 10,
  }) async {
    final all = await loadPlants();

    final expectedCare =
        _careForPreference(garden.careLevel.arabicLabel);

    final scored = all
        .where((p) => p.arabicName.isNotEmpty)
        .map((p) {
      int score = 0;

      if (p.careLevel == expectedCare) score += 2;
      if (p.climateToleranceClass == 'Tolerant') score += 2;
      if (p.climateToleranceClass == 'Sensitive') score -= 2;

      return MapEntry(p, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  String _careForPreference(String careLevelArabicLabel) {
    switch (careLevelArabicLabel) {
      case 'قليلة':
        return 'Low';

      case 'عالية':
        return 'High';

      default:
        return 'Moderate';
    }
  }

  // Search by full or partial Arabic or scientific name.
  List<Plant> search(List<Plant> plants, String query) {
    final q = _normalize(query);

    if (q.isEmpty) return plants;

    return plants.where((p) {
      return _normalize(p.arabicName).contains(q) ||
          _normalize(p.scientificName).contains(q);
    }).toList();
  }

  // Filter plants by watering, climate tolerance and care.
  List<Plant> filter(
    List<Plant> plants, {
    String? water,
    String? tolerance,
    String? care,
  }) {
    return plants.where((p) {
      if (water != null &&
          p.wateringRequirement != water) {
        return false;
      }

      if (tolerance != null &&
          p.climateToleranceClass != tolerance) {
        return false;
      }

      if (care != null && p.careLevel != care) {
        return false;
      }

      return true;
    }).toList();
  }

  // Normalize search text.
  String _normalize(String s) {
    var t = s.trim().toLowerCase();

    t = t.replaceAll(RegExp('[ً-ٰٟـ]'), '');

    t = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');

    return t;
  }
}
