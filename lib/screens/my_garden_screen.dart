import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/garden_profile.dart';
import '../services/garden_service.dart';
import '../services/plant_service.dart';
import '../models/plant.dart';
import 'setup_garden_screen.dart';

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  GardenProfile? garden;
  bool isLoading = true;

  List<Plant> recommendedPlants = [];
  bool isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadGarden();
  }

  Future<void> _loadGarden() async {
    setState(() => isLoading = true);
    final result = await GardenService.instance.getGarden();
    if (!mounted) return;
    setState(() {
      garden = result;
      isLoading = false;
    });

    if (result != null) {
      _loadRecommendations(result);
    }
  }

  Future<void> _loadRecommendations(GardenProfile g) async {
    setState(() => isLoadingRecommendations = true);
    final result = await PlantService.instance.recommendForGarden(g);
    if (!mounted) return;
    setState(() {
      recommendedPlants = result;
      isLoadingRecommendations = false;
    });
  }

  Future<void> _openSetupOrEdit() async {
    final result = await Navigator.push<GardenProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupGardenScreen(existingGarden: garden),
      ),
    );

    if (result != null) {
      setState(() => garden = result);
      _loadRecommendations(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scaleX = width / 360;
            final scaleY = height / 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24 * scaleX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 38 * scaleY),

                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.eco,
                        color: const Color(0xFF315B32),
                        size: 26 * scaleX,
                      ),
                      SizedBox(width: 8 * scaleX),
                      Text(
                        'حديقتي',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF234525),
                          fontSize: 28 * scaleX,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6 * scaleY),

                  Text(
                    'كل ما تحتاجه لحديقتك في مكان واحد',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF7D8079),
                      fontSize: 14 * scaleX,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 24 * scaleY),

                  if (isLoading)
                    Padding(
                      padding: EdgeInsets.only(top: 60 * scaleY),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF315B32),
                        ),
                      ),
                    )
                  else if (garden == null)
                    _emptyState(scaleX, scaleY)
                  else ...[
                    _weatherPlaceholderCard(scaleX, scaleY),
                    SizedBox(height: 18 * scaleY),
                    _gardenDataCard(garden!, scaleX, scaleY),
                    SizedBox(height: 26 * scaleY),
                    _myPlantsSection(scaleX, scaleY),
                    SizedBox(height: 26 * scaleY),
                    _recommendedPlantsSection(scaleX, scaleY),
                    SizedBox(height: 30 * scaleY),
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
  // الحالة الفاضية (قبل إعداد الحديقة)
  // ============================================================
  Widget _emptyState(double scaleX, double scaleY) {
    return Column(
      children: [
        SizedBox(height: 40 * scaleY),
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
            onPressed: _openSetupOrEdit,
            style: ButtonStyle(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor:
                  const WidgetStatePropertyAll(Color(0xFF315B32)),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            child: Text(
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
    );
  }

  // ============================================================
  // بطاقة الطقس (مكان محجوز فقط — صاحبتي بتربطها بـ API الطقس)
  // TODO(صاحبتي): استبدال الأرقام الثابتة ببيانات حقيقية من OpenWeather
  // ============================================================
  Widget _weatherPlaceholderCard(double scaleX, double scaleY) {
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
              Icon(Icons.wb_sunny_outlined,
                  color: Colors.white, size: 20 * scaleX),
            ],
          ),
          SizedBox(height: 4 * scaleY),
          Text(
            'قريباً — بانتظار ربط بيانات الطقس',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12 * scaleX,
            ),
          ),
          SizedBox(height: 16 * scaleY),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weatherMetric('--°', 'حرارة', Icons.thermostat, scaleX),
              _weatherMetric('--%', 'رطوبة', Icons.water_drop, scaleX),
              _weatherMetric('-- كم/س', 'رياح', Icons.air, scaleX),
              _weatherMetric('-- ساعات', 'ضوء الشمس', Icons.light_mode,
                  scaleX),
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
          Icon(icon, color: Colors.white, size: 20 * scaleX),
          SizedBox(height: 6 * scaleX),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14 * scaleX,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2 * scaleX),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11 * scaleX,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة بيانات الحديقة (نفس بيانات GardenProfile الحالية، بتصميم جديد)
  // ============================================================
  Widget _gardenDataCard(GardenProfile g, double scaleX, double scaleY) {
    return Container(
      padding: EdgeInsets.all(18 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4D8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بيانات الحديقة',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF234525),
                  fontSize: 16 * scaleX,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: _openSetupOrEdit,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scaleX,
                    vertical: 7 * scaleY,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0E4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: const Color(0xFF315B32), size: 14 * scaleX),
                      SizedBox(width: 4 * scaleX),
                      Text(
                        'تعديل',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF315B32),
                          fontSize: 12 * scaleX,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * scaleY),
          Row(
            children: [
              _gardenDataColumn(
                Icons.water_drop_outlined,
                'مستوى العناية',
                g.careLevel.arabicLabel,
                scaleX,
              ),
              _gardenDataColumn(
                Icons.square_foot_outlined,
                'أبعاد مساحة الزراعة',
                '${_fmt(g.widthMeters)}×${_fmt(g.lengthMeters)} م',
                scaleX,
              ),
              _gardenDataColumn(
                Icons.explore_outlined,
                'اتجاه الواجهة',
                g.facadeDirection.arabicLabel,
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
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF315B32),
              size: 22 * scaleX,
            ),
          ),
          SizedBox(height: 8 * scaleX),
          Text(
            value,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: const Color(0xFF292D28),
              fontSize: 13 * scaleX,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2 * scaleX),
          Text(
            label,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: const Color(0xFF7D8079),
              fontSize: 10.5 * scaleX,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  // ============================================================
  // قسم "نباتاتي" — لا يوجد بعد نظام لحفظ النباتات، لذا نعرض حالة فاضية
  // TODO: استبدال هذا بقائمة حقيقية بعد إضافة ميزة "حفظ نبتة"
  // ============================================================
  Widget _myPlantsSection(double scaleX, double scaleY) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نباتاتي',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: const Color(0xFF234525),
            fontSize: 17 * scaleX,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12 * scaleY),
        Container(
          padding: EdgeInsets.all(16 * scaleX),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE4D8), width: 1.2),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.local_florist_outlined,
                  color: const Color(0xFF6F8F64), size: 26 * scaleX),
              SizedBox(width: 12 * scaleX),
              Expanded(
                child: Text(
                  'ماعندك نباتات محفوظة بعد',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF7D8079),
                    fontSize: 13 * scaleX,
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
  // قسم "نباتات موصى بها لك" — بيانات حقيقية من الداتاسيت + فلترة مبسطة
  // ============================================================
  Widget _recommendedPlantsSection(double scaleX, double scaleY) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نباتات موصى بها لك',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: const Color(0xFF234525),
            fontSize: 17 * scaleX,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12 * scaleY),
        if (isLoadingRecommendations)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Color(0xFF315B32)),
            ),
          )
        else
          SizedBox(
            height: 150 * scaleY,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: recommendedPlants.length,
              itemBuilder: (context, index) {
                final plant = recommendedPlants[index];
                return Padding(
                  padding: EdgeInsets.only(left: 12 * scaleX),
                  child: _plantCard(plant, scaleX),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _plantCard(Plant plant, double scaleX) {
    return Container(
      width: 140 * scaleX,
      padding: EdgeInsets.all(14 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4D8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36 * scaleX,
            height: 36 * scaleX,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.eco_outlined,
              color: const Color(0xFF315B32),
              size: 20 * scaleX,
            ),
          ),
          SizedBox(height: 10 * scaleX),
          Text(
            plant.arabicName,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: const Color(0xFF292D28),
              fontSize: 13 * scaleX,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scaleX),
          Text(
            plant.shortHint,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: const Color(0xFF7D8079),
              fontSize: 11 * scaleX,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}