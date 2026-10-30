import '../models/weather_data.dart';
import 'weather_service.dart';

/// Shares weather readings between Home and My Garden for the saved location.
/// No new location permission is requested; only saved garden coordinates are used.
class GardenWeatherCache {
  GardenWeatherCache._();

  static const Duration freshness = Duration(minutes: 10);
  static final Map<String, _WeatherEntry> _readings = {};
  static final Map<String, Future<WeatherData>> _pending = {};

  static String _key(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';

  static WeatherData? lastReading(double latitude, double longitude) =>
      _readings[_key(latitude, longitude)]?.weather;

  static DateTime? lastUpdated(double latitude, double longitude) =>
      _readings[_key(latitude, longitude)]?.updatedAt;

  static Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
    bool forceRefresh = false,
  }) {
    final key = _key(latitude, longitude);
    final cached = _readings[key];
    if (!forceRefresh && cached != null &&
        DateTime.now().difference(cached.updatedAt) < freshness) {
      return Future.value(cached.weather);
    }
    // If both pages ask at once, they share one network request.
    final running = _pending[key];
    if (running != null) return running;
    final request = WeatherService.getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    ).then((weather) {
      _readings[key] = _WeatherEntry(weather, DateTime.now());
      return weather;
    });
    _pending[key] = request;
    request.then<void>((_) { _pending.remove(key); },
        onError: (Object _, StackTrace __) { _pending.remove(key); });
    return request;
  }
}

class _WeatherEntry {
  final WeatherData weather;
  final DateTime updatedAt;
  const _WeatherEntry(this.weather, this.updatedAt);
}
