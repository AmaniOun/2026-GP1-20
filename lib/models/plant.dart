// ============================================================
// (Plant) نموذج بيانات النبتة
// مصدر البيانات: Ruwa_KNN_Cleaned_Plant_Dataset_90
// ============================================================

class Plant {
  final String id;
  final String arabicName;
  final String scientificName;
  final String wateringRequirement; // Low / Medium / High
  final String lightRequirement; // Full Sun / Partial Sun / Shade
  final double matureHeight;
  final double matureSpread;
  final double minTempTolerance;
  final String climateToleranceClass; // Highly / Moderately / Poorly Tolerant

  Plant({
    required this.id,
    required this.arabicName,
    required this.scientificName,
    required this.wateringRequirement,
    required this.lightRequirement,
    required this.matureHeight,
    required this.matureSpread,
    required this.minTempTolerance,
    required this.climateToleranceClass,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      arabicName: json['arabicName'] as String,
      scientificName: json['scientificName'] as String,
      wateringRequirement: json['wateringRequirement'] as String,
      lightRequirement: json['lightRequirement'] as String,
      matureHeight: (json['matureHeight'] as num).toDouble(),
      matureSpread: (json['matureSpread'] as num).toDouble(),
      minTempTolerance: (json['minTempTolerance'] as num).toDouble(),
      climateToleranceClass: json['climateToleranceClass'] as String,
    );
  }

  /// وصف قصير يُعرض تحت اسم النبتة بالكرت (مثلاً "ينمو بشكل جيد" أو "بحاجة إلى ري")
  String get shortHint {
    if (climateToleranceClass == 'Poorly Tolerant') {
      return 'يحتاج عناية إضافية';
    }
    if (wateringRequirement == 'High') {
      return 'بحاجة إلى ري منتظم';
    }
    if (climateToleranceClass == 'Highly Tolerant') {
      return 'مقاوم للحرارة';
    }
    return 'ينمو بشكل جيد';
  }
}