
class Plant {
  final String id;
  final String arabicName;
  final String scientificName;
  final String? family;
  final String? origin;
  final String wateringRequirement;
  final String lightRequirement;
  final String careLevel;
  final String? matureHeight;
  final String? matureSpread;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final String? climateToleranceClass;
  final String recordType;

  const Plant({
    required this.id,
    required this.arabicName,
    required this.scientificName,
    this.family,
    this.origin,
    required this.wateringRequirement,
    required this.lightRequirement,
    required this.careLevel,
    this.matureHeight,
    this.matureSpread,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.climateToleranceClass,
    this.recordType = 'Validated',
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      arabicName: (json['arabicName'] as String?) ?? '',
      scientificName: json['scientificName'] as String,
      family: json['family'] as String?,
      origin: json['origin'] as String?,
      wateringRequirement:
          json['wateringRequirement'] as String,
      lightRequirement:
          json['lightRequirement'] as String,
      careLevel: json['careLevel'] as String,
      matureHeight: json['matureHeight'] as String?,
      matureSpread: json['matureSpread'] as String?,
      minTemperatureC:
          (json['minTemperatureC'] as num?)?.toDouble(),
      maxTemperatureC:
          (json['maxTemperatureC'] as num?)?.toDouble(),
      climateToleranceClass:
          json['climateToleranceClass'] as String?,
      recordType:
          (json['recordType'] as String?) ?? 'Validated',
    );
  }

  String get displayName =>
      arabicName.isNotEmpty ? arabicName : scientificName;

  String get shortHint {
    if (climateToleranceClass == 'Sensitive') {
      return 'يحتاج عناية إضافية';
    }

    if (wateringRequirement == 'High') {
      return 'بحاجة إلى ري منتظم';
    }

    if (climateToleranceClass == 'Tolerant') {
      return 'مقاوم للحرارة';
    }

    return 'ينمو بشكل جيد';
  }
}
