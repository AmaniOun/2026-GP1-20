import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoapifyService {
  // مفتاح Geoapify المشترك للمشروع
  static const String apiKey = '09dbe3256c4b4b2eab95c0883cdf667f';

  // ============================================================
  // تحويل Latitude + Longitude إلى بيانات موقع
  // ============================================================
  static Future<Map<String, dynamic>> getLocationDetails({
    required double latitude,
    required double longitude,
  }) async {
    final Uri url = Uri.parse(
      'https://api.geoapify.com/v1/geocode/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final List<dynamic> features =
            data['features'] ?? [];

        if (features.isEmpty) {
          throw Exception(
            'لم يتم العثور على بيانات لهذا الموقع.',
          );
        }

        final Map<String, dynamic> properties =
            features[0]['properties'];

        return {
          'formatted': properties['formatted'],
          'city': properties['city'],
          'state': properties['state'],
          'country': properties['country'],
          'postcode': properties['postcode'],
        };
      }

      throw Exception(
        'فشل طلب Geoapify. Status Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'حدث خطأ أثناء الاتصال بـ Geoapify: $e',
      );
    }
  }
}