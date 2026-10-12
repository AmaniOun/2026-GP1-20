
import 'dart:convert';

import 'package:http/http.dart' as http;

class PerenualService {
  PerenualService._();

  static final PerenualService instance = PerenualService._();

  static const String _apiKey = String.fromEnvironment(
    'PERENUAL_API_KEY',
  );

  static const String _baseUrl = 'https://perenual.com/api';

  final Map<String, Map<String, dynamic>?> _plantCache = {};
  final Map<int, List<Map<String, dynamic>>> _careCache = {};

  bool get isConfigured => _apiKey.isNotEmpty;

  // Search for a plant using its scientific name.
  Future<Map<String, dynamic>?> findPlant(
    String scientificName,
  ) async {
    final name = scientificName.trim();

    if (name.isEmpty || !isConfigured) {
      return null;
    }

    final cacheKey = name.toLowerCase();

    if (_plantCache.containsKey(cacheKey)) {
      return _plantCache[cacheKey];
    }

    final uri = Uri.parse('$_baseUrl/species-list').replace(
      queryParameters: {
        'key': _apiKey,
        'q': name,
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final results = decoded['data'];

      if (results is! List) {
        return null;
      }

      for (final item in results) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final names = item['scientific_name'];

        if (names is! List) {
          continue;
        }

        final matches = names.any(
          (value) =>
              value is String &&
              value.trim().toLowerCase() == cacheKey,
        );

        if (matches) {
          _plantCache[cacheKey] = item;
          return item;
        }
      }

      _plantCache[cacheKey] = null;
      return null;
    } catch (_) {
      return null;
    }
  }

  // Get a verified image URL for the plant.
  Future<String?> getPlantImage(
    String scientificName,
  ) async {
    final plant = await findPlant(scientificName);

    if (plant == null) {
      return null;
    }

    final image = plant['default_image'];

    if (image is! Map) {
      return null;
    }

    for (final field in [
      'regular_url',
      'medium_url',
      'small_url',
      'original_url',
    ]) {
      final value = image[field];

      if (value is String &&
          Uri.tryParse(value)?.hasScheme == true) {
        return value;
      }
    }

    return null;
  }

  // Fetch plant care guides using Perenual's species ID.
  Future<List<Map<String, dynamic>>> getCareGuides(
    int speciesId,
  ) async {
    if (!isConfigured) {
      return [];
    }

    if (_careCache.containsKey(speciesId)) {
      return _careCache[speciesId]!;
    }

    final uri = Uri.parse(
      '$_baseUrl/species-care-guide-list',
    ).replace(
      queryParameters: {
        'key': _apiKey,
        'species_id': speciesId.toString(),
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return [];
      }

      final data = decoded['data'];

      if (data is! List || data.isEmpty) {
        return [];
      }

      final first = data.first;

      if (first is! Map<String, dynamic>) {
        return [];
      }

      final sections = first['section'];

      if (sections is! List) {
        return [];
      }

      final guides = sections
          .whereType<Map<String, dynamic>>()
          .toList();

      _careCache[speciesId] = guides;

      return guides;
    } catch (_) {
      return [];
    }
  }

  // Fetch the plant's Perenual ID, image, and care guides.
  Future<Map<String, dynamic>?> getPlantDetails(
    String scientificName,
  ) async {
    final plant = await findPlant(scientificName);

    if (plant == null) {
      return null;
    }

    final id = plant['id'];

    if (id is! int) {
      return null;
    }

    final imageUrl = await getPlantImage(scientificName);
    final careGuides = await getCareGuides(id);

    return {
      'perenualId': id,
      'imageUrl': imageUrl,
      'careGuides': careGuides,
    };
  }
}
