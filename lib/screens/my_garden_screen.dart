import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/garden_profile.dart';
import '../models/plant.dart';
import '../services/garden_service.dart';
import '../services/plant_service.dart';
import '../services/location_service.dart';
import '../services/geoapify_service.dart';
import '../services/weather_service.dart';
import 'setup_garden_screen.dart';
class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});
  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}
class _MyGardenScreenState extends State<MyGardenScreen> {
  GardenProfile? garden;
  bool isLoading = true;
  bool isCheckingLocation = false;
  List<Plant> recommendedPlants = [];
  bool isLoadingRecommendations = false;

  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = false;
  String? weatherError;
  @override
  void initState() {
    super.initState();
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
      _loadRecommendations(result);
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
        weatherData = result;
        weatherError = null;
      });
    } catch (e) {
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
  // تحميل النباتات الموصى بها
  // ============================================================
  Future<void> _loadRecommendations(
    GardenProfile g,
  ) async {
    setState(
      () => isLoadingRecommendations = true,
    );
    final result =
        await PlantService.instance.recommendForGarden(g);
    if (!mounted) return;
    setState(() {
      recommendedPlants = result;
      isLoadingRecommendations = false;
    });
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
        _loadRecommendations(result);
        _loadWeather(result);
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
        _loadRecommendations(result);
        _loadWeather(result);
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
              'ما أعددتي بيانات حديقتك بعد',
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
              'أضيفي اتجاه الواجهة ومساحة الزراعة لتحصلي على توصيات مناسبة',
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
                    .water_drop_outlined,
                'مستوى العناية',
                g.careLevel
                    .arabicLabel,
                scaleX,
              ),
              _gardenDataColumn(
                Icons
                    .square_foot_outlined,
                'أبعاد مساحة الزراعة',
                '${_fmt(g.widthMeters)}×${_fmt(g.lengthMeters)} م',
                scaleX,
              ),
              _gardenDataColumn(
                Icons
                    .explore_outlined,
                'اتجاه الواجهة',
                g.facadeDirection
                    .arabicLabel,
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
  // ============================================================
  // قسم نباتاتي
  // ============================================================
  Widget _myPlantsSection(
    double scaleX,
    double scaleY,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Text(
          'نباتاتي',
          textDirection:
              TextDirection.rtl,
          textAlign:
              TextAlign.right,
          style: GoogleFonts.cairo(
            color:
                const Color(0xFF234525),
            fontSize: 17 * scaleX,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        SizedBox(
          height: 12 * scaleY,
        ),
        Container(
          padding:
              EdgeInsets.all(
            16 * scaleX,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: const Color(
                0xFFDCE4D8,
              ),
              width: 1.2,
            ),
          ),
          child: Row(
            textDirection:
                TextDirection.rtl,
            children: [
              Icon(
                Icons
                    .local_florist_outlined,
                color: const Color(
                  0xFF6F8F64,
                ),
                size: 26 * scaleX,
              ),
              SizedBox(
                width: 12 * scaleX,
              ),
              Expanded(
                child: Text(
                  'ماعندك نباتات محفوظة بعد',
                  textDirection:
                      TextDirection.rtl,
                  textAlign:
                      TextAlign.right,
                  style:
                      GoogleFonts.cairo(
                    color:
                        const Color(
                      0xFF7D8079,
                    ),
                    fontSize:
                        13 * scaleX,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // ============================================================
  // النباتات الموصى بها
  // ============================================================
  Widget _recommendedPlantsSection(
    double scaleX,
    double scaleY,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Text(
          'نباتات موصى بها لك',
          textDirection:
              TextDirection.rtl,
          textAlign:
              TextAlign.right,
          style: GoogleFonts.cairo(
            color:
                const Color(0xFF234525),
            fontSize: 17 * scaleX,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        SizedBox(
          height: 12 * scaleY,
        ),
        if (isLoadingRecommendations)
          const Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 20,
              ),
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF315B32),
              ),
            ),
          )
        else
          SizedBox(
            height: 180 * scaleY,
            child:
                ListView.builder(
              scrollDirection:
                  Axis.horizontal,
              reverse: true,
              itemCount:
                  recommendedPlants
                      .length,
              itemBuilder:
                  (context, index) {
                final plant =
                    recommendedPlants[
                        index];
                return Padding(
                  padding:
                      EdgeInsets.only(
                    left:
                        12 * scaleX,
                  ),
                  child: _plantCard(
                    plant,
                    scaleX,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  Widget _plantCard(
    Plant plant,
    double scaleX,
  ) {
    return Container(
      width: 140 * scaleX,
      padding:
          EdgeInsets.all(14 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFDCE4D8),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Container(
            width: 36 * scaleX,
            height: 36 * scaleX,
            decoration:
                BoxDecoration(
              color: const Color(
                0xFFE8F0E4,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              Icons.eco_outlined,
              color: const Color(
                0xFF315B32,
              ),
              size: 20 * scaleX,
            ),
          ),
          SizedBox(
            height: 10 * scaleX,
          ),
          Text(
            plant.arabicName,
            textDirection:
                TextDirection.rtl,
            textAlign:
                TextAlign.right,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
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
          SizedBox(
            height: 4 * scaleX,
          ),
          Text(
            plant.shortHint,
            textDirection:
                TextDirection.rtl,
            textAlign:
                TextAlign.right,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                GoogleFonts.cairo(
              color: const Color(
                0xFF7D8079,
              ),
              fontSize:
                  11 * scaleX,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
