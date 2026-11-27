
import 'package:geolocator/geolocator.dart';
import 'geoapify_service.dart';

class LocationService {
  // Get the user's current location.
  static Future<Position> getCurrentLocation() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'خدمة الموقع غير مفعلة. يرجى تشغيل الموقع والمحاولة مرة أخرى.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'تم رفض إذن الوصول إلى الموقع.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.',
      );
    }

    final Position position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return position;
  }

  // Retrieve location details through Geoapify.
  static Future<Map<String, dynamic>> getLocationDetails(
    Position position,
  ) async {
    return GeoapifyService.getLocationDetails(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // Check whether the location is within the supported area.
  static bool isWithinSupportedArea(
    Map<String, dynamic> locationData,
  ) {
    final city = (locationData['city'] ?? '').toString();
    final state = (locationData['state'] ?? '').toString();
    final formatted =
        (locationData['formatted'] ?? '').toString();

    final locationText =
        '$city $state $formatted'.toLowerCase();

    return locationText.contains('riyadh') ||
        locationText.contains('الرياض');
  }
}
