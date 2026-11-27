import '../widgets/ruwa_saved_badge.dart';
import '../widgets/ruwa_plant_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/garden_profile.dart';
import '../services/garden_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'my_plants_screen.dart';
import 'setup_garden_screen.dart';
import 'recommended_plants_screen.dart';
import 'plant_details_screen.dart';
import '../models/plant.dart';
import '../services/my_plant_service.dart';
import '../services/recommendation_engine.dart';
import '../utils/ruwa_notice.dart';
class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});
  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}
class _MyGardenScreenState extends State<MyGardenScreen> {
  GardenProfile? garden;
  bool isLoading = true;
  bool isCheckingLocation = false;
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = false;
  String? weatherError;
  late Future<List<Plant>> _savedPreview;
  late Future<RecommendationResults> _recommendationPreview;

  void _loadPreviews() {
    _savedPreview = MyPlantService.instance.getMyPlants();
    _recommendationPreview = RecommendationEngine.instance.getRecommendations();
  }

  @override
  void initState() {
    super.initState();
    _loadPreviews();
    _loadGarden();
  }
  // ============================================================
  // تحميل بيانات الحديقة
  // ============================================================
  Future<void> _loadGarden() async {
    setState(() => isLoading = true);
    final result =
        await GardenService.instance.getGarden();
    if (!mounted) return;
    setState(() {
      garden = result;
      isLoading = false;
    });
    if (result != null) {
      setState(_loadPreviews);
      _loadWeather(result);
    }
  }
  // ============================================================
  // تحميل بيانات الطقس باستخدام موقع الحديقة المحفوظ
  // ============================================================
  Future<void> _loadWeather(GardenProfile g) async {
    final latitude = g.latitude;
    final longitude = g.longitude;
    if (latitude == null || longitude == null) {
      if (!mounted) return;
      setState(() {
        weatherData = null;
        weatherError = 'بيانات موقع الحديقة غير متوفرة.';
        isLoadingWeather = false;
      });
      return;
    }
    setState(() {
      isLoadingWeather = true;
      weatherError = null;
    });
    try {
      final result = await WeatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        weatherData = result.toMap();
        weatherError = null;
      });
    } catch (e) {
      debugPrint('WEATHER ERROR: $e');
      if (!mounted) return;
      var message = e.toString();
      message = message.replaceFirst('Exception: ', '');
      setState(() {
        weatherData = null;
        weatherError = message;
      });
    } finally {
      if (mounted) {
        setState(() => isLoadingWeather = false);
      }
    }
  }
  // ============================================================
  // فتح صفحة إعداد / تعديل الحديقة
  // ============================================================
 
  Future<void> _openSetupOrEdit() async {
    // Edit an existing garden without verifying location again.
    if (garden != null) {
      final result = await Navigator.push<GardenProfile>(
        context,
        MaterialPageRoute(
          builder: (context) => SetupGardenScreen(
            existingGarden: garden,
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() => garden = result);
        _loadWeather(result);
        setState(_loadPreviews);
      }

      return;
    }

    // Prevent repeated requests during location verification.
    if (isCheckingLocation) return;

    setState(() => isCheckingLocation = true);

    try {
      // 1. Get the device's current location.
      final position =
          await LocationService.getCurrentLocation();

      if (!mounted) return;

      // 2. Retrieve location details through LocationService.
      Map<String, dynamic> locationData;

      try {
        locationData =
            await LocationService.getLocationDetails(position);
      } catch (_) {
        if (!mounted) return;

        _showLocationMessage(
          'تعذر التحقق من موقعك حالياً. '
          'يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى.',
        );

        return;
      }

      if (!mounted) return;

      // 3. Verify whether the location is supported.
      final isWithinRiyadh =
          LocationService.isWithinSupportedArea(locationData);

      if (!isWithinRiyadh) {
        _showLocationMessage(
          'رُوى متاح حالياً للحدائق الموجودة '
          'في منطقة الرياض ومحافظاتها فقط.',
        );

        return;
      }

      // 4. Open garden setup with the verified location.
      final result = await Navigator.push<GardenProfile>(
        context,
        MaterialPageRoute(
          builder: (context) => SetupGardenScreen(
            latitude: position.latitude,
            longitude: position.longitude,
            city: locationData['city']?.toString(),
            state: locationData['state']?.toString(),
            country: locationData['country']?.toString(),
            formattedAddress:
                locationData['formatted']?.toString(),
            locationVerified: true,
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() => garden = result);
        _loadWeather(result);
        setState(_loadPreviews);
      }
    } catch (e) {
      if (!mounted) return;

      var message = e.toString();
      message = message.replaceFirst('Exception: ', '');

      _showLocationMessage(message);
    } finally {
      if (mounted) {
        setState(() => isCheckingLocation = false);
      }
    }
  }
  void _showLocationMessage(String message) {
    if (!mounted) return;
    RuwaNotice.show(context, message, success: false);
  }
  // UI spacing and typography follow the same visual language as Home.
  static const Color _green = Color(0xFF315B32);
  static const Color _dark = Color(0xFF234525);
  static const Color _light = Color(0xFFE8F0E4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _muted = Color(0xFF4E604D);

  Text _label(String value, {double size = 14, Color color = _dark,
      FontWeight weight = FontWeight.w500, TextAlign align = TextAlign.right,
      int? maxLines}) => Text(value, textDirection: TextDirection.rtl,
      textAlign: align, maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: GoogleFonts.cairo(fontSize: size, fontWeight: weight,
          color: color, height: 1.45));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F4),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            children: [
              Row(children: [
                const Icon(Icons.eco_outlined, color: _green, size: 27),
                const SizedBox(width: 8),
                _label('حديقتي', size: 25, weight: FontWeight.w800),
              ]),
              const SizedBox(height: 3),
              _label('كل ما تحتاجه لحديقتك في مكان واحد', size: 14,
                  color: _muted),
              const SizedBox(height: 22),
              if (isLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 65),
                    child: Center(child: CircularProgressIndicator(color: _green)))
              else if (garden == null)
                _emptyState(1, 1)
              else ...[
                _weatherPlaceholderCard(1, 1),
                const SizedBox(height: 18),
                _gardenDataCard(garden!, 1, 1),
                const SizedBox(height: 28),
                _myPlantsSection(1, 1),
                const SizedBox(height: 28),
                _recommendedPlantsSection(1, 1),
                const SizedBox(height: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // الحالة الفاضية
  // ============================================================
  Widget _emptyState(
    double scaleX,
    double scaleY,
  ) {
    return SizedBox(
      height: 500 * scaleY,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco_outlined,
              color: const Color(0xFF6F8F64),
              size: 60 * scaleX,
            ),
            SizedBox(height: 16 * scaleY),
            Text(
              'لم يتم إعداد بيانات حديقتك بعد',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: const Color(0xFF234525),
                fontSize: 16 * scaleX,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6 * scaleY),
            Text(
              'أضف اتجاه الواجهة ومساحة الزراعة للحصول على توصيات مناسبة',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: const Color(0xFF7D8079),
                fontSize: 13 * scaleX,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24 * scaleY),
            SizedBox(
              height: 50 * scaleY,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCheckingLocation ? null : _openSetupOrEdit,
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return const Color(0xFF6F8F64);
                    }
                    return const Color(0xFF315B32);
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                child: isCheckingLocation
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: TextDirection.rtl,
                        children: [
                          SizedBox(
                            width: 19 * scaleX,
                            height: 19 * scaleX,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10 * scaleX),
                          Text(
                            'جاري التحقق من موقعك...',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 14 * scaleX,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'إعداد حديقتي',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 15 * scaleX,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // بطاقة الطقس
  // ============================================================
  Widget _weatherPlaceholderCard(double scaleX, double scaleY) {
    String temperature = '—';
    String humidity = '—';
    String windSpeed = '—';
    String daylightHours = '—';
    String statusText = 'جارٍ تحميل بيانات الطقس...';
    if (!isLoadingWeather && weatherData != null) {
      final temp = weatherData!['temperature'] as double?;
      final humidityValue = weatherData!['humidity'] as int?;
      final wind = weatherData!['windSpeed'] as double?;
      final sunrise = weatherData!['sunrise'] as int?;
      final sunset = weatherData!['sunset'] as int?;
      final description = weatherData!['description']?.toString();
      if (temp != null) temperature = '${temp.round()}°';
      if (humidityValue != null) humidity = '$humidityValue%';
      if (wind != null) windSpeed = '${(wind * 3.6).toStringAsFixed(1)} كم/س';
      if (sunrise != null && sunset != null && sunset > sunrise) {
        daylightHours = '${((sunset - sunrise) / 3600).toStringAsFixed(1)} س';
      }
      statusText = description != null && description.isNotEmpty
          ? description : 'حالة الطقس الحالية';
    } else if (!isLoadingWeather && weatherError != null) {
      statusText = 'تعذّر تحميل بيانات الطقس حاليًا';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: const LinearGradient(
          colors: [Color(0xFF294F32), Color(0xFF46744E)],
          begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFDD8C), size: 25),
          const SizedBox(width: 9),
          Expanded(child: _label('الظروف الحالية في حديقتك',
              size: 17, color: Colors.white, weight: FontWeight.w800)),
          if (isLoadingWeather)
            const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2,
                    color: Colors.white)),
        ]),
        const SizedBox(height: 3),
        _label(statusText, size: 13, color: const Color(0xFFE4F0DF)),
        const SizedBox(height: 17),
        LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;
          return compact
            ? Column(children: [
                Row(children: [
                  _weatherMetric(humidity, 'الرطوبة', Icons.water_drop_outlined),
                  _weatherMetric(temperature, 'درجة الحرارة', Icons.thermostat_outlined),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  _weatherMetric(windSpeed, 'سرعة الرياح', Icons.air_rounded),
                  _weatherMetric(daylightHours, 'ساعات النهار', Icons.wb_sunny_outlined),
                ]),
              ])
            : Row(children: [
                _weatherMetric(humidity, 'الرطوبة', Icons.water_drop_outlined),
                _weatherMetric(temperature, 'الحرارة', Icons.thermostat_outlined),
                _weatherMetric(windSpeed, 'الرياح', Icons.air_rounded),
                _weatherMetric(daylightHours, 'ساعات النهار', Icons.wb_sunny_outlined),
              ]);
        }),
      ]),
    );
  }

  Widget _weatherMetric(String value, String label, IconData icon) =>
      Expanded(child: Column(children: [
        Icon(icon, color: Colors.white, size: 23),
        const SizedBox(height: 7),
        FittedBox(fit: BoxFit.scaleDown,
          child: _label(value, size: 15, color: Colors.white,
              weight: FontWeight.w800, align: TextAlign.center)),
        const SizedBox(height: 2),
        _label(label, size: 12, color: const Color(0xFFE4F0DF),
            align: TextAlign.center, maxLines: 1),
      ]));

  // ============================================================
  // بطاقة بيانات الحديقة
  // ============================================================
  Widget _gardenDataCard(GardenProfile g, double scaleX, double scaleY) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: _label('بيانات الحديقة', size: 18,
              weight: FontWeight.w800)),
          Material(color: _light, borderRadius: BorderRadius.circular(24),
            child: InkWell(onTap: _openSetupOrEdit,
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.edit_outlined, color: _green, size: 18),
                    const SizedBox(width: 7),
                    Text('تعديل', style: GoogleFonts.cairo(color: _green,
                        fontSize: 14, fontWeight: FontWeight.w800)),
                  ]),
                )),
            )),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          return Column(children: [
            Row(children: [
              _gardenDatum(Icons.explore_outlined, 'اتجاه الواجهة',
                  g.facadeDirection.arabicLabel),
              const SizedBox(width: 10),
              _gardenDatum(Icons.square_foot_outlined, 'مساحة الزراعة',
                  '${_fmt(g.lengthMeters * g.widthMeters)} م²'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _gardenDatum(Icons.water_drop_outlined, 'مستوى الري',
                  g.wateringLevel.arabicLabel),
              const SizedBox(width: 10),
              _gardenDatum(Icons.eco_outlined, 'مستوى العناية',
                  g.careLevel.arabicLabel),
            ]),
          ]);
        }),
      ]),
    );
  }

  Widget _gardenDatum(IconData icon, String label, String value) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F8F2),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: _light,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _green, size: 22)),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(value, size: 14, weight: FontWeight.w800, maxLines: 1),
            _label(label, size: 12, color: _muted, maxLines: 2),
          ])),
      ]),
    ));

  String _fmt(double value) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }
    return value.toString();
  }
  // Both preview sections reuse the same card dimensions and typography as Home.
  Widget _myPlantsSection(double scaleX, double scaleY) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _previewHeader('نباتاتي', () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MyPlantsScreen()));
        if (mounted) setState(_loadPreviews);
      }),
      const SizedBox(height: 12),
      FutureBuilder<List<Plant>>(
        future: _savedPreview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 35),
              child: CircularProgressIndicator(color: _green)));
          }
          if (snapshot.hasError) {
            return _previewMessage('تعذّر تحميل النباتات المحفوظة.');
          }
          final plants = snapshot.data ?? [];
          if (plants.isEmpty) return _previewMessage('لا توجد نباتات محفوظة بعد');
          return SizedBox(height: 280, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plants.length > 3 ? 3 : plants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) => _smallPlantCard(plants[index]),
          ));
        },
      ),
    ]);
  }

  Widget _recommendedPlantsSection(double scaleX, double scaleY) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _previewHeader('النباتات الموصى بها لك', () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => const RecommendedPlantsScreen()));
        if (mounted) setState(_loadPreviews);
      }),
      const SizedBox(height: 12),
      FutureBuilder<RecommendationResults>(
        future: _recommendationPreview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 35),
              child: CircularProgressIndicator(color: _green)));
          }
          if (snapshot.hasError) {
            return _previewMessage('تعذّر تحميل النباتات الموصى بها حاليًا.');
          }
          final results = snapshot.data!;
          final items = [...results.tolerantPlants, ...results.sensitivePlants]
            ..sort((a, b) => b.score.compareTo(a.score));
          if (items.isEmpty) {
            return _previewMessage('لا توجد نباتات موصى بها لك حاليًا');
          }
          return SizedBox(height: 280, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length > 3 ? 3 : items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) => _smallPlantCard(
              items[index].plant, score: items[index].score),
          ));
        },
      ),
    ]);
  }

  Widget _previewHeader(String title, VoidCallback onTap) => Row(children: [
    Expanded(child: _label(title, size: 18, weight: FontWeight.w800)),
    Material(color: _light, borderRadius: BorderRadius.circular(23),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(23),
        child: Container(constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(23)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _label('عرض الكل', size: 14, color: _green,
                weight: FontWeight.w700),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: _green, size: 20),
          ]),
        ),
      ),
    ),
  ]);

  Widget _previewMessage(String message) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    child: _label(message, size: 14, color: _muted,
        align: TextAlign.center),
  );

  Widget _smallPlantCard(Plant plant, {double? score}) {
    return SizedBox(width: 164, child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
            child: ClipRRect(borderRadius: BorderRadius.circular(12),
              child: SizedBox(height: 142, child: score == null
                  ? _plantImage(plant)
                  : Stack(
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
            child: _label(plant.displayName, size: 14,
              weight: FontWeight.w700, align: TextAlign.center, maxLines: 1)),
          // In My Plants the single saved marker sits under the plant name.
          // Recommended plants keep the saved marker on the image instead.
          Center(child: Padding(padding: const EdgeInsets.only(top: 3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _light,
                borderRadius: BorderRadius.circular(18)),
              child: score == null
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _green, size: 14),
                      const SizedBox(width: 4),
                      _label('محفوظ', size: 13, color: _green,
                          weight: FontWeight.w700),
                    ])
                  : _label('${score.clamp(0, 100).toStringAsFixed(0)}% توافق',
                      size: 13, color: _green, weight: FontWeight.w700),
            ))),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(7, 0, 7, 7),
            child: Material(color: const Color(0xFFF0F4ED),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PlantDetailsScreen(plant: plant)));
                  if (mounted) setState(_loadPreviews);
                },
                child: SizedBox(height: 48,
                  child: Center(child: _label('عرض التفاصيل',
                    color: _green, size: 14, weight: FontWeight.w700))),
              ),
            ),
          ),
        ]),
      ),
    ));
  }

  Widget _plantImage(Plant plant) =>
      RuwaPlantImage(scientificName: plant.scientificName);
}
