import 'dart:async';

import 'package:flutter/material.dart';
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

  GardenProfile? _garden;
  WeatherData? _weather;
  bool _weatherLoading = false;
  bool _weatherStale = false;
  int _weatherRequestVersion = 0;
  int _reloadVersion = 0;
  List<Plant> _saved = const [];
  List<PlantRecommendation> _recommended = const [];
  bool _loading = true;
  bool _hasLoadedOnce = false;
  bool _gardenLoaded = false;
  String? _error;
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const _tips = <({String title, String body, IconData icon})>[
    (title: 'الإضاءة المناسبة', body: 'تختلف احتياجات النباتات للضوء؛ فبعضها يفضّل الشمس المباشرة، وبعضها ينمو أفضل في الظل الجزئي.', icon: Icons.wb_sunny_outlined),
    (title: 'توقيت الري', body: 'يُفضّل ري النباتات في الصباح الباكر لتقليل فقدان الماء بالتبخر، خاصةً في الأجواء الحارة.', icon: Icons.water_drop_outlined),
    (title: 'مساحة النمو', body: 'اتركي مساحة كافية لنمو النباتات؛ فبعضها يتمدد ويحتاج مساحة أكبر مع مرور الوقت.', icon: Icons.straighten_rounded),
    (title: 'تحمّل المناخ', body: 'قد تتحمّل بعض النباتات حرارة الصيف، بينما تحتاج نباتات أخرى إلى حماية إضافية من أشعة الشمس الشديدة.', icon: Icons.thermostat_outlined),
    (title: 'مستوى العناية', body: 'بعض النباتات تحتاج متابعة مستمرة، بينما تكتفي أنواع أخرى بعناية أقل بعد استقرار نموها.', icon: Icons.eco_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _reload();
    _startTips();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reload();
    if (widget.active != oldWidget.active) {
      widget.active ? _startTips() : _tipTimer?.cancel();
    }
  }

  void _startTips() {
    _tipTimer?.cancel();
    if (!widget.active) return;
    _tipTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final request = ++_reloadVersion;
    if (!mounted) return;
    setState(() { _loading = !_hasLoadedOnce; _error = null; });

    // Keep existing garden and weather visible while other tabs are visited.
    GardenProfile? garden = _garden;
    List<Plant> saved = _saved;
    List<PlantRecommendation> recommended = _recommended;
    String? error;
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
    } catch (_) { error ??= 'تعذر تحميل نباتاتك.'; }
    if (garden != null) {
      try {
        final results = await RecommendationEngine.instance.getRecommendations();
        recommended = [...results.tolerantPlants, ...results.sensitivePlants]
          ..sort((a, b) => b.score.compareTo(a.score));
      } catch (_) { error ??= 'تعذر تحميل التوصيات.'; }
    } else if (gardenLoaded) {
      recommended = const [];
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
      // Only replace the reading when the actual saved location changes.
      if (!sameLocation) {
        _weatherRequestVersion++;
        _weather = cached;
        _weatherStale = false;
      } else if (_weather == null && cached != null) {
        _weather = cached;
      }
      _error = error;
      _loading = false;
      _hasLoadedOnce = true;
    });

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

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page))
        .then((_) { if (mounted) _reload(); });
  }

  Text _text(String value, {double size = 14, Color color = _dark, FontWeight weight = FontWeight.w500}) =>
      Text(value, textAlign: TextAlign.right, style: GoogleFonts.cairo(
        fontSize: size, color: color, fontWeight: weight, height: 1.45));

  Widget _surface({required Widget child, Color color = Colors.white, EdgeInsetsGeometry padding = const EdgeInsets.all(15)}) =>
      Container(padding: padding, decoration: BoxDecoration(color: color,
        borderRadius: BorderRadius.circular(19), border: Border.all(color: _border)), child: child);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              _header(),
              const SizedBox(height: 16),
              _weatherCard(),
              const SizedBox(height: 22),
              _heading('الوصول السريع'),
              const SizedBox(height: 12),
              _quickActions(),
              const SizedBox(height: 20),
              _gardenCard(),
              const SizedBox(height: 22),
              _heading('نباتاتي المحفوظة', onTap: () => _openPage(const MyPlantsScreen())),
              const SizedBox(height: 11),
              _plantStrip(_saved, saved: true),
              const SizedBox(height: 22),
              _heading('النباتات الموصى بها لك', onTap: () {
                if (_garden == null) { widget.onSelectTab(2); return; }
                _openPage(const RecommendedPlantsScreen());
              }),
              const SizedBox(height: 11),
              _plantStrip(_recommended.map((e) => e.plant).toList(), saved: false),
              const SizedBox(height: 22),
              _heading('نصائح سريعة'),
              const SizedBox(height: 11),
              _tipsCarousel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final firstName = widget.name.trim().split(' ').first;
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _text('أهلًا ${firstName.isEmpty ? 'بك' : 'يا $firstName'}!', size: 25, weight: FontWeight.w800),
        _text('معًا لبيئة أكثر خضرة في كل يوم', size: 14, weight: FontWeight.w500, color: const Color(0xFF6E796B)),
      ])),
      _circleButton(Icons.notifications_none_rounded, () => widget.onSelectTab(3)),
      const SizedBox(width: 7),
      _circleButton(Icons.person_outline_rounded, () => widget.onSelectTab(4)),
    ]);
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) =>
      Material(color: _light, borderRadius: BorderRadius.circular(50), child:
        InkWell(borderRadius: BorderRadius.circular(50), onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(11),
            child: Icon(icon, color: _green, size: 23))));

  Widget _weatherCard() {
    // The initial state is loading, NOT an unconfigured garden.
    // A location is displayed only with actual successfully retrieved weather.
    final weather = _weather;
    final isInitialLoading = !_gardenLoaded || (_garden != null &&
        weather == null && (_loading || _weatherLoading));
    final hasGarden = _garden != null;
    final hasCoordinates = _garden?.latitude != null && _garden?.longitude != null;
    final temp = weather?.temperatureC;
    final humidity = weather?.humidity;
    final wind = weather?.windSpeedMs;
    final city = _garden?.city?.trim();
    final rawCity = city != null && city.isNotEmpty ? city : (weather?.city ?? '');
    final location = rawCity.toLowerCase() == 'riyadh' ||
            rawCity.toLowerCase() == 'ar riyadh'
        ? 'الرياض' : rawCity;
    final description = weather?.description?.trim();
    final tempLabel = temp == null ? '—' : '${temp.round()}°';
    final windLabel = wind == null ? '—' : (wind * 3.6).toStringAsFixed(1);

    final content = isInitialLoading
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 26, height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
            const SizedBox(height: 11),
            Text('جارٍ جلب معلومات طقس حديقتك', textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 15,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          ])
        : !hasGarden
            ? Center(child: Text('أعد حديقتك لعرض طقس موقعها',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16,
                    fontWeight: FontWeight.w700, color: Colors.white)))
            : !hasCoordinates
                ? Center(child: Text('موقع الحديقة غير متاح لعرض الطقس',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.white)))
                : weather == null
                    ? Center(child: Text('تعذّر جلب طقس حديقتك حاليًا',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 15,
                            fontWeight: FontWeight.w700, color: Colors.white)))
                    : Column(children: [
                        Row(textDirection: TextDirection.ltr, children: [
                          Expanded(flex: 5, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.wb_sunny_rounded,
                                    color: Color(0xFFFFDE73), size: 34),
                                const SizedBox(width: 6),
                                Text(tempLabel, style: GoogleFonts.cairo(
                                    fontSize: 29, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                              ]),
                              Text(description != null && description.isNotEmpty
                                      ? description : 'طقس حديقتك الحالي',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.cairo(color: Colors.white,
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                              if (location.isNotEmpty) Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.place_outlined,
                                      color: Colors.white70, size: 15),
                                  const SizedBox(width: 3),
                                  Flexible(child: Text(location, maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(color: Colors.white70,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700))),
                                ],
                              ),
                            ],
                          )),
                          Container(width: 1, height: 94, color: Colors.white38,
                            margin: const EdgeInsets.symmetric(horizontal: 10)),
                          Expanded(flex: 5, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _weatherMetric(Icons.water_drop_outlined, 'الرطوبة',
                                  humidity == null ? '—' : '$humidity%'),
                              const SizedBox(height: 8),
                              _weatherMetric(Icons.thermostat_outlined,
                                  'الحرارة', tempLabel),
                              const SizedBox(height: 8),
                              _weatherMetric(Icons.air_rounded,
                                  'الرياح', '$windLabel كم/س'),
                            ],
                          )),
                        ]),
                        if (_weatherStale) Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Text('آخر قراءة محفوظة — تعذّر تحديث الطقس',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(color: Colors.white70,
                                fontSize: 11.5)),
                        ),
                      ]);

    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: _green, borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF244A32), Color(0xFF477652)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      ),
      child: content,
    );
  }

  Widget _weatherMetric(IconData icon, String title, String value) => Row(
    textDirection: TextDirection.rtl,
    children: [
      Icon(icon, color: Colors.white, size: 17),
      const SizedBox(width: 5),
      Expanded(child: Text('$title  $value', maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))),
    ],
  );

  Widget _heading(String title, {VoidCallback? onTap}) => Row(
    textDirection: TextDirection.rtl,
    children: [
      Expanded(child: _text(title, size: 17, weight: FontWeight.w800)),
      if (onTap != null) Material(
        color: const Color(0xFFE7F0E3),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                _text('عرض الكل', size: 13, color: _green, weight: FontWeight.w700),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: _green, size: 20),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _quickActions() {
    final actions = <({String text, IconData icon, VoidCallback onTap})>[
      (text: _garden == null ? 'إعداد الحديقة' : 'حديقتي', icon: Icons.yard_outlined, onTap: () => widget.onSelectTab(2)),
      (text: 'البحث', icon: Icons.search_rounded, onTap: () => widget.onSelectTab(1)),
      (text: 'نباتاتي', icon: Icons.local_florist_outlined, onTap: () => _openPage(const MyPlantsScreen())),
      (text: 'الموصى بها لك', icon: Icons.auto_awesome_outlined, onTap: () {
        if (_garden == null) { widget.onSelectTab(2); return; }
        _openPage(const RecommendedPlantsScreen());
      }),
    ];
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i != 0) const SizedBox(width: 7),
          Expanded(
            child: Material(
              color: _light,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: actions[i].onTap,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 91,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(actions[i].icon, color: _green, size: 27),
                        const SizedBox(height: 7),
                        Text(
                          actions[i].text,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: _dark, fontSize: 10, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _gardenCard() => _surface(color: _light, child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.spa_outlined, color: _green, size: 23), const SizedBox(width: 7), _text('ملخص حديقتك', size: 18, weight: FontWeight.w800)]),
      const SizedBox(height: 11),
      Row(children: [
        Expanded(child: _counter('النباتات المحفوظة', '${_saved.length}', Icons.bookmark_outline)),
        const SizedBox(width: 10),
        Expanded(child: _counter('النباتات الموصى بها لك', _garden == null || (_error == 'تعذر تحميل التوصيات.') ? '—' : '${_recommended.length}', Icons.auto_awesome_outlined)),
      ]),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => widget.onSelectTab(2),
        style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(_garden == null ? 'إعداد حديقتي' : 'عرض حديقتي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700)))),
    ],
  ));

  Widget _counter(String title, String value, IconData icon) =>
      Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
        child: Column(children: [Icon(icon, color: _green), const SizedBox(height: 4),
          _text(value, size: 23, weight: FontWeight.w800),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 10, color: _dark))]));

  Widget _plantStrip(List<Plant> plants, {required bool saved}) {
    if (_loading && plants.isEmpty) {
      return const SizedBox(height: 145,
        child: Center(child: CircularProgressIndicator(color: _green)));
    }
    if (plants.isEmpty) {
      return _surface(child: _text(saved
        ? 'لا توجد نباتات محفوظة بعد'
        : (_garden == null ? 'أعد حديقتك أولًا لعرض النباتات الموصى بها لك' : 'لا توجد نباتات موصى بها لك حاليًا'),
        color: const Color(0xFF667467), size: 12));
    }
    return SizedBox(
      height: saved ? 212 : 261,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        itemCount: plants.length > 8 ? 8 : plants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plant = plants[index];
          final PlantRecommendation? match = saved ? null :
              _recommended.firstWhere((r) => r.plant.id == plant.id);
          final bool sensitive = (plant.climateToleranceClass ?? '')
              .trim().toLowerCase() == 'sensitive';
          final statusColor = sensitive ? const Color(0xFF9A6A32) : _green;
          final score = match?.score.clamp(0.0, 100.0).toDouble();
          return SizedBox(
            width: 148,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: _border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openPage(PlantDetailsScreen(plant: plant)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: _plantImage(plant, height: 130),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
                      child: Text(plant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: _dark,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    if (score != null) ...[
                      Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
                        decoration: BoxDecoration(
                          color: sensitive ? const Color(0xFFF8ECDD) : const Color(0xFFE4EFE0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(sensitive ? 'حساس' : 'مقاوم',
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700,
                            color: statusColor)),
                      )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 2),
                        child: Row(textDirection: TextDirection.rtl, children: [
                          Text('${score.toStringAsFixed(0)}%',
                            style: GoogleFonts.cairo(fontSize: 11, color: statusColor,
                              fontWeight: FontWeight.w700)),
                          const SizedBox(width: 5),
                          Expanded(child: LinearProgressIndicator(
                            value: (score / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            color: statusColor,
                            backgroundColor: const Color(0xFFE8F0E4),
                          )),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Container(
                        height: 31,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF2EA),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('عرض التفاصيل',
                          style: GoogleFonts.cairo(color: _green,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _plantImage(Plant plant, {required double height}) => FutureBuilder<String?>(
    future: PlantImageService.instance.imageFor(plant.scientificName),
    builder: (context, snapshot) {
      final url = snapshot.data;
      if (url == null || url.isEmpty) return Container(height: height,
        color: _light, child: const Icon(Icons.local_florist_outlined, color: _green, size: 35));
      return Image.network(url, height: height, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(height: height,
          color: _light, child: const Icon(Icons.local_florist_outlined, color: _green, size: 35)));
    },
  );

  Widget _tipsCarousel() {
    final tip = _tips[_tipIndex];
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 120) _changeTip(velocity < 0 ? -1 : 1);
      },
      child: _surface(
        color: _light,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
        child: Column(children: [
          Row(textDirection: TextDirection.ltr, children: [
            IconButton(
              tooltip: 'النصيحة التالية باتجاه اليسار',
              onPressed: () => _changeTip(1),
              icon: const Icon(Icons.chevron_left_rounded, color: _green, size: 28),
            ),
            Expanded(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, children: [
                  Icon(tip.icon, color: _green, size: 25),
                  const SizedBox(width: 8),
                  Flexible(child: Text(tip.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 15, color: _dark,
                      fontWeight: FontWeight.w800))),
                ]),
              const SizedBox(height: 5),
              Text(tip.body, textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12.5,
                  color: const Color(0xFF4B6651), height: 1.5)),
            ])),
            IconButton(
              tooltip: 'النصيحة السابقة باتجاه اليمين',
              onPressed: () => _changeTip(-1),
              icon: const Icon(Icons.chevron_right_rounded, color: _green, size: 28),
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.ltr,
            children: [
              for (var i = 0; i < _tips.length; i++) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () { setState(() => _tipIndex = i); _startTips(); },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: i == _tipIndex ? 18 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: i == _tipIndex ? _green : const Color(0xFFC2D1BD),
                      borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  void _changeTip(int offset) {
    setState(() => _tipIndex = (_tipIndex + offset + _tips.length) % _tips.length);
    _startTips();
  }
}
