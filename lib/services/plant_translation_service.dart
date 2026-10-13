import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PlantTranslationService {
  PlantTranslationService._();

  static final PlantTranslationService instance =
      PlantTranslationService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  final Map<String, String> _memoryCache = {};

  Future<String> translateCareDescription(String englishText) async {
    final text = englishText.trim();

    if (text.isEmpty) return '';

    if (_memoryCache.containsKey(text)) {
      return _memoryCache[text]!;
    }

    try {
      final callable = _functions.httpsCallable('translatePlantCare');

      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
      });

      final translated =
          (result.data['translatedText'] ?? '').toString();

      if (translated.isNotEmpty) {
        _memoryCache[text] = translated;
        return translated;
      }

      return englishText;
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Translation function error: ${error.code}');
      return englishText;
    } catch (error) {
      debugPrint('Translation error: $error');
      return englishText;
    }
  }
}
