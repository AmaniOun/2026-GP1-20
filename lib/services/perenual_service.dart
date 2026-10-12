
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

    debugPrint('Perenual: Searching for "$name"');
    debugPrint('Perenual: API key configured = $isConfigured');

    if (name.isEmpty) {
      debugPrint('Perenual: Scientific name is empty.');
      return null;
    }

    if (!isConfigured) {
      debugPrint(
        'Perenual: API key is missing. '
        'Run Flutter with --dart-define-from-file=perenual.local.json',
      );
      return null;
    }

    final cacheKey = name.toLowerCase();

    if (_plantCache.containsKey(cacheKey)) {
      debugPrint('Perenual: Using cached plant result.');
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

      debugPrint(
        'Perenual: Search HTTP status = ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Perenual: Search request failed. '
          'Response: ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint('Perenual: Unexpected search response format.');
        return null;
      }

      final results = decoded['data'];

      if (results is! List) {
        debugPrint(
          'Perenual: No data list found. '
          'Response: ${response.body}',
        );
        return null;
      }

      debugPrint(
        'Perenual: Search returned ${results.length} results.',
      );

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
          debugPrint(
            'Perenual: Exact match found. '
            'Species ID = ${item['id']}',
          );

          _plantCache[cacheKey] = item;
          return item;
        }
      }

      debugPrint(
        'Perenual: No exact scientific-name match found.',
      );

      _plantCache[cacheKey] = null;
      return null;
    } catch (error) {
      debugPrint('Perenual search error: $error');
      return null;
    }
  }

  // Get the image URL for a matched plant.
  Future<String?> getPlantImage(
    String scientificName,
  ) async {
    final plant = await findPlant(scientificName);

    if (plant == null) {
      debugPrint(
        'Perenual: Cannot get image because plant was not found.',
      );
      return null;
    }

    final image = plant['default_image'];

    if (image is! Map) {
      debugPrint(
        'Perenual: Plant has no default_image.',
      );
      return null;
    }

    for (final field in [
      'regular_url',
      'medium_url',
      'small_url',
      'original_url',
    ]) {
      final value = image[field];

      if (value is String) {
        final parsed = Uri.tryParse(value);

        if (parsed != null &&
            (parsed.scheme == 'https' ||
                parsed.scheme == 'http') &&
            parsed.host.isNotEmpty) {
          debugPrint(
            'Perenual: Image found using $field.',
          );
          return value;
        }
      }
    }

    debugPrint(
      'Perenual: No valid image URL found.',
    );

    return null;
  }

  // Fetch plant care guides using Perenual's species ID.
  Future<List<Map<String, dynamic>>> getCareGuides(
    int speciesId,
  ) async {
    if (!isConfigured) {
      debugPrint(
        'Perenual: Cannot load care guides. API key missing.',
      );
      return [];
    }

    if (_careCache.containsKey(speciesId)) {
      debugPrint(
        'Perenual: Using cached care guides for $speciesId.',
      );
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

      debugPrint(
        'Perenual: Care guides HTTP status = '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Perenual: Care guides request failed. '
          'Response: ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint(
          'Perenual: Unexpected care guides response format.',
        );
        return [];
      }

      final data = decoded['data'];

      if (data is! List || data.isEmpty) {
        debugPrint(
          'Perenual: No care guides available for $speciesId.',
        );
        return [];
      }

      final first = data.first;

      if (first is! Map<String, dynamic>) {
        debugPrint(
          'Perenual: Invalid care guide entry.',
        );
        return [];
      }

      final sections = first['section'];

      if (sections is! List) {
        debugPrint(
          'Perenual: Care guide sections are missing.',
        );
        return [];
      }

      final guides = sections
          .whereType<Map<String, dynamic>>()
          .toList();

      debugPrint(
        'Perenual: Found ${guides.length} care guide sections.',
      );

      _careCache[speciesId] = guides;

      return guides;
    } catch (error) {
      debugPrint('Perenual care guides error: $error');
      return [];
    }
  }

  // Fetch a plant's Perenual ID, image, and care guides.
  Future<Map<String, dynamic>?> getPlantDetails(
    String scientificName,
  ) async {
    debugPrint(
      'Perenual: Loading details for "$scientificName"',
    );

    final plant = await findPlant(scientificName);

    if (plant == null) {
      debugPrint(
        'Perenual: Plant details unavailable.',
      );
      return null;
    }

    final id = plant['id'];

    if (id is! int) {
      debugPrint(
        'Perenual: Plant ID is missing or invalid.',
      );
      return null;
    }

    final imageUrl = await getPlantImage(scientificName);
    final careGuides = await getCareGuides(id);

    debugPrint(
      'Perenual: Details loaded. '
      'Has image = ${imageUrl != null}, '
      'Care sections = ${careGuides.length}',
    );

    return {
      'perenualId': id,
      'imageUrl': imageUrl,
      'careGuides': careGuides,
    };
  }
}
