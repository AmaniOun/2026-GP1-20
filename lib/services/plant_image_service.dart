import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'perenual_service.dart';

/// Resolves plant image URLs. The actual image bytes are cached by
/// CachedNetworkImage in the screens that display these URLs.
class PlantImageService {
  PlantImageService._();

  static final PlantImageService instance = PlantImageService._();

  final Map<String, Future<String?>> _imageFutures = {};
  final List<Completer<void>> _waiting = [];
  int _activeRequests = 0;

  static const int _maxConcurrentRequests = 2;
  static const Duration _urlCacheLifetime = Duration(days: 7);
  // Preserve the existing prefix to read old entries and invalidate them safely.
  static const String _urlCachePrefix = 'ruwa_plant_image_url_v1_';

  Future<String?> imageFor(String scientificName) {
    final name = scientificName.trim();
    if (name.isEmpty) return Future.value(null);

    final key = name.toLowerCase();
    final pending = _imageFutures[key];
    if (pending != null) return pending;

    final request = _loadImageWithDiskLookup(name, key);
    _imageFutures[key] = request;
    // Do not permanently cache failures: a later visit may have connectivity.
    request.then((url) {
      if (url == null && identical(_imageFutures[key], request)) {
        _imageFutures.remove(key);
      }
    }, onError: (Object error) {
      if (identical(_imageFutures[key], request)) {
        _imageFutures.remove(key);
      }
    });
    return request;
  }

  /// AWS-signed image links may expire within hours, not days.
  /// Never treat a link as usable if its signature has expired.
  bool _isUsableUrl(String? value) {
    if (value == null || value.trim().isEmpty ||
        value.contains('upgrade_access.jpg')) {
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return false;
    }

    final params = uri.queryParameters;
    final dateString = params['X-Amz-Date'];
    final expiresString = params['X-Amz-Expires'];
    if (dateString != null || expiresString != null) {
      // A partially signed link is not safe to persist or reuse.
      if (dateString == null || expiresString == null) return false;
      try {
        if (dateString.length != 16 || dateString[8] != 'T' ||
            dateString[15] != 'Z') {
          return false;
        }
        final signedAt = DateTime.utc(
          int.parse(dateString.substring(0, 4)),
          int.parse(dateString.substring(4, 6)),
          int.parse(dateString.substring(6, 8)),
          int.parse(dateString.substring(9, 11)),
          int.parse(dateString.substring(11, 13)),
          int.parse(dateString.substring(13, 15)),
        );
        final seconds = int.parse(expiresString);
        return signedAt.add(Duration(seconds: seconds)).isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 5)),
        );
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  bool _isSignedUrl(String url) {
    final params = Uri.tryParse(url)?.queryParameters;
    return params?.containsKey('X-Amz-Signature') == true ||
        params?.containsKey('X-Amz-Date') == true ||
        params?.containsKey('X-Amz-Expires') == true;
  }

  Future<String?> _loadImageWithDiskLookup(String name, String key) async {
    final preferenceKey = '$_urlCachePrefix${Uri.encodeComponent(key)}';
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(preferenceKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final url = decoded['url'];
          final savedAt = decoded['savedAt'];
          if (url is String && savedAt is int &&
              _isUsableUrl(url) && !_isSignedUrl(url) &&
              DateTime.now().millisecondsSinceEpoch >= savedAt &&
              DateTime.now().millisecondsSinceEpoch - savedAt <
                  _urlCacheLifetime.inMilliseconds) {
            return url;
          }
        }
        // Remove old expired or signed links from the previous implementation.
        await preferences.remove(preferenceKey);
      }
    } catch (error) {
      debugPrint('Plant image URL cache read failed: $error');
    }

    final found = await _loadImage(name);
    if (found != null && preferences != null && !_isSignedUrl(found)) {
      try {
        await preferences.setString(preferenceKey, jsonEncode({
          'url': found,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
        }));
      } catch (error) {
        debugPrint('Plant image URL cache write failed: $error');
      }
    }
    return found;
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
      String? perenualUrl;
      try {
        perenualUrl = await PerenualService.instance
            .getPlantImage(scientificName)
            .timeout(const Duration(seconds: 18));
      } catch (error) {
        debugPrint('Perenual image lookup failed: $error');
      }

      if (_isUsableUrl(perenualUrl)) return perenualUrl;

      // A signed Perenual URL may be expired even when it looks like HTTPS.
      debugPrint('Perenual image unavailable or expired for '
          '"$scientificName"; trying Wikimedia.');
      return await _findWikimediaImage(scientificName);
    } catch (error) {
      debugPrint('Plant image lookup error: $error');
      return null;
    } finally {
      _release();
    }
  }

  /// Retrieves a photo from Wikimedia Commons' file namespace.
  /// Candidates are not guaranteed botanical identifications.
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
      final response = await http.get(uri, headers: {
        'User-Agent':
            'RuwaPlantApp/1.0 (plant image lookup; Wikimedia Commons API)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

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
        final metadata = info['extmetadata'];
        if (metadata is! Map || metadata['LicenseShortName'] == null) {
          continue;
        }
        final thumbnail = info['thumburl'];
        final original = info['url'];
        final imageUrl = thumbnail is String
            ? thumbnail
            : (original is String ? original : null);
        if (_isUsableUrl(imageUrl)) {
          debugPrint('Wikimedia image candidate found for '
              '"$scientificName": $title');
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
