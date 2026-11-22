import '../widgets/ruwa_saved_badge.dart';
import '../widgets/ruwa_plant_image.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_profile.dart';
import '../models/plant.dart';
import '../models/weather_data.dart';
import '../services/garden_service.dart';
import '../services/my_plant_service.dart';
import '../services/plant_image_service.dart';
import '../services/recommendation_engine.dart';
import '../services/garden_weather_cache.dart';
import 'my_plants_screen.dart';
import 'plant_details_screen.dart';
import 'recommended_plants_screen.dart';

/// Home is an overview and a navigation hub; My Garden keeps the full details.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.name,
    required this.onSelectTab,
    required this.active,
  });

  final String name;
  final ValueChanged<int> onSelectTab;
  final bool active;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _green = Color(0xFF315B32);
  static const _dark = Color(0xFF234525);
  static const _light = Color(0xFFE8F0E4);
  static const _bg = Color(0xFFFAF9F4);
  static const _border = Color(0xFFDCE4D8);
  static const _muted = Color(0xFF4E604D);

  GardenProfile? _garden;
  WeatherData? _weather;
  bool _weatherLoading = false;
  bool _weatherStale = false;
  int _weatherRequestVersion = 0;
  int _reloadVersion = 0;
  List<Plant> _saved = const [];
  List<PlantRecommendation> _recommended = const [];
  RecommendationResults? _recommendationResults;
  final Set<String> _prefetchStarted = {};
  bool _loading = true;
  bool _hasLoadedOnce = false;
  bool _gardenLoaded = false;
  String? _error;
  String? _savedError;
  String? _recommendationsError;
  int _tipIndex = 0;
  late final PageController _tipsController;
  Timer? _tipsTimer;
  bool _isTouchingTips = false;

  static const _tips = <({String title, String body, IconData icon})>[
    (title: 'الإضاءة المناسبة', body: 'تختلف احتياجات النباتات للضوء؛ فبعضها يفضّل الشمس المباشرة، وبعضها ينمو أفضل في الظل الجزئي.', icon: Icons.wb_sunny_outlined),
    (title: 'توقيت الري', body: 'يُفضّل ري النباتات في الصباح الباكر لتقليل فقدان الماء بالتبخر، خاصةً في الأجواء الحارة.', icon: Icons.water_drop_outlined),
    (title: 'مساحة النمو', body: 'اترك مساحة كافية لنمو النباتات؛ فبعضها يتمدد ويحتاج مساحة أكبر مع مرور الوقت.', icon: Icons.straighten_rounded),
    (title: 'تحمّل المناخ', body: 'قد تتحمّل بعض النباتات حرارة الصيف، بينما تحتاج نباتات أخرى إلى حماية إضافية من أشعة الشمس الشديدة.', icon: Icons.thermostat_outlined),
    (title: 'مستوى العناية', body: 'بعض النباتات تحتاج متابعة مستمرة، بينما تكتفي أنواع أخرى بعناية أقل بعد استقرار نموها.', icon: Icons.eco_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tipsController = PageController();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleNextTip();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _reload();
      _scheduleNextTip();
    } else if (!widget.active && oldWidget.active) {
      _tipsTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _tipsTimer?.cancel();
    _tipsController.dispose();
    super.dispose();
  }

  // Auto-advance every six seconds while Home is visible. A manual swipe
  // pauses the timer, and the next interval starts after the interaction.
  void _scheduleNextTip() {
    _tipsTimer?.cancel();
    if (!mounted || !widget.active || _isTouchingTips) return;
    _tipsTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || !widget.active || _isTouchingTips ||
          !_tipsController.hasClients) return;
      final next = (_tipIndex + 1) % _tips.length;
      _tipsController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      // onPageChanged schedules the next interval.
    });
  }

  Future<void> _reload() async {
    final request = ++_reloadVersion;
    if (!mounted) return;
    setState(() { _loading = !_hasLoadedOnce; _error = null; });

    // Keep existing garden and weather visible while other tabs are visited.
    GardenProfile? garden = _garden;
    List<Plant> saved = _saved;
    List<PlantRecommendation> recommended = _recommended;
    RecommendationResults? recommendationResults = _recommendationResults;
    String? error;
    String? savedError;
    String? recommendationsError;
    bool gardenLoaded = false;
    try {
      garden = await GardenService.instance.getGarden();
      gardenLoaded = true;
    } catch (e) {
      debugPrint('HOME GARDEN ERROR: $e');
      error = 'تعذر تحديث بيانات الحديقة.';
      // A temporary Firestore error must NOT look like a deleted garden.
    }
    try {
      saved = await MyPlantService.instance.getMyPlants();
    } catch (e) {
      debugPrint('HOME SAVED PLANTS ERROR: $e');
      savedError = 'تعذّر تحميل النباتات المحفوظة. تحقّق من الاتصال وصلاحيات الوصول.';
    }
    if (garden != null) {
      try {
        final results = await RecommendationEngine.instance.getRecommendations();
        recommendationResults = results;
        recommended = [...results.tolerantPlants, ...results.sensitivePlants]
          ..sort((a, b) => b.score.compareTo(a.score));
      } catch (e) {
        debugPrint('HOME RECOMMENDATIONS ERROR: $e');
        recommendationsError = 'تعذّر تحميل التوصيات حاليًا.';
      }
    } else if (gardenLoaded) {
      recommended = const [];
      recommendationResults = null;
    }
    if (!mounted || request != _reloadVersion) return;

    final sameLocation = _garden?.latitude == garden?.latitude &&
        _garden?.longitude == garden?.longitude;
    final lat = garden?.latitude;
    final lon = garden?.longitude;
    final cached = lat != null && lon != null
        ? GardenWeatherCache.lastReading(lat, lon)
        : null;

    setState(() {
      _garden = garden;
      if (gardenLoaded) _gardenLoaded = true;
      _saved = saved;
      _recommended = recommended;
      _recommendationResults = recommendationResults;
      // Only replace the reading when the actual saved location changes.
      if (!sameLocation) {
        _weatherRequestVersion++;
        _weather = cached;
        _weatherStale = false;
      } else if (_weather == null && cached != null) {
        _weather = cached;
      }
      _error = error;
      _savedError = savedError;
      _recommendationsError = recommendationsError;
      _loading = false;
      _hasLoadedOnce = true;
    });

    // Prime the same persistent image cache used by recommendation cards.
    // Never await this work in the page's data-loading lifecycle.
    if (recommended.isNotEmpty) {
      final topPlants = recommended.take(6).map((r) => r.plant).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_prefetchRecommendationPhotos(topPlants));
        }
      });
    }

    if (lat != null && lon != null) {
      // Exactly the same source as My Garden: saved garden coordinates and
      // WeatherService.getCurrentWeather (via a small home cache).
      _loadWeather(garden!);
    } else if (gardenLoaded) {
      // No saved location: do not show weather for an unrelated garden.
      _weatherRequestVersion++;
      setState(() {
        _weather = null;
        _weatherLoading = false;
        _weatherStale = false;
      });
    }
  }

  // Background preloading: highest-ranked photos first, at most two workers.
  // This does not block recommendations, navigation, or scrolling.
  Future<void> _prefetchRecommendationPhotos(List<Plant> plants) async {
    final pending = <String>[];
    for (final plant in plants) {
      final name = plant.scientificName.trim();
      final key = name.toLowerCase();
      if (name.isNotEmpty && _prefetchStarted.add(key)) pending.add(name);
    }
    if (pending.isEmpty) return;
    var next = 0;
    Future<void> worker() async {
      while (next < pending.length && mounted) {
        final name = pending[next++];
        final key = name.toLowerCase();
        try {
          final url = await PlantImageService.instance.imageFor(name)
              .timeout(const Duration(seconds: 35), onTimeout: () => null);
          if (!mounted || url == null || url.isEmpty) {
            _prefetchStarted.remove(key);
            continue;
          }
          await precacheImage(
            CachedNetworkImageProvider(
              url,
              cacheKey: 'ruwa_plant_$key',
            ),
            context,
            onError: (error, stackTrace) {
              debugPrint('Home image prefetch failed for $name: $error');
              _prefetchStarted.remove(key);
            },
          ).timeout(const Duration(seconds: 20));
        } catch (error) {
          _prefetchStarted.remove(key);
          debugPrint('Image prefetch skipped for $name: $error');
        }
      }
    }
    await Future.wait([worker(), worker()]);
  }

  Future<void> _loadWeather(GardenProfile garden, {bool forceRefresh = false}) async {
    final lat = garden.latitude;
    final lon = garden.longitude;
    if (lat == null || lon == null) return;
    final version = ++_weatherRequestVersion;
    final cached = GardenWeatherCache.lastReading(lat, lon);
    if (!mounted) return;
    setState(() {
      if (cached != null) _weather = cached;
      _weatherLoading = cached == null;
      _weatherStale = cached != null &&
          DateTime.now().difference(GardenWeatherCache.lastUpdated(lat, lon)!) >=
              GardenWeatherCache.freshness;
    });
    try {
      final weather = await GardenWeatherCache.getWeather(
        latitude: lat, longitude: lon, forceRefresh: forceRefresh,
      );
      if (!mounted || version != _weatherRequestVersion ||
          _garden?.latitude != lat || _garden?.longitude != lon) return;
      setState(() { _weather = weather; _weatherStale = false; _weatherLoading = false; });
    } catch (e) {
      debugPrint('HOME WEATHER ERROR: $e');
      if (!mounted || version != _weatherRequestVersion) return;
      // Leave the last successful reading on screen; never pretend stale data
      // is current. An empty state is shown only if no reading exists at all.
      setState(() { _weatherStale = _weather != null; _weatherLoading = false; });
    }
  }

  // My Plants requires a configured garden. Route users to My Garden setup first.
  void _openMyPlants() {
    if (!_gardenLoaded || _loading) return;
    if (_garden == null) {
      widget.onSelectTab(2);
      return;
    }
    _openPage(const MyPlantsScreen());
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page))
        .then((_) { if (mounted) _reload(); });
  }

  TextStyle _style(double size, {Color color = _dark, FontWeight weight = FontWeight.w500, double height = 1.45}) =>
      GoogleFonts.cairo(fontSize: size, color: color, fontWeight: weight, height: height);

  Widget _label(String value, {double size = 14, Color color = _dark, FontWeight weight = FontWeight.w500,
      TextAlign align = TextAlign.right, int? maxLines}) =>
      Text(value, textDirection: TextDirection.rtl, textAlign: align, maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: _style(size, color: color, weight: weight));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _green,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 32),
              children: [
                _header(),
                const SizedBox(height: 22),
                if (!_gardenLoaded && !_hasLoadedOnce)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Center(child: CircularProgressIndicator(color: _green)),
                  )
                else if (_garden == null && !_gardenLoaded) ...[
                  _notice('تعذّر تحميل بيانات الحديقة. اسحبي الصفحة للأسفل لإعادة المحاولة.'),
                ] else if (_garden == null) ...[
                  _setupHero(),
                  const SizedBox(height: 20),
                  _exploreSection(),
                ] else ...[
                  _weatherCard(),
                  const SizedBox(height: 18),
                  _recommendationHero(),
                  const SizedBox(height: 23),
                  _recommendedSection(),
                  const SizedBox(height: 20),
                  _savedSection(),
                ],
                const SizedBox(height: 21),
                _tipsCard(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _notice(_error!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty || parts.first.isEmpty ? '' : parts.first;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        _roundIcon(Icons.person_outline_rounded, 'حسابي', () => widget.onSelectTab(4)),
        const SizedBox(width: 9),
        const Spacer(),
        _roundIcon(Icons.notifications_none_rounded, 'الإشعارات', () => widget.onSelectTab(3)),
      ]),
      const SizedBox(height: 13),
      _label(first.isEmpty ? 'أهلًا بك!' : 'أهلًا، $first!', size: 23, weight: FontWeight.w800),
      const SizedBox(height: 2),
      _label(_gardenLoaded && _garden == null
          ? 'لنبدأ رحلتك في عالم النباتات'
          : 'حديقة أجمل تبدأ باختيار مناسب',
        size: 15, color: _muted),
    ]);
  }

  Widget _roundIcon(IconData icon, String tooltip, VoidCallback action) =>
      Material(color: _light, shape: const CircleBorder(), child: IconButton(
        tooltip: tooltip, onPressed: action, icon: Icon(icon, color: _green, size: 23),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ));

  // Built entirely from Flutter widgets; there are no external asset dependencies.
  Widget _setupHero() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2E5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(children: [
        const SizedBox(height: 4),
        SizedBox(height: 140, width: double.infinity, child: CustomPaint(
          painter: _GardenSetupPainter(),
        )),
        const SizedBox(height: 13),
        _label('ابدأ بإعداد حديقتك', size: 21, weight: FontWeight.w800, align: TextAlign.center),
        const SizedBox(height: 8),
        _label('أضف موقع حديقتك ومساحة الزراعة وتفضيلات العناية لنقترح النباتات الأنسب لك.',
          size: 15, color: _muted, align: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 49, child: ElevatedButton.icon(
          onPressed: () => widget.onSelectTab(2),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: Text('إعداد حديقتي', style: _style(15, color: Colors.white, weight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
      ]),
    );
  }

  Widget _exploreSection() => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: () => widget.onSelectTab(1),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
        child: Row(children: [
          Container(width: 55, height: 64,
            decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.search_rounded, color: _green, size: 30)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('استكشف النباتات', size: 17, weight: FontWeight.w800),
            const SizedBox(height: 4),
            _label('ابحث عن النباتات وتعرّف على احتياجاتها وخصائصها.', size: 14, color: _muted),
          ])),
          const Icon(Icons.chevron_left_rounded, color: _green),
        ]),
      ),
    ),
  );

  Widget _weatherCard() {
    final weather = _weather;
    final hasCoords = _garden?.latitude != null && _garden?.longitude != null;
    final isWaiting = _loading || _weatherLoading || !_gardenLoaded;
    final rawCity = _garden?.city?.trim().isNotEmpty == true
        ? _garden!.city!.trim() : (weather?.city ?? '');
    final city = rawCity.toLowerCase() == 'riyadh' || rawCity.toLowerCase() == 'ar riyadh'
        ? 'الرياض' : rawCity;
    final temp = weather?.temperatureC;
    final status = weather?.description?.trim();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE7EFD9), Color(0xFFF2F4E6)],
          begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
        borderRadius: BorderRadius.circular(22), border: Border.all(color: _border),
      ),
      child: Stack(children: [
        const PositionedDirectional(bottom: -19, start: -20,
          child: Icon(Icons.spa_rounded, size: 100, color: Color(0x1F6B9158))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(children: [
            Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('طقس حديقتك', size: 17, weight: FontWeight.w800),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_outlined, color: _green, size: 17),
                const SizedBox(width: 3),
                Expanded(child: _label(city.isEmpty ? 'موقع الحديقة' : city,
                  size: 14, color: _muted, maxLines: 1)),
              ]),
              if (_weatherStale) _label('آخر قراءة محفوظة', size: 12, color: _muted),
            ])),
            Container(width: 1, height: 52, color: const Color(0xFFCEDCC5)),
            const SizedBox(width: 10),
            Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (isWaiting && weather == null)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
                    strokeWidth: 2, color: _green))
                else
                  Icon(_weatherIcon(status), color: const Color(0xFFDEAC35), size: 28),
                const SizedBox(width: 7),
                Flexible(child: Text(temp == null ? '—' : '${temp.round()}°',
                  textDirection: TextDirection.ltr, style: _style(27, weight: FontWeight.w800))),
              ]),
              _label(!hasCoords ? 'الموقع غير متاح' : weather == null
                  ? (isWaiting ? 'جارٍ جلب الطقس' : 'تعذّر تحديث الطقس')
                  : (status?.isNotEmpty == true ? status! : 'الطقس الحالي'),
                size: 13, color: _muted, maxLines: 2),
            ])),
          ]),
        ),
      ]),
    );
  }

  IconData _weatherIcon(String? description) {
    final text = (description ?? '').toLowerCase();
    if (text.contains('rain') || text.contains('مطر')) return Icons.grain_rounded;
    if (text.contains('cloud') || text.contains('غائم') || text.contains('سحب')) return Icons.cloud_outlined;
    if (text.contains('dust') || text.contains('غبار')) return Icons.air_rounded;
    return Icons.wb_sunny_rounded;
  }

  Widget _recommendationHero() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFE9F0E0), borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
    ),
    padding: const EdgeInsets.all(17),
    child: Row(children: [
      Expanded(flex: 4, child: SizedBox(height: 142,
        child: CustomPaint(painter: _PlantPotPainter()))),
      const SizedBox(width: 13),
      Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('اكتشف نباتات تناسب حديقتك', size: 18, weight: FontWeight.w800),
        const SizedBox(height: 5),
        _label('توصيات مبنية على ظروف حديقتك وتفضيلات العناية.', size: 14, color: _muted),
        const SizedBox(height: 12),
        _solidSmallButton('عرض التوصيات', () => _openPage(RecommendedPlantsScreen(initialResults: _recommendationResults))),
      ])),
    ]),
  );

  Widget _solidSmallButton(String title, VoidCallback action) =>
    Material(color: _green, borderRadius: BorderRadius.circular(22), child: InkWell(
      onTap: action, borderRadius: BorderRadius.circular(22),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _label(title, size: 14, color: Colors.white, weight: FontWeight.w700),
          const SizedBox(width: 7),
          const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 17),
        ])),
    ));

  Widget _sectionHeader(String title, {VoidCallback? action}) => Row(children: [
    Expanded(child: _label(title, size: 18, weight: FontWeight.w800)),
    if (action != null) Material(
      color: _light,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _label('عرض الكل', size: 14, color: _green, weight: FontWeight.w700),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: _green, size: 20),
          ]),
        ),
      ),
    ),
  ]);

  Widget _recommendedSection() {
    final items = _recommended.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sectionHeader('نباتات مقترحة لك', action: () => _openPage(RecommendedPlantsScreen(initialResults: _recommendationResults))),
      const SizedBox(height: 9),
      if (_loading && items.isEmpty)
        const _SmallLoader()
      else if (_recommendationsError != null && items.isEmpty)
        _emptyMessage(_recommendationsError!, Icons.error_outline_rounded)
      else if (items.isEmpty)
        _emptyMessage('لا توجد توصيات متاحة حاليًا.', Icons.auto_awesome_outlined)
      else SizedBox(height: 280, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, index) => _plantCard(items[index].plant,
          score: items[index].score),
      )),
    ]);
  }

  Widget _plantCard(Plant plant, {double? score}) {
    return SizedBox(width: 164, child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
            child: ClipRRect(borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 142, child: Stack(
                fit: StackFit.expand,
                children: [
                  _plantImage(plant),
                  PositionedDirectional(
                    end: 6, top: 6,
                    child: RuwaSavedBadge(plantId: plant.id, compact: true),
                  ),
                ],
              )))),
          Padding(padding: const EdgeInsets.fromLTRB(7, 5, 7, 0),
            child: _label(plant.displayName, size: 14, weight: FontWeight.w700,
              align: TextAlign.center, maxLines: 1)),
          if (score != null)
            Center(child: Padding(padding: const EdgeInsets.only(top: 3),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(18)),
                child: _label('${score.clamp(0, 100).toStringAsFixed(0)}% توافق',
                  size: 13, color: _green, weight: FontWeight.w700))))
          else const SizedBox(height: 6),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
            child: Material(color: const Color(0xFFF0F4ED), borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _openPage(PlantDetailsScreen(plant: plant)),
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(height: 48, child: Center(
                  child: _label('عرض التفاصيل', color: _green, size: 14, weight: FontWeight.w700),
                )),
              )),
          ),
        ]),
      ),
    ));
  }

  Widget _plantImage(Plant plant) =>
      RuwaPlantImage(scientificName: plant.scientificName);

  Widget _savedSection() => Material(
    color: const Color(0xFFF4F2E9),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: _openMyPlants, borderRadius: BorderRadius.circular(18),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(children: [
          Container(width: 43, height: 43,
            decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.bookmark_border_rounded, color: _green, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('نباتاتي المحفوظة', size: 16, weight: FontWeight.w800),
            _label(_savedError != null ? 'تعذّر تحميل النباتات المحفوظة'
                : _saved.isEmpty ? 'لا توجد نباتات محفوظة بعد'
                : '${_saved.length} ${_saved.length == 1 ? 'نبات محفوظ' : 'نباتات محفوظة'}',
              size: 14, color: _muted),
          ])),
          const Icon(Icons.chevron_left_rounded, color: _green, size: 23),
        ])),
    ),
  );

  // Tips are swipeable in RTL and also advance automatically every six seconds.
  Widget _tipsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD1A12F), size: 23),
          const SizedBox(width: 7),
          _label('نصائح زراعية', size: 17, weight: FontWeight.w800),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: Listener(
            onPointerDown: (_) {
              _isTouchingTips = true;
              _tipsTimer?.cancel();
            },
            onPointerUp: (_) {
              _isTouchingTips = false;
              _scheduleNextTip();
            },
            onPointerCancel: (_) {
              _isTouchingTips = false;
              _scheduleNextTip();
            },
            child: PageView.builder(
            controller: _tipsController,
            itemCount: _tips.length,
            onPageChanged: (index) {
              setState(() => _tipIndex = index);
              _scheduleNextTip();
            },
            itemBuilder: (context, index) {
              final tip = _tips[index];
              return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 56, height: 70,
                  decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(14)),
                  child: Icon(tip.icon, color: _green, size: 29),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(tip.title, size: 15, weight: FontWeight.w700),
                    const SizedBox(height: 4),
                    _label(tip.body, size: 14, color: _muted),
                  ],
                )),
              ]);
            },
          ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int index = 0; index < _tips.length; index++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _tipIndex ? 17 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _tipIndex ? _green : _border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _emptyMessage(String message, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    child: Row(children: [Icon(icon, color: _green), const SizedBox(width: 10),
      Expanded(child: _label(message, size: 14, color: _muted))]),
  );

  Widget _notice(String message) => _emptyMessage(message, Icons.info_outline_rounded);


}

class _SmallLoader extends StatelessWidget {
  const _SmallLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 90,
    child: Center(child: CircularProgressIndicator(color: Color(0xFF315B32))));
}

// Botanical illustration drawn with Flutter itself: responsive, no network or image assets.


class _GardenSetupPainter extends CustomPainter {
  const _GardenSetupPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // نظام إحداثيات موحّد يحافظ على تناسب الرسمة.
    final scaleX = size.width / 330;
    final scaleY = size.height / 140;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();

    canvas.translate(
      (size.width - 330 * scale) / 2,
      (size.height - 140 * scale) / 2,
    );

    canvas.scale(scale);

    // ========================================
    // ظل خفيف أسفل الرسمة
    // ========================================

    canvas.drawOval(
      const Rect.fromLTWH(40, 126, 253, 8),
      Paint()..color = const Color(0x184F7547),
    );

    // ========================================
    // لوحة إعداد الحديقة
    // ========================================

    canvas.save();
    canvas.translate(212, 13);
    canvas.rotate(0.025);

    // ظل اللوحة
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 4, 93, 111),
        const Radius.circular(13),
      ),
      Paint()..color = const Color(0x18705B41),
    );

    // الإطار الفخاري
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 93, 111),
        const Radius.circular(13),
      ),
      Paint()..color = const Color(0xFFC79B6E),
    );

    // الورقة البيضاء
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 9, 75, 93),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFFFCF5),
    );

    // المشبك العلوي
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, -7, 40, 15),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF749564),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, -11, 18, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF92B17B),
    );

    // ========================================
    // مهام الحديقة
    // ========================================

    final outlinePaint = Paint()
      ..color = const Color(0xFFA0BA92)
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final textLinePaint = Paint()
      ..color = const Color(0xFF8EAA7F)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final y = 26.0 + (i * 25);

      // مربع المهمة
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(18, y, 12, 12),
          const Radius.circular(2.5),
        ),
        outlinePaint,
      );

      // علامتا إنجاز للمهمتين الأوليين
      if (i < 2) {
        final checkPath = Path()
          ..moveTo(20, y + 6)
          ..lineTo(23, y + 9)
          ..lineTo(28, y + 3);

        canvas.drawPath(
          checkPath,
          Paint()
            ..color = const Color(0xFF497B4D)
            ..strokeWidth = 1.9
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        );
      }

      // السطر بجانب المهمة
      canvas.drawLine(
        Offset(39, y + 6),
        Offset(72 - i * 4, y + 6),
        textLinePaint,
      );
    }

    canvas.restore();

    // ========================================
    // النبتة: الرسم نفسه في بطاقة التوصيات
    // ========================================

    // موضع النبتة داخل بطاقة الإعداد.
    const double plantScale = 0.79;

    canvas.save();

    canvas.translate(
      106 - (77 * plantScale),
      73 - (80 * plantScale),
    );

    canvas.scale(plantScale);

    // إعادة استخدام الرسمة الأصلية
    // لتوحيد شكل النبتة بين حالتي الصفحة.
    _PlantPotPainter().paint(
      canvas,
      const Size(154, 154),
    );

    canvas.restore();

    // ========================================
    // تفاصيل زخرفية بسيطة وغير مزدحمة
    // ========================================

    final accent = Paint()
      ..color = const Color(0xFFB8CBA5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // لمعة بسيطة
    canvas.drawLine(
      const Offset(28, 39),
      const Offset(28, 49),
      accent,
    );

    canvas.drawLine(
      const Offset(23, 44),
      const Offset(33, 44),
      accent,
    );

    // نقاط زخرفية
    canvas.drawCircle(
      const Offset(193, 26),
      2.2,
      Paint()..color = const Color(0xFFC9B18C),
    );

    canvas.drawCircle(
      const Offset(32, 110),
      2.5,
      Paint()..color = const Color(0xFFB7CDA0),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _PlantPotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // A softly detailed botanical illustration, drawn locally with Flutter.
    final center = Offset(size.width * .50, size.height * .52);
    final unit = size.shortestSide / 154;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(unit);

    const dark = Color(0xFF38663D);
    const mid = Color(0xFF598A4F);
    const sage = Color(0xFF83A96B);
    const soft = Color(0xFFA8BD89);
    final stemPaint = Paint()
      ..color = const Color(0xFF58804A)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Ground shadow, behind the planter.
    canvas.drawOval(
      const Rect.fromLTWH(-58, 66, 116, 9),
      Paint()..color = const Color(0x23456C39),
    );

    // Natural, slightly curved branches.
    void branch(Offset from, Offset control, Offset to) {
      canvas.drawPath(
        Path()..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy),
        stemPaint,
      );
    }

    branch(const Offset(0, 22), const Offset(1, -18), const Offset(-2, -67));
    branch(const Offset(-1, 2), const Offset(-19, -20), const Offset(-43, -31));
    branch(const Offset(-1, -13), const Offset(24, -32), const Offset(43, -45));
    branch(const Offset(-2, -35), const Offset(-20, -50), const Offset(-27, -64));
    branch(const Offset(0, -1), const Offset(17, -13), const Offset(33, -15));
    // Two smaller shoots make the pot feel fuller without obscuring the card.
    branch(const Offset(-19, 19), const Offset(-40, -2), const Offset(-55, -21));
    branch(const Offset(20, 19), const Offset(47, 1), const Offset(59, -22));
    branch(const Offset(-16, 14), const Offset(-31, -2), const Offset(-27, -22));
    branch(const Offset(18, 10), const Offset(30, -4), const Offset(39, -19));

    // Pointed leaves, with a gentle highlight and a fine central vein.
    void leaf(Offset origin, double angle, double length, double width, Color color) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle * 3.141592653589793 / 180);
      final outline = Path()
        ..moveTo(0, 0)
        ..cubicTo(-width * .70, -length * .27,
            -width * .57, -length * .78, 0, -length)
        ..cubicTo(width * .65, -length * .74,
            width * .64, -length * .25, 0, 0)
        ..close();
      canvas.drawPath(outline, Paint()..color = color);
      final highlight = Path()
        ..moveTo(0, -length * .1)
        ..quadraticBezierTo(-width * .24, -length * .49, 0, -length * .88)
        ..quadraticBezierTo(-width * .30, -length * .54, 0, -length * .1);
      canvas.drawPath(highlight, Paint()..color = const Color(0x2FFFFFFF));
      canvas.drawPath(
        Path()..moveTo(0, -3)
          ..quadraticBezierTo(-width * .09, -length * .45, 0, -length * .88),
        Paint()..color = const Color(0x66E4F0D3)
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }

    leaf(const Offset(-2, -46), 2, 37, 20, dark);
    leaf(const Offset(-24, -19), -46, 35, 18, mid);
    leaf(const Offset(-43, -31), -66, 32, 18, sage);
    leaf(const Offset(-27, -49), -30, 32, 17, soft);
    leaf(const Offset(-3, -65), -8, 24, 14, mid);
    leaf(const Offset(19, -27), 48, 37, 20, mid);
    leaf(const Offset(43, -45), 56, 34, 18, sage);
    leaf(const Offset(33, -15), 76, 28, 16, dark);
    leaf(const Offset(2, -16), 19, 31, 17, soft);
    // Additional small leaves and low foliage on the new shoots.
    leaf(const Offset(-55, -20), -53, 24, 13, dark);
    leaf(const Offset(-43, -9), -115, 20, 12, sage);
    leaf(const Offset(-27, -21), -8, 21, 12, mid);
    leaf(const Offset(59, -22), 57, 23, 13, soft);
    leaf(const Offset(47, -7), 112, 21, 12, mid);
    leaf(const Offset(39, -18), 22, 22, 12, sage);
    leaf(const Offset(-13, 7), -56, 18, 11, soft);
    leaf(const Offset(12, 9), 61, 19, 11, dark);

    // Planter: visible soil, softly tapered body and a curved rim.
    canvas.drawOval(
      const Rect.fromLTWH(-36, 18, 72, 12),
      Paint()..color = const Color(0xFF8A6C4E),
    );
    final potBody = Path()
      ..moveTo(-41, 23)
      ..lineTo(41, 23)
      ..lineTo(32, 59)
      ..quadraticBezierTo(0, 70, -32, 59)
      ..close();
    canvas.drawPath(
      potBody,
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFFE5C49B), Color(0xFFD2A575), Color(0xFFBF8D60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(-43, 20, 86, 50)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-46, 18, 92, 12),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFFD6AB7B),
    );
    canvas.drawPath(
      Path()..moveTo(-26, 39)..quadraticBezierTo(-2, 49, 22, 40),
      Paint()..color = const Color(0x44FFFFFF)
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
