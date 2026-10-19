import 'weather_condition.dart';

class WeatherData {
  final double? temperatureC;
  final double? windSpeedMs;
  final bool hasDust;
  final bool hasDustAlert;
  final double? feelsLike;
  final int? humidity;
  final String? description;
  final String? icon;
  final int? sunrise;
  final int? sunset;
  final String? city;
  final int? weatherId;
  final List<Map<String, dynamic>> alerts;

  const WeatherData({
    required this.temperatureC,
    required this.windSpeedMs,
    required this.hasDust,
    required this.hasDustAlert,
    this.feelsLike,
    this.humidity,
    this.description,
    this.icon,
    this.sunrise,
    this.sunset,
    this.city,
    this.weatherId,
    this.alerts = const [],
  });

  // Official alerts are used for classification; no invented numerical thresholds.
  List<WeatherCondition> detectConditions() {
    final conditions = <WeatherCondition>[];
    if (hasDust || hasDustAlert) {
      conditions.add(WeatherCondition.DustStorm);
    }
    for (final alert in alerts) {
      final tags = alert['tags'];
      final combined = [
        alert['event'],
        if (tags is List) ...tags,
      ].where((part) => part != null).join(' ').toLowerCase();
      if (_matches(combined, r'heat|high temperature|extreme temperature|حرارة مرتفعة|موجة حر|حر شديد')) {
        conditions.add(WeatherCondition.HighTemperature);
      }
      if (_matches(combined, r'cold|frost|freeze|low temperature|برد شديد|صقيع|انخفاض درجات الحرارة')) {
        conditions.add(WeatherCondition.LowTemperature);
      }
      if (_matches(combined, r'strong wind|high wind|wind warning|gale|رياح شديدة|رياح قوية|رياح نشطة|عاصفة رياح')) {
        conditions.add(WeatherCondition.StrongWinds);
      }
    }
    return conditions.toSet().toList();
  }

  static bool _matches(String text, String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(text);

  // Compatibility for existing UI that reads a Map.
  Map<String, dynamic> toMap() => {
        'temperature': temperatureC,
        'temperatureC': temperatureC,
        'windSpeed': windSpeedMs,
        'windSpeedMs': windSpeedMs,
        'hasDust': hasDust,
        'hasDustAlert': hasDustAlert,
        'hasOfficialAlerts': alerts.isNotEmpty,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'description': description,
        'icon': icon,
        'sunrise': sunrise,
        'sunset': sunset,
        'city': city,
        'weatherId': weatherId,
        'alerts': alerts,
        'conditions': detectConditions().map((e) => e.name).toList(),
      };
}
