import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // حطي مفتاح OpenWeather الخاص بك هنا
  static const String apiKey = '978973628536cf1ab443f9bc23760549';

  static Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final Uri url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$latitude'
      '&lon=$longitude'
      '&appid=$apiKey'
      '&units=metric'
      '&lang=ar',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final main = data['main'] as Map<String, dynamic>?;
        final wind = data['wind'] as Map<String, dynamic>?;
        final sys = data['sys'] as Map<String, dynamic>?;

        final weatherList = data['weather'] as List<dynamic>?;

        return {
          'temperature':
              (main?['temp'] as num?)?.toDouble(),

          'feelsLike':
              (main?['feels_like'] as num?)?.toDouble(),

          'humidity':
              (main?['humidity'] as num?)?.toInt(),

          'windSpeed':
              (wind?['speed'] as num?)?.toDouble(),

          'description':
              weatherList != null && weatherList.isNotEmpty
                  ? weatherList[0]['description']
                  : null,

          'icon':
              weatherList != null && weatherList.isNotEmpty
                  ? weatherList[0]['icon']
                  : null,

          'sunrise':
              (sys?['sunrise'] as num?)?.toInt(),

          'sunset':
              (sys?['sunset'] as num?)?.toInt(),

          'city':
              data['name'],
        };
      }

      if (response.statusCode == 401) {
        throw Exception(
          'مفتاح OpenWeather غير صحيح أو لم يتم تفعيله بعد.',
        );
      }

      throw Exception(
        'فشل طلب الطقس. Status Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'حدث خطأ أثناء الاتصال بخدمة الطقس: $e',
      );
    }
  }
}