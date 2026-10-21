class Plant {
  final String id;
  final String arabicName; // فاضي لو الاسم العربي غير متوفر
  final String scientificName;
  final String wateringRequirement; // Low / Moderate / High
  final String lightRequirement; // Full Sun
  final String careLevel; // Low / Moderate / High
  final String? matureHeight;
  final String? matureSpread;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final String? climateToleranceClass; // Tolerant / Sensitive (قد يكون null)
  final String recordType; // Validated / Predicted

  const Plant({
    required this.id,
    required this.arabicName,
    required this.scientificName,
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
      wateringRequirement: json['wateringRequirement'] as String,
      lightRequirement: json['lightRequirement'] as String,
      careLevel: json['careLevel'] as String,
      matureHeight: json['matureHeight'] as String?,
      matureSpread: json['matureSpread'] as String?,
      minTemperatureC: (json['minTemperatureC'] as num?)?.toDouble(),
      maxTemperatureC: (json['maxTemperatureC'] as num?)?.toDouble(),
      climateToleranceClass: json['climateToleranceClass'] as String?,
      recordType: (json['recordType'] as String?) ?? 'Validated',
    );
  }

  String get displayName => arabicName.isNotEmpty ? arabicName : scientificName;

  String get shortHint {
    if (climateToleranceClass == 'Sensitive') return 'يحتاج عناية إضافية';
    if (wateringRequirement == 'High') return 'بحاجة إلى ري منتظم';
    if (climateToleranceClass == 'Tolerant') return 'مقاوم للحرارة';
    return 'ينمو بشكل جيد';
  }
}