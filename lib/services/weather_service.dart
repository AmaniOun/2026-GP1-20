import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/weather_condition.dart';

class WeatherService {
  static const String apiKey = '978973628536cf1ab443f9bc23760549';

  static Future<WeatherData> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.https(
      'api.openweathermap.org', '/data/3.0/onecall', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'appid': apiKey,
      'units': 'metric',
      'lang': 'ar',
      'exclude': 'minutely,hourly,daily',
    });

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        throw Exception('مفتاح OpenWeather غير صحيح أو اشتراك One Call لم يتفعّل بعد.');
      }
      if (response.statusCode != 200) {
        throw Exception('فشل طلب الطقس. Status Code: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>? ?? {};
      final weatherList = current['weather'] as List<dynamic>? ?? [];
      final weather = weatherList.isNotEmpty && weatherList.first is Map
          ? Map<String, dynamic>.from(weatherList.first as Map)
          : <String, dynamic>{};
      final id = (weather['id'] as num?)?.toInt();
      final description = weather['description']?.toString();
      final main = weather['main']?.toString();
      final dustPattern = RegExp(r'dust|sand|غبار|رمال|رملي', caseSensitive: false);
      final hasDust = {731, 751, 761}.contains(id) ||
          dustPattern.hasMatch('${main ?? ''} ${description ?? ''}');

      final rawAlerts = data['alerts'] as List<dynamic>? ?? [];
      final alerts = rawAlerts.whereType<Map>().map((raw) {
        final alert = Map<String, dynamic>.from(raw);
        return <String, dynamic>{
          'senderName': alert['sender_name'],
          'event': alert['event'],
          'start': alert['start'],
          'end': alert['end'],
          'description': alert['description'],
          'tags': alert['tags'] ?? <dynamic>[],
        };
      }).toList();

      final hasDustAlert = alerts.any((alert) {
        final tags = alert['tags'];
        final text = '${alert['event'] ?? ''} ${tags is List ? tags.join(' ') : ''}';
        return dustPattern.hasMatch(text);
      });

      return WeatherData(
        temperatureC: (current['temp'] as num?)?.toDouble(),
        windSpeedMs: (current['wind_speed'] as num?)?.toDouble(),
        hasDust: hasDust,
        hasDustAlert: hasDustAlert,
        feelsLike: (current['feels_like'] as num?)?.toDouble(),
        humidity: (current['humidity'] as num?)?.toInt(),
        description: description,
        icon: weather['icon']?.toString(),
        sunrise: (current['sunrise'] as num?)?.toInt(),
        sunset: (current['sunset'] as num?)?.toInt(),
        city: data['name']?.toString(),
        weatherId: id,
        alerts: alerts,
      );
    } on http.ClientException catch (e) {
      throw Exception('تعذر الاتصال بخدمة الطقس: $e');
    } on FormatException catch (e) {
      throw Exception('تعذر قراءة بيانات الطقس: $e');
    }
  }

  // For existing screens that expect Map<String, dynamic>.
  static Future<Map<String, dynamic>> getCurrentWeatherMap({
    required double latitude,
    required double longitude,
  }) async {
    final weather = await getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );
    return weather.toMap();
  }

  static List<WeatherCondition> detectConditions(WeatherData weather) =>
      weather.detectConditions();
}
