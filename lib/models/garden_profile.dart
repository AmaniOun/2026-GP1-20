// ==========================================
// نموذج بيانات الحديقة (Garden Profile)
//
// يمثل بيانات الحديقة الأساسية:
// - اتجاه الواجهة
// - أبعاد مساحة الزراعة
// - مستوى العناية
//
// بالإضافة إلى بيانات الموقع التي تم التحقق منها
// باستخدام Geoapify.
// ==========================================

enum FacadeDirection {
  north,
  south,
  east,
  west,
}

enum CareLevel {
  low,
  medium,
  high,
}

// ==========================================
// أسماء اتجاهات الواجهة بالعربي
// ==========================================
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

// ==========================================
// أسماء مستويات العناية بالعربي
// ==========================================
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

// ==========================================
// Garden Profile
// ==========================================
class GardenProfile {
  // بيانات الحديقة
  final FacadeDirection facadeDirection;
  final double lengthMeters;
  final double widthMeters;
  final CareLevel careLevel;

  // ========================================
  // بيانات الموقع
  // ========================================

  /// Latitude الذي تم الحصول عليه من الجهاز.
  final double? latitude;

  /// Longitude الذي تم الحصول عليه من الجهاز.
  final double? longitude;

  /// المدينة القادمة من Geoapify.
  final String? city;

  /// المنطقة / المحافظة القادمة من Geoapify.
  final String? state;

  /// الدولة القادمة من Geoapify.
  final String? country;

  /// العنوان المنسق القادم من Geoapify.
  final String? formattedAddress;

  /// هل تم التحقق من أن الموقع ضمن نطاق رُوى؟
  final bool locationVerified;

  final DateTime updatedAt;

  const GardenProfile({
    required this.facadeDirection,
    required this.lengthMeters,
    required this.widthMeters,
    required this.careLevel,
    required this.updatedAt,

    // جعلنا بيانات الموقع اختيارية مؤقتاً
    // حتى لا ينكسر الكود القديم.
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
    this.formattedAddress,
    this.locationVerified = false,
  });

  // ========================================
  // copyWith
  // ========================================
  GardenProfile copyWith({
    FacadeDirection? facadeDirection,
    double? lengthMeters,
    double? widthMeters,
    CareLevel? careLevel,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
    String? formattedAddress,
    bool? locationVerified,
    DateTime? updatedAt,
  }) {
    return GardenProfile(
      facadeDirection:
          facadeDirection ?? this.facadeDirection,
      lengthMeters:
          lengthMeters ?? this.lengthMeters,
      widthMeters:
          widthMeters ?? this.widthMeters,
      careLevel:
          careLevel ?? this.careLevel,

      latitude:
          latitude ?? this.latitude,
      longitude:
          longitude ?? this.longitude,
      city:
          city ?? this.city,
      state:
          state ?? this.state,
      country:
          country ?? this.country,
      formattedAddress:
          formattedAddress ?? this.formattedAddress,
      locationVerified:
          locationVerified ?? this.locationVerified,

      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ========================================
  // تحويل GardenProfile إلى Map
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'facadeDirection':
          facadeDirection.name,

      'lengthMeters':
          lengthMeters,

      'widthMeters':
          widthMeters,

      'careLevel':
          careLevel.name,

      // بيانات الموقع
      'latitude':
          latitude,

      'longitude':
          longitude,

      'city':
          city,

      'state':
          state,

      'country':
          country,

      'formattedAddress':
          formattedAddress,

      'locationVerified':
          locationVerified,

      'updatedAt':
          updatedAt.toIso8601String(),
    };
  }

  // ========================================
  // إنشاء GardenProfile من Map
  // ========================================
  factory GardenProfile.fromMap(
    Map<String, dynamic> map,
  ) {
    return GardenProfile(
      facadeDirection:
          FacadeDirection.values.firstWhere(
        (e) =>
            e.name ==
            map['facadeDirection'],
      ),

      lengthMeters:
          (map['lengthMeters'] as num)
              .toDouble(),

      widthMeters:
          (map['widthMeters'] as num)
              .toDouble(),

      careLevel:
          CareLevel.values.firstWhere(
        (e) =>
            e.name ==
            map['careLevel'],
      ),

      // بيانات الموقع
      latitude:
          map['latitude'] != null
              ? (map['latitude'] as num)
                  .toDouble()
              : null,

      longitude:
          map['longitude'] != null
              ? (map['longitude'] as num)
                  .toDouble()
              : null,

      city:
          map['city'] as String?,

      state:
          map['state'] as String?,

      country:
          map['country'] as String?,

      formattedAddress:
          map['formattedAddress']
              as String?,

      // لو عندنا Garden Profile قديم
      // ما فيه هذا الحقل، نعتبره false.
      locationVerified:
          map['locationVerified']
              as bool? ??
          false,

      updatedAt:
          DateTime.parse(
        map['updatedAt'] as String,
      ),
    );
  }
}