
 // ============================================================
 // (PlantService) تحميل النباتات + البحث بالاسم
 //
 // يقرأ النباتات من مجموعة "plants" في Firestore.
 // ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garden_profile.dart';
import '../models/plant.dart';

class PlantService {
  PlantService._();
  static final PlantService instance = PlantService._();

  List<Plant>? _cache;

  /// يحمّل كل النباتات من Firestore (مرة واحدة ويخزنها بالكاش)
  Future<List<Plant>> loadPlants() async {
    if (_cache != null) return _cache!;

    final snapshot =
        await FirebaseFirestore.instance.collection('plants').get();

    _cache = snapshot.docs.map((doc) {
      final raw = doc.data();

      final mapped = {
        'id': raw['Plant_ID'] ?? doc.id,
        'arabicName': raw['Arabic_Name'],
        'scientificName': raw['Scientific_Name'],
        'wateringRequirement': raw['Watering_Requirement'],
        'lightRequirement': raw['Light_Requirement'],
        'careLevel': raw['Care_Level'],
        'matureHeight': raw['Mature_Height'],
        'matureSpread': raw['Mature_Spread'],
        'minTemperatureC': raw['Min_Temperature_C'],
        'maxTemperatureC': raw['Max_Temperature_C'],
        'climateToleranceClass': raw['Climate_Tolerance_Class'],
        'recordType': raw['Record_Type'],
      };

      return Plant.fromJson(mapped);
    }).toList();

    return _cache!;
  }

  /// ترشيح مبسط للنباتات في شاشة "حديقتي" (قائم على القواعد، مو الـ Recommendation Engine الكامل):
  /// - يفضّل النباتات اللي مستوى عنايتها يطابق تفضيل المستخدمة
  /// - يفضّل النباتات عالية التحمل للمناخ، ويؤخّر ضعيفة التحمل
  /// - يتجاهل النباتات اللي ما لها اسم عربي (عشان تظهر بالكرت)
  Future<List<Plant>> recommendForGarden(
    GardenProfile garden, {
    int limit = 10,
  }) async {
    final all = await loadPlants();
    final expectedCare = _careForPreference(garden.careLevel.arabicLabel);

    final scored = all.where((p) => p.arabicName.isNotEmpty).map((p) {
      int score = 0;
      if (p.careLevel == expectedCare) score += 2;
      if (p.climateToleranceClass == 'High') score += 2;
      if (p.climateToleranceClass == 'Moderate') score += 1;
      if (p.climateToleranceClass == 'Low') score -= 2;
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

  /// البحث بالاسم الكامل أو الجزئي (عربي أو علمي).
  /// فاضي → يرجع كل النباتات.
  List<Plant> search(List<Plant> plants, String query) {
    final q = _normalize(query);
    if (q.isEmpty) return plants;
    return plants.where((p) {
      return _normalize(p.arabicName).contains(q) ||
          _normalize(p.scientificName).contains(q);
    }).toList();
  }

  /// فلترة بالخصائص (الماء، تحمل المناخ، العناية). null = بدون فلتر.
  List<Plant> filter(
    List<Plant> plants, {
    String? water,
    String? tolerance,
    String? care,
  }) {
    return plants.where((p) {
      if (water != null && p.wateringRequirement != water) return false;
      if (tolerance != null && p.climateToleranceClass != tolerance) {
        return false;
      }
      if (care != null && p.careLevel != care) return false;
      return true;
    }).toList();
  }

  /// توحيد النص: حروف صغيرة، وإزالة التشكيل، وتوحيد الألف والتاء المربوطة والياء
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
