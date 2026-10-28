class PlantDisplayFormatter {
  // احتياج الري
  static String water(String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
        return 'منخفض';
      case 'moderate':
      case 'medium':
        return 'متوسط';
      case 'high':
        return 'مرتفع';
      default:
        return value;
    }
  }

  // مستوى العناية
  static String care(String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
        return 'قليل';
      case 'moderate':
      case 'medium':
        return 'متوسط';
      case 'high':
        return 'عالٍ';
      default:
        return value;
    }
  }

  // تحمل المناخ
  static String tolerance(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'tolerant':
        return 'مقاوم';
      case 'sensitive':
        return 'حساس';
      default:
        return value ?? 'غير مصنّفة';
    }
  }

  // النص المعروض في بطاقة البحث للري
  static String waterTag(String value) {
    return 'ري ${water(value)}';
  }

  // النص المعروض في بطاقة البحث للعناية
  static String careTag(String value) {
    switch (value.trim().toLowerCase()) {
      case 'low':
        return 'عناية قليلة';
      case 'moderate':
      case 'medium':
        return 'عناية متوسطة';
      case 'high':
        return 'عناية عالية';
      default:
        return 'عناية $value';
    }
  }

  // النص المعروض في بطاقة البحث لتحمل المناخ
  static String toleranceTag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'غير مصنّفة';
    }
    return tolerance(value);
  }

  // احتياج الإضاءة
  static String light(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'full sun':
        return 'شمس كاملة';

      case 'partial sun':
      case 'part sun':
      case 'partial shade':
      case 'part shade':
        return 'ظل جزئي';

      case 'full shade':
        return 'ظل كامل';

      case 'medium':
      case 'moderate':
      case 'medium light':
        return 'متوسط';

      case 'low':
      case 'low light':
        return 'منخفض';

      case 'high':
      case 'high light':
        return 'مرتفع';

      default:
        return value;
    }
  }
}