import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/garden_profile.dart';
import '../services/garden_service.dart';
import '../services/location_service.dart';
import '../services/geoapify_service.dart';
import '../services/weather_service.dart';
import 'my_plants_screen.dart';
import 'setup_garden_screen.dart';
import 'recommended_plants_screen.dart';
import 'plant_details_screen.dart';
import '../models/plant.dart';
import '../services/my_plant_service.dart';
import '../services/recommendation_engine.dart';
import '../services/plant_image_service.dart';
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
    // تعديل حديقة موجودة: لا نعيد التحقق من الموقع.
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
    // منع الضغط المتكرر أثناء التحقق من الموقع.
    if (isCheckingLocation) return;
    setState(() => isCheckingLocation = true);
    try {
      // 1) الحصول على موقع الجهاز.
      final position = await LocationService.getCurrentLocation();
      if (!mounted) return;
      // 2) إرسال Latitude + Longitude إلى Geoapify.
      Map<String, dynamic> locationData;
      try {
        locationData = await GeoapifyService.getLocationDetails(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        if (!mounted) return;
        _showLocationMessage(
          'تعذر التحقق من موقعك حالياً. '
          'يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى.',
        );
        return;
      }
      if (!mounted) return;
      // 3) التحقق من أن الموقع ضمن منطقة الرياض ومحافظاتها.
      final city = (locationData['city'] ?? '').toString();
      final state = (locationData['state'] ?? '').toString();
      final formatted = (locationData['formatted'] ?? '').toString();
      final locationText = '$city $state $formatted'.toLowerCase();
      final isWithinRiyadh =
          locationText.contains('riyadh') ||
          locationText.contains('الرياض');
      if (!isWithinRiyadh) {
        _showLocationMessage(
          'رُوى متاح حالياً للحدائق الموجودة '
          'في منطقة الرياض ومحافظاتها فقط.',
        );
        return;
      }
      // 4) الموقع صحيح: فتح إعداد الحديقة وتمرير بيانات الموقع.
      final result = await Navigator.push<GardenProfile>(
        context,
        MaterialPageRoute(
          builder: (context) => SetupGardenScreen(
            latitude: position.latitude,
            longitude: position.longitude,
            city: locationData['city']?.toString(),
            state: locationData['state']?.toString(),
            country: locationData['country']?.toString(),
            formattedAddress: locationData['formatted']?.toString(),
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFAF9F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth;
            final height =
                constraints.maxHeight;
            final scaleX = width / 360;
            final scaleY = height / 800;
            return SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 24 * scaleX,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 38 * scaleY,
                  ),
                  Row(
                    textDirection:
                        TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.eco,
                        color: const Color(
                          0xFF315B32,
                        ),
                        size: 26 * scaleX,
                      ),
                      SizedBox(
                        width: 8 * scaleX,
                      ),
                      Text(
                        'حديقتي',
                        textDirection:
                            TextDirection.rtl,
                        style:
                            GoogleFonts.cairo(
                          color:
                              const Color(
                            0xFF234525,
                          ),
                          fontSize:
                              28 * scaleX,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 6 * scaleY,
                  ),
                  Text(
                    'كل ما تحتاجه لحديقتك في مكان واحد',
                    textDirection:
                        TextDirection.rtl,
                    textAlign:
                        TextAlign.right,
                    style:
                        GoogleFonts.cairo(
                      color: const Color(
                        0xFF7D8079,
                      ),
                      fontSize:
                          14 * scaleX,
                      fontWeight:
                          FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    height: 24 * scaleY,
                  ),
                  if (isLoading)
                    Padding(
                      padding:
                          EdgeInsets.only(
                        top: 60 * scaleY,
                      ),
                      child:
                          const Center(
                        child:
                            CircularProgressIndicator(
                          color: Color(
                            0xFF315B32,
                          ),
                        ),
                      ),
                    )
                  else if (garden == null)
                    _emptyState(
                      scaleX,
                      scaleY,
                    )
                  else ...[
                    _weatherPlaceholderCard(
                      scaleX,
                      scaleY,
                    ),
                    SizedBox(
                      height: 18 * scaleY,
                    ),
                    _gardenDataCard(
                      garden!,
                      scaleX,
                      scaleY,
                    ),
                    SizedBox(
                      height: 26 * scaleY,
                    ),
                    _myPlantsSection(
                      scaleX,
                      scaleY,
                    ),
                    SizedBox(
                      height: 26 * scaleY,
                    ),
                    _recommendedPlantsSection(
                      scaleX,
                      scaleY,
                    ),
                    SizedBox(
                      height: 30 * scaleY,
                    ),
                  ],
                ],
              ),
            );
          },
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
  Widget _weatherPlaceholderCard(
    double scaleX,
    double scaleY,
  ) {
    String temperature = '--°';
    String humidity = '--%';
    String windSpeed = '-- كم/س';
    String daylightHours = '-- س';
    String statusText = 'جاري تحميل بيانات الطقس...';
    if (!isLoadingWeather && weatherData != null) {
      final temp = weatherData!['temperature'] as double?;
      final humidityValue = weatherData!['humidity'] as int?;
      final wind = weatherData!['windSpeed'] as double?;
      final sunrise = weatherData!['sunrise'] as int?;
      final sunset = weatherData!['sunset'] as int?;
      final description = weatherData!['description']?.toString();
      if (temp != null) {
        temperature = '${temp.round()}°';
      }
      if (humidityValue != null) {
        humidity = '$humidityValue%';
      }
      if (wind != null) {
        final windKmh = wind * 3.6;
        windSpeed = '${windKmh.toStringAsFixed(1)} كم/س';
      }
      if (sunrise != null && sunset != null && sunset > sunrise) {
        final hours = (sunset - sunrise) / 3600;
        daylightHours = '${hours.toStringAsFixed(1)} س';
      }
      statusText = (description != null && description.isNotEmpty)
          ? description
          : 'تم تحديث بيانات الطقس';
    } else if (!isLoadingWeather && weatherError != null) {
      statusText = 'تعذر تحميل بيانات الطقس حالياً';
    }
    return Container(
      padding: EdgeInsets.all(18 * scaleX),
      decoration: BoxDecoration(
        color: const Color(0xFF315B32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الظروف الحالية في حديقتك',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 15 * scaleX,
                  fontWeight: FontWeight.w700,
                ),
              ),
              isLoadingWeather
                  ? SizedBox(
                      width: 18 * scaleX,
                      height: 18 * scaleX,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 20 * scaleX,
                    ),
            ],
          ),
          SizedBox(height: 4 * scaleY),
          Text(
            statusText,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12 * scaleX,
            ),
          ),
          SizedBox(height: 16 * scaleY),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weatherMetric(
                temperature,
                'حرارة',
                Icons.thermostat,
                scaleX,
              ),
              _weatherMetric(
                humidity,
                'رطوبة',
                Icons.water_drop,
                scaleX,
              ),
              _weatherMetric(
                windSpeed,
                'رياح',
                Icons.air,
                scaleX,
              ),
              _weatherMetric(
                daylightHours,
                'ساعات النهار',
                Icons.light_mode,
                scaleX,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _weatherMetric(
    String value,
    String label,
    IconData icon,
    double scaleX,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20 * scaleX,
          ),
          SizedBox(
            height: 6 * scaleX,
          ),
          SizedBox(
            height: 24 * scaleX,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14 * scaleX,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2 * scaleX,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10 * scaleX,
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // بطاقة بيانات الحديقة
  // ============================================================
  Widget _gardenDataCard(
    GardenProfile g,
    double scaleX,
    double scaleY,
  ) {
    return Container(
      padding:
          EdgeInsets.all(18 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFDCE4D8),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection:
                TextDirection.rtl,
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                'بيانات الحديقة',
                textDirection:
                    TextDirection.rtl,
                style:
                    GoogleFonts.cairo(
                  color:
                      const Color(
                    0xFF234525,
                  ),
                  fontSize:
                      16 * scaleX,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap:
                    _openSetupOrEdit,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal:
                        14 * scaleX,
                    vertical:
                        7 * scaleY,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE8F0E4,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Row(
                    textDirection:
                        TextDirection.rtl,
                    children: [
                      Icon(
                        Icons
                            .edit_outlined,
                        color:
                            const Color(
                          0xFF315B32,
                        ),
                        size:
                            14 * scaleX,
                      ),
                      SizedBox(
                        width:
                            4 * scaleX,
                      ),
                      Text(
                        'تعديل',
                        textDirection:
                            TextDirection
                                .rtl,
                        style:
                            GoogleFonts
                                .cairo(
                          color:
                              const Color(
                            0xFF315B32,
                          ),
                          fontSize:
                              12 *
                                  scaleX,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 18 * scaleY,
          ),
          Row(
            children: [
              _gardenDataColumn(
                Icons
                    .eco_outlined,
                'مستوى العناية',
                g.careLevel
                    .arabicLabel,
                null,
                scaleX,
              ),
              _gardenDataColumn(
                Icons
                    .water_drop_outlined,
                'مستوى الري',
                g.wateringLevel
                        ?.arabicLabel ??
                    'غير محدد',
                null,
                scaleX,
              ),
              _gardenDataColumn(
                Icons
                    .square_foot_outlined,
                'مساحة الزراعة',
                '${_fmt(g.lengthMeters * g.widthMeters)} م²',
                null,
                scaleX,
              ),
              _gardenDataColumn(
                Icons
                    .explore_outlined,
                'اتجاه الواجهة',
                g.facadeDirection
                    .arabicLabel,
                null,
                scaleX,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _gardenDataColumn(
    IconData icon,
    String label,
    String value,
    String? areaValue,
    double scaleX,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44 * scaleX,
            height: 44 * scaleX,
            decoration:
                BoxDecoration(
              color: const Color(
                0xFFE8F0E4,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(
                0xFF315B32,
              ),
              size: 22 * scaleX,
            ),
          ),
          SizedBox(
            height: 8 * scaleX,
          ),
          Text(
            value,
            textAlign:
                TextAlign.center,
            textDirection:
                TextDirection.rtl,
            style:
                GoogleFonts.cairo(
              color: const Color(
                0xFF292D28,
              ),
              fontSize:
                  13 * scaleX,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          if (areaValue != null)
            Text(
              areaValue,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                color: const Color(0xFF315B32),
                fontSize: 12 * scaleX,
                fontWeight: FontWeight.w700,
              ),
            ),
          SizedBox(
            height: 2 * scaleX,
          ),
          Text(
            label,
            textAlign:
                TextAlign.center,
            textDirection:
                TextDirection.rtl,
            style:
                GoogleFonts.cairo(
              color: const Color(
                0xFF7D8079,
              ),
              fontSize:
                  10.5 * scaleX,
            ),
          ),
        ],
      ),
    );
  }
  String _fmt(double value) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }
    return value.toString();
  }
  // قسم نباتاتي - عرض فعلي لحالة القائمة المحفوظة.
  Widget _myPlantsSection(double scaleX, double scaleY) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _previewHeader('نباتاتي', () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MyPlantsScreen()));
        if (mounted) setState(_loadPreviews);
      }),
      SizedBox(height: 12 * scaleY),
      FutureBuilder<List<Plant>>(
        future: _savedPreview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF315B32)));
          }
          if (snapshot.hasError) return _previewMessage('تعذر تحميل النباتات المحفوظة.');
          final plants = snapshot.data ?? [];
          if (plants.isEmpty) return _previewMessage('لا توجد نباتات محفوظة بعد');
          return SizedBox(
            height: 212,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length > 3 ? 3 : plants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _smallPlantCard(plants[index]),
              ),
            ),
          );
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
      SizedBox(height: 12 * scaleY),
      FutureBuilder<RecommendationResults>(
        future: _recommendationPreview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF315B32)));
          }
          if (snapshot.hasError) return _previewMessage('تعذر تحميل النباتات الموصى بها حاليًا.');
          final results = snapshot.data!;
          final items = [...results.tolerantPlants, ...results.sensitivePlants]
            ..sort((a,b) => b.score.compareTo(a.score));
          if (items.isEmpty) return _previewMessage('لا توجد نباتات موصى بها لك حاليًا');
          return SizedBox(
            height: 261,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length > 3 ? 3 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context,index) {
                final item=items[index];
                final sensitive=results.sensitivePlants.any((r)=>r.plant.id==item.plant.id);
                return _smallPlantCard(item.plant, score:item.score, sensitive:sensitive);
              },
              ),
            ),
          );
        },
      ),
    ]);
  }

  Widget _previewHeader(String title, VoidCallback onTap) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: const Color(0xFF234525),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
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
                  Text('عرض الكل', style: GoogleFonts.cairo(
                    color: const Color(0xFF315B32),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF315B32), size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewMessage(String message) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),
      border:Border.all(color:const Color(0xFFDCE4D8))),
    child:Text(message,textAlign:TextAlign.center,style:GoogleFonts.cairo(color:const Color(0xFF555A52))),
  );

  // بطاقة معاينة مضغوطة، بهامش للصورة ومن دون Spacer يسبب فراغات كبيرة.
  Widget _smallPlantCard(Plant plant, {double? score, bool sensitive = false}) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantDetailsScreen(plant: plant)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE4D8)),
        ),
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
                  child: FutureBuilder<String?>(
                    future: PlantImageService.instance.imageFor(plant.scientificName),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      if (url != null && url.isNotEmpty) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _emptyPlantImage(),
                        );
                      }
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF315B32),
                          ),
                        );
                      }
                      return _emptyPlantImage();
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 7, 3),
              child: Text(
                plant.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF234525),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (score != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
                  decoration: BoxDecoration(
                    color: sensitive ? const Color(0xFFF8ECDD) : const Color(0xFFE4EFE0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sensitive ? 'حساس' : 'مقاوم',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sensitive ? const Color(0xFF9A6A32) : const Color(0xFF315B32),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 2),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF315B32),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        color: sensitive ? const Color(0xFF9A6A32) : const Color(0xFF315B32),
                        backgroundColor: const Color(0xFFE8F0E4),
                      ),
                    ),
                  ],
                ),
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
                child: Text(
                  'عرض التفاصيل',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF315B32),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPlantImage()=>Container(color:const Color(0xFFE8F0E4),
    child:const Icon(Icons.local_florist_outlined,color:Color(0xFF315B32),size:32));
}
