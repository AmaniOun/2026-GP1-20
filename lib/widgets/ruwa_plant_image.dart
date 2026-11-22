import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/plant_image_service.dart';

/// Unified plant image UX across Ruwa:
/// loading -> small spinner; success -> disk-cached image; failure -> flower.
/// Shares the same cache key as Home's existing image preloading.
class RuwaPlantImage extends StatefulWidget {
  const RuwaPlantImage({
    super.key,
    required this.scientificName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String scientificName;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<RuwaPlantImage> createState() => _RuwaPlantImageState();
}

class _RuwaPlantImageState extends State<RuwaPlantImage> {
  Future<String?>? _imageUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant RuwaPlantImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scientificName.trim().toLowerCase() !=
        widget.scientificName.trim().toLowerCase()) {
      _resolve();
    }
  }

  void _resolve() {
    final name = widget.scientificName.trim();
    _imageUrl = name.isEmpty
        ? Future<String?>.value(null)
        : PlantImageService.instance.imageFor(name).timeout(
            const Duration(seconds: 35),
            onTimeout: () => null,
          );
  }

  static const _background = Color(0xFFE8F0E4);
  static const _foreground = Color(0xFF315B32);

  Widget _loading() => const ColoredBox(
        color: _background,
        child: Center(
          child: SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foreground,
            ),
          ),
        ),
      );

  Widget _unavailable() => const ColoredBox(
        color: _background,
        child: Center(
          child: Icon(
            Icons.local_florist_outlined,
            color: _foreground,
            size: 34,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loading();
        }
        final url = snapshot.data;
        if (snapshot.hasError || url == null || url.trim().isEmpty) {
          return _unavailable();
        }
        final normalized = widget.scientificName.trim().toLowerCase();
        return CachedNetworkImage(
          imageUrl: url,
          cacheKey: 'ruwa_plant_$normalized',
          fit: widget.fit,
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          memCacheWidth: 400,
          maxWidthDiskCache: 800,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 90),
          placeholder: (context, url) => _loading(),
          errorWidget: (context, url, error) => _unavailable(),
        );
      },
    );
  }
}
