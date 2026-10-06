// ==========================================
// نموذج بيانات الحديقة (Garden Profile)
// يمثل الحقول المطلوبة بالـ Product Backlog:
// PBI 4: Facade Direction
// PBI 5: Planting Area Dimensions (length & width)
// PBI 6: Preferred Level of Plant Care
// ==========================================

enum FacadeDirection { north, south, east, west }

enum CareLevel { low, medium, high }

extension FacadeDirectionLabel on FacadeDirection {
  String get arabicLabel {
    switch (this) {
      case FacadeDirection.north:
        return 'شمالية';
      case FacadeDirection.south:
        return 'جنوبية';
      case FacadeDirection.east:
        return 'شرقية';
      case FacadeDirection.west:
        return 'غربية';
    }
  }
}

extension CareLevelLabel on CareLevel {
  String get arabicLabel {
    switch (this) {
      case CareLevel.low:
        return 'قليلة';
      case CareLevel.medium:
        return 'متوسطة';
      case CareLevel.high:
        return 'عالية';
    }
  }
}

class GardenProfile {
  final FacadeDirection facadeDirection;
  final double lengthMeters;
  final double widthMeters;
  final CareLevel careLevel;
  final DateTime updatedAt;

  const GardenProfile({
    required this.facadeDirection,
    required this.lengthMeters,
    required this.widthMeters,
    required this.careLevel,
    required this.updatedAt,
  });

  GardenProfile copyWith({
    FacadeDirection? facadeDirection,
    double? lengthMeters,
    double? widthMeters,
    CareLevel? careLevel,
    DateTime? updatedAt,
  }) {
    return GardenProfile(
      facadeDirection: facadeDirection ?? this.facadeDirection,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      widthMeters: widthMeters ?? this.widthMeters,
      careLevel: careLevel ?? this.careLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'facadeDirection': facadeDirection.name,
      'lengthMeters': lengthMeters,
      'widthMeters': widthMeters,
      'careLevel': careLevel.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GardenProfile.fromMap(Map<String, dynamic> map) {
    return GardenProfile(
      facadeDirection: FacadeDirection.values.firstWhere(
        (e) => e.name == map['facadeDirection'],
      ),
      lengthMeters: (map['lengthMeters'] as num).toDouble(),
      widthMeters: (map['widthMeters'] as num).toDouble(),
      careLevel: CareLevel.values.firstWhere(
        (e) => e.name == map['careLevel'],
      ),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}