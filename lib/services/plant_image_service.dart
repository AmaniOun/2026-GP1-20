import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'perenual_service.dart';

/// Loads plant images from Perenual first, then Wikimedia Commons.
/// Reuses requests and limits concurrent image lookups.
class PlantImageService {
  PlantImageService._();

  static final PlantImageService instance = PlantImageService._();

  final Map<String, Future<String?>> _imageFutures = {};
  final List<Completer<void>> _waiting = [];

  int _activeRequests = 0;
  static const int _maxConcurrentRequests = 2;

  Future<String?> imageFor(String scientificName) {
    final name = scientificName.trim();
    if (name.isEmpty) return Future.value(null);

    final key = name.toLowerCase();
    return _imageFutures.putIfAbsent(key, () => _loadImage(name));
  }

  Future<void> _acquire() async {
    if (_activeRequests < _maxConcurrentRequests) {
      _activeRequests++;
      return;
    }

    final waiter = Completer<void>();
    _waiting.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else {
      _activeRequests--;
    }
  }

  Future<String?> _loadImage(String scientificName) async {
    await _acquire();

    try {
      final perenualUrl = await PerenualService.instance.getPlantImage(
        scientificName,
      );

      if (_isUsableUrl(perenualUrl)) {
        return perenualUrl;
      }

      debugPrint('Perenual image unavailable for "$scientificName"; trying Wikimedia.');
      return await _findWikimediaImage(scientificName);
    } catch (error) {
      debugPrint('Plant image lookup error: $error');
      return null;
    } finally {
      _release();
    }
  }

  bool _isUsableUrl(String? value) {
    if (value == null || value.trim().isEmpty ||
        value.contains('upgrade_access.jpg')) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  /// Uses Commons' File namespace and thumbnail URLs, not arbitrary web images.
  /// Search results are candidates, not guaranteed botanical identifications.
  Future<String?> _findWikimediaImage(String scientificName) async {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': 'intitle:"$scientificName"',
      'gsrnamespace': '6',
      'gsrlimit': '15',
      'prop': 'imageinfo',
      'iiprop': 'url|mime|extmetadata',
      'iiurlwidth': '800',
      'format': 'json',
      'formatversion': '2',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'RuwaPlantApp/1.0 (plant image lookup; Wikimedia Commons API)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('Wikimedia search failed: HTTP ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final query = decoded['query'];
      if (query is! Map<String, dynamic>) return null;
      final pages = query['pages'];
      if (pages is! List) return null;

      final normalizedName = scientificName.toLowerCase().trim();
      for (final page in pages) {
        if (page is! Map<String, dynamic>) continue;
        final title = page['title'];
        if (title is! String ||
            !title.toLowerCase().contains(normalizedName)) {
          continue;
        }

        final imageInfo = page['imageinfo'];
        if (imageInfo is! List || imageInfo.isEmpty) continue;
        final info = imageInfo.first;
        if (info is! Map<String, dynamic>) continue;

        final mime = info['mime'];
        if (mime != 'image/jpeg' && mime != 'image/png' &&
            mime != 'image/webp') {
          continue;
        }

        // Skip files with no license information; Commons files may require
        // attribution and license display when used in the app.
        final metadata = info['extmetadata'];
        if (metadata is! Map || metadata['LicenseShortName'] == null) {
          continue;
        }

        final thumbnail = info['thumburl'];
        final original = info['url'];
        final imageUrl = thumbnail is String ? thumbnail :
            (original is String ? original : null);
        if (_isUsableUrl(imageUrl)) {
          debugPrint('Wikimedia image candidate found for "$scientificName": $title');
          return imageUrl;
        }
      }

      debugPrint('No suitable Wikimedia image found for "$scientificName".');
      return null;
    } catch (error) {
      debugPrint('Wikimedia image lookup error: $error');
      return null;
    }
  }
}
