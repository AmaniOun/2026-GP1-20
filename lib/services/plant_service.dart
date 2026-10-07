// ============================================================
// (PlantService) تحميل بيانات النباتات + فلترة بسيطة قائمة على القواعد
// (ليست خوارزمية KNN حقيقية — هذا فقط لعرض نباتات "موصى بها" مبدئياً)
// ============================================================

import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/plant.dart';
import '../models/garden_profile.dart';

class PlantService {
  PlantService._();

  static final PlantService instance = PlantService._();

  List<Plant>? _cache;

  /// يحمّل كل النباتات من assets/plants.json
  /// مرة واحدة فقط ويخزنها بالكاش
  Future<List<Plant>> loadPlants() async {
    if (_cache != null) {
      return _cache!;
    }

    final raw = await rootBundle.loadString(
      'assets/plants.json',
    );

    final List<dynamic> list = jsonDecode(raw);

    _cache = list
        .map(
          (e) => Plant.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    return _cache!;
  }

  /// فلترة مبسطة قائمة على القواعد (وليست KNN حقيقية):
  ///
  /// - اتجاه الواجهة → مقدار الضوء المتوقع أن تتعرض له الحديقة
  /// - مستوى العناية المفضل → مقدار الري اللي المستخدمة ترتاح له
  /// - استبعاد/تأخير النباتات "ضعيفة التحمل"
  ///   إذا ما وجدنا بدائل كفاية
  Future<List<Plant>> recommendForGarden(
    GardenProfile garden, {
    int limit = 10,
  }) async {
    final all = await loadPlants();

    final expectedLight = _lightForFacade(
      garden.facadeDirection.arabicLabel,
    );

    final expectedWatering = _wateringForCareLevel(
      garden.careLevel.arabicLabel,
    );

    // ترتيب حسب درجة التوافق
    // الأعلى توافقاً أولاً
    final scored = all.map((p) {
      int score = 0;

      if (p.lightRequirement == expectedLight) {
        score += 2;
      }

      if (p.wateringRequirement == expectedWatering) {
        score += 2;
      }

      if (p.climateToleranceClass == 'Highly Tolerant') {
        score += 1;
      }

      if (p.climateToleranceClass == 'Poorly Tolerant') {
        score -= 2;
      }

      return MapEntry(p, score);
    }).toList();

    scored.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return scored
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  /// يحوّل اتجاه الواجهة (نص عربي)
  /// إلى مقدار الضوء المتوقع
  ///
  /// ملاحظة:
  /// هذا تقريب مبسّط لاتجاه الشمس في الرياض
  String _lightForFacade(
    String facadeArabicLabel,
  ) {
    switch (facadeArabicLabel) {
      case 'جنوب':
      case 'غرب':
        return 'Full Sun';

      case 'شرق':
        return 'Partial Sun';

      case 'شمال':
        return 'Shade';

      default:
        return 'Partial Sun';
    }
  }

  /// يحوّل مستوى العناية المفضل
  /// إلى مقدار الري المناسب
  String _wateringForCareLevel(
    String careLevelArabicLabel,
  ) {
    switch (careLevelArabicLabel) {
      case 'منخفض':
        return 'Low';

      case 'مرتفع':
      case 'عالي':
        return 'High';

      default:
        return 'Medium';
    }
  }
}