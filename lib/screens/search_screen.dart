import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/knn_classifier.dart';

// ==========================================
// شاشة البحث عن النباتات
//
// - البحث بالاسم (عربي أو علمي) داخل قاعدة بيانات روى (90 نبتة)
// - لو النبتة غير موجودة: نموذج لإدخال خصائصها، ويتوقع KNN
//   فئة تحملها للمناخ (Highly / Moderately / Poorly Tolerant)
// ==========================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();
  final heightController = TextEditingController();
  final spreadController = TextEditingController();
  final minTempController = TextEditingController();

  List<Plant> allPlants = [];
  bool isLoading = true;
  String query = '';

  String? selectedWatering; // Low / Medium / High
  String? selectedLight; // Shade / Partial Sun / Full Sun
  String? predictedClass;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    searchController.dispose();
    heightController.dispose();
    spreadController.dispose();
    minTempController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    final plants = await PlantService.instance.loadPlants();
    if (!mounted) return;
    setState(() {
      allPlants = plants;
      isLoading = false;
    });
  }

  List<Plant> get results {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allPlants;
    return allPlants.where((p) {
      return p.arabicName.toLowerCase().contains(q) ||
          p.scientificName.toLowerCase().contains(q);
    }).toList();
  }

  String _classLabel(String englishClass) {
    switch (englishClass) {
      case 'Highly Tolerant':
        return 'عالية التحمل';
      case 'Moderately Tolerant':
        return 'متوسطة التحمل';
      case 'Poorly Tolerant':
        return 'ضعيفة التحمل';
      default:
        return englishClass;
    }
  }

  void _showMessage(String message) {
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
      ),
    );
  }

  void _classify() {
    if (selectedWatering == null || selectedLight == null) {
      _showMessage('يرجى تحديد مستوى الري ومستوى الضوء');
      return;
    }

    final height = double.tryParse(heightController.text.trim());
    final spread = double.tryParse(spreadController.text.trim());
    final minTemp = double.tryParse(minTempController.text.trim());

    if (height == null || spread == null || minTemp == null) {
      _showMessage('يرجى إدخال قيم رقمية صحيحة للطول والانتشار وأقل حرارة');
      return;
    }
    if (height <= 0 || spread <= 0) {
      _showMessage('يجب أن يكون الطول والانتشار أكبر من صفر');
      return;
    }
    if (minTemp < -50 || minTemp > 50) {
      _showMessage('قيمة أقل حرارة يجب أن تكون بين -50 و 50 درجة مئوية');
      return;
    }

    final classifier = KnnClassifier(allPlants);
    final result = classifier.classify(
      NewPlantFeatures(
        arabicName: query.trim(),
        scientificName: '',
        wateringRequirement: selectedWatering!,
        lightRequirement: selectedLight!,
        matureHeight: height,
        matureSpread: spread,
        minTempTolerance: minTemp,
      ),
      k: 5,
    );

    setState(() => predictedClass = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / 360;
            final scaleY = constraints.maxHeight / 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24 * scaleX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 38 * scaleY),
                  Text(
                    'البحث',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF234525),
                      fontSize: 28 * scaleX,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6 * scaleY),
                  Text(
                    'ابحثي عن نبتة بالاسم العربي أو العلمي',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF7D8079),
                      fontSize: 14 * scaleX,
                    ),
                  ),
                  SizedBox(height: 20 * scaleY),
                  _searchField(scaleX, scaleY),
                  SizedBox(height: 20 * scaleY),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF315B32),
                      ),
                    )
                  else if (results.isEmpty)
                    _notFoundSection(scaleX, scaleY)
                  else
                    ...results.map((p) => _plantTile(p, scaleX)),
                  SizedBox(height: 30 * scaleY),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _searchField(double scaleX, double scaleY) {
    return SizedBox(
      height: 52 * scaleY,
      child: TextField(
        controller: searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (value) => setState(() {
          query = value;
          predictedClass = null;
        }),
        style: GoogleFonts.cairo(
          color: const Color(0xFF234525),
          fontSize: 14 * scaleX,
        ),
        decoration: InputDecoration(
          hintText: 'اسم النبتة...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF8A8D87),
            fontSize: 13 * scaleX,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF315B32)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16 * scaleX),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4D8), width: 1.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF315B32), width: 1.7),
          ),
        ),
      ),
    );
  }

  Widget _plantTile(Plant plant, double scaleX) {
    return Container(
      margin: EdgeInsets.only(bottom: 10 * scaleX),
      padding: EdgeInsets.all(14 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE4D8), width: 1.2),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40 * scaleX,
            height: 40 * scaleX,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.eco_outlined,
              color: const Color(0xFF315B32),
              size: 22 * scaleX,
            ),
          ),
          SizedBox(width: 12 * scaleX),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plant.arabicName,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF292D28),
                    fontSize: 14 * scaleX,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  plant.scientificName,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF7D8079),
                    fontSize: 11 * scaleX,
                  ),
                ),
                Text(
                  _classLabel(plant.climateToleranceClass),
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF315B32),
                    fontSize: 11.5 * scaleX,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // لو النبتة غير موجودة بقاعدة روى: نموذج التصنيف بـ KNN
  // ============================================================
  Widget _notFoundSection(double scaleX, double scaleY) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'هذه النبتة غير موجودة في قاعدة بيانات روى',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: const Color(0xFF234525),
            fontSize: 15 * scaleX,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4 * scaleY),
        Text(
          'أدخلي خصائصها ونتوقع فئة تحملها للمناخ باستخدام KNN',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: const Color(0xFF7D8079),
            fontSize: 12.5 * scaleX,
          ),
        ),
        SizedBox(height: 18 * scaleY),
        _label('مستوى الري', scaleX),
        SizedBox(height: 8 * scaleY),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10 * scaleX,
          runSpacing: 8 * scaleY,
          children: [
            _chip('قليل', 'Low', selectedWatering, scaleX,
                (v) => setState(() => selectedWatering = v)),
            _chip('متوسط', 'Medium', selectedWatering, scaleX,
                (v) => setState(() => selectedWatering = v)),
            _chip('عالي', 'High', selectedWatering, scaleX,
                (v) => setState(() => selectedWatering = v)),
          ],
        ),
        SizedBox(height: 16 * scaleY),
        _label('مستوى الضوء', scaleX),
        SizedBox(height: 8 * scaleY),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10 * scaleX,
          runSpacing: 8 * scaleY,
          children: [
            _chip('ظل', 'Shade', selectedLight, scaleX,
                (v) => setState(() => selectedLight = v)),
            _chip('شمس جزئية', 'Partial Sun', selectedLight, scaleX,
                (v) => setState(() => selectedLight = v)),
            _chip('شمس كاملة', 'Full Sun', selectedLight, scaleX,
                (v) => setState(() => selectedLight = v)),
          ],
        ),
        SizedBox(height: 16 * scaleY),
        _numberField(heightController, 'الطول عند النضج (م)', scaleX, scaleY),
        SizedBox(height: 10 * scaleY),
        _numberField(spreadController, 'الانتشار عند النضج (م)', scaleX, scaleY),
        SizedBox(height: 10 * scaleY),
        _numberField(
            minTempController, 'أقل حرارة تتحملها (°م)', scaleX, scaleY,
            signed: true),
        SizedBox(height: 20 * scaleY),
        SizedBox(
          height: 50 * scaleY,
          child: ElevatedButton(
            onPressed: _classify,
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
              'صنّفي النبتة',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 15 * scaleX,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (predictedClass != null) ...[
          SizedBox(height: 18 * scaleY),
          Container(
            padding: EdgeInsets.all(16 * scaleX),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF315B32), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الفئة المتوقعة (KNN)',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF7D8079),
                    fontSize: 12 * scaleX,
                  ),
                ),
                SizedBox(height: 4 * scaleX),
                Text(
                  _classLabel(predictedClass!),
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF234525),
                    fontSize: 18 * scaleX,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text, double scaleX) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        color: const Color(0xFF292D28),
        fontSize: 14 * scaleX,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _chip(
    String label,
    String value,
    String? selectedValue,
    double scaleX,
    ValueChanged<String> onSelect,
  ) {
    final selected = selectedValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: 18 * scaleX,
          vertical: 10 * scaleX,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF315B32) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                selected ? const Color(0xFF315B32) : const Color(0xFFDCE4D8),
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(
            color: selected ? Colors.white : const Color(0xFF292D28),
            fontSize: 13 * scaleX,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String hint,
    double scaleX,
    double scaleY, {
    bool signed = false,
  }) {
    return SizedBox(
      height: 50 * scaleY,
      child: TextField(
        controller: controller,
        keyboardType:
            TextInputType.numberWithOptions(decimal: true, signed: signed),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          color: const Color(0xFF234525),
          fontSize: 13 * scaleX,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF8A8D87),
            fontSize: 13 * scaleX,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16 * scaleX),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4D8), width: 1.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF315B32), width: 1.7),
          ),
        ),
      ),
    );
  }
}