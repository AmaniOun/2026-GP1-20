import 'package:geolocator/geolocator.dart';

class LocationService {
  // ============================================================
  // الحصول على موقع المستخدم الحالي
  // ============================================================
  static Future<Position> getCurrentLocation() async {
    // ----------------------------------------------------------
    // 1. التأكد أن خدمة الموقع GPS مفعلة في الجهاز
    // ----------------------------------------------------------
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'خدمة الموقع غير مفعلة. يرجى تشغيل الموقع والمحاولة مرة أخرى.',
      );
    }

    // ----------------------------------------------------------
    // 2. التحقق من صلاحية الموقع الحالية
    // ----------------------------------------------------------
    LocationPermission permission =
        await Geolocator.checkPermission();

    // ----------------------------------------------------------
    // 3. إذا لم يتم إعطاء الصلاحية، نطلبها من المستخدم
    // ----------------------------------------------------------
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      // المستخدم رفض الصلاحية
      if (permission == LocationPermission.denied) {
        throw Exception(
          'تم رفض إذن الوصول إلى الموقع.',
        );
      }
    }

    // ----------------------------------------------------------
    // 4. إذا المستخدم رفض الصلاحية بشكل دائم
    // ----------------------------------------------------------
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.',
      );
    }

    // ----------------------------------------------------------
    // 5. الصلاحية موجودة، نحصل على الموقع الحالي
    // ----------------------------------------------------------
    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return position;
  }
}