import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/plant_service.dart';

// ==========================================
// شاشة البحث عن النباتات
//
// - عرض النباتات الموجودة في قاعدة روى (PBI 8)
// - البحث بالاسم الكامل أو الجزئي، عربي أو علمي (PBI 9)
// - فلترة بالخصائص: الماء، تحمل المناخ، العناية (PBI 22)
// - رسائل: لا توجد نتائج / لا توجد نباتات تطابق الفلاتر
// ==========================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _green = Color(0xFF315B32);
  static const _darkGreen = Color(0xFF234525);
  static const _border = Color(0xFFDCE4D8);
  static const _grey = Color(0xFF7D8079);

  final _searchController = TextEditingController();

  List<Plant> _allPlants = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  // الفلاتر (null = بدون فلتر)
  String? _water; // Low / Moderate / High
  String? _tolerance; // High / Moderate / Low
  String? _care; // Low / Moderate / High

  bool get _hasFilters => _water != null || _tolerance != null || _care != null;

  int get _filterCount =>
      [_water, _tolerance, _care].where((e) => e != null).length;

  // خيارات الفلاتر (القيمة في الداتاسيت: النص العربي)
  static const _waterOptions = {
    'Low': 'ري منخفض',
    'Moderate': 'ري متوسط',
    'High': 'ري مرتفع',
  };
  static const _toleranceOptions = {
    'High': 'تحمل عالٍ',
    'Moderate': 'تحمل متوسط',
    'Low': 'تحمل ضعيف',
  };
  static const _careOptions = {
    'Low': 'عناية قليلة',
    'Moderate': 'عناية متوسطة',
    'High': 'عناية عالية',
  };

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await PlantService.instance.loadPlants();
      if (!mounted) return;
      setState(() {
        _allPlants = plants;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // البحث بالاسم ثم تطبيق الفلاتر (المنطق داخل PlantService)
  List<Plant> get _results {
    final service = PlantService.instance;
    final byName = service.search(_allPlants, _query);
    return service.filter(
      byName,
      water: _water,
      tolerance: _tolerance,
      care: _care,
    );
  }

  void _resetFilters() {
    setState(() {
      _water = null;
      _tolerance = null;
      _care = null;
    });
  }

  // ---------- نصوص عربية للقيم ----------
  String _waterLabel(String v) {
    switch (v) {
      case 'Low':
        return 'ري منخفض';
      case 'Moderate':
        return 'ري متوسط';
      case 'High':
        return 'ري مرتفع';
      default:
        return v;
    }
  }

  String _careLabel(String v) {
    switch (v) {
      case 'Low':
        return 'عناية قليلة';
      case 'Moderate':
        return 'عناية متوسطة';
      case 'High':
        return 'عناية عالية';
      default:
        return v;
    }
  }

  String _toleranceLabel(String? v) {
    switch (v) {
      case 'High':
        return 'تحمل عالٍ';
      case 'Moderate':
        return 'تحمل متوسط';
      case 'Low':
        return 'تحمل ضعيف';
      default:
        return 'غير مصنّفة';
    }
  }

  // ==========================================
  // البناء
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / 360;
            final scaleY = constraints.maxHeight / 800;
            final results = _results;

            Widget? message;
            if (_isLoading) {
              message = const Center(
                child: CircularProgressIndicator(color: _green),
              );
            } else if (_error != null) {
              message = _message('تعذر تحميل النباتات:\n$_error', scaleX);
            } else if (_allPlants.isEmpty) {
              message = _message('لا توجد نباتات متاحة حالياً', scaleX);
            } else if (results.isEmpty) {
              message = _message(
                _hasFilters
                    ? 'لا توجد نباتات تطابق الفلاتر المحددة'
                    : 'لا توجد نتائج مطابقة',
                scaleX,
              );
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scaleX),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _header(scaleX, scaleY, results.length),
                  ),
                  if (message != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: message!,
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _plantTile(results[i], scaleX),
                        childCount: results.length,
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 24 * scaleY)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(double scaleX, double scaleY, int count) {
    final showCount = !_isLoading && _error == null && _allPlants.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 30 * scaleY),
        Text(
          'البحث',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: _darkGreen,
            fontSize: 28 * scaleX,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4 * scaleY),
        Text(
          'ابحثي عن نبتة بالاسم العربي أو العلمي',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(color: _grey, fontSize: 14 * scaleX),
        ),
        SizedBox(height: 16 * scaleY),
        _searchField(scaleX, scaleY),
        SizedBox(height: 16 * scaleY),

        // زر تصفية النتائج (يفتح ورقة الفلاتر) + إعادة تعيين
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _openFilterSheet,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scaleX,
                  vertical: 8 * scaleX,
                ),
                decoration: BoxDecoration(
                  color: _hasFilters ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _hasFilters ? _green : _border,
                    width: 1.3,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18 * scaleX,
                      color: _hasFilters ? Colors.white : _darkGreen,
                    ),
                    SizedBox(width: 6 * scaleX),
                    Text(
                      'تصفية النتائج',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        color: _hasFilters ? Colors.white : _darkGreen,
                        fontSize: 13 * scaleX,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_hasFilters) ...[
                      SizedBox(width: 6 * scaleX),
                      Container(
                        width: 20 * scaleX,
                        height: 20 * scaleX,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_filterCount',
                          style: GoogleFonts.cairo(
                            color: _green,
                            fontSize: 11 * scaleX,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_hasFilters)
              GestureDetector(
                onTap: _resetFilters,
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18 * scaleX, color: _green),
                    SizedBox(width: 4 * scaleX),
                    Text(
                      'إعادة تعيين',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        color: _green,
                        fontSize: 13 * scaleX,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // الفلاتر المفعّلة (تُمسح بعلامة ×)
        if (_hasFilters) ...[
          SizedBox(height: 10 * scaleY),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_water != null)
                    _activeChip(_waterOptions[_water]!,
                        () => setState(() => _water = null), scaleX),
                  if (_tolerance != null)
                    _activeChip(_toleranceOptions[_tolerance]!,
                        () => setState(() => _tolerance = null), scaleX),
                  if (_care != null)
                    _activeChip(_careOptions[_care]!,
                        () => setState(() => _care = null), scaleX),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: 14 * scaleY),

        // عداد النتائج
        if (showCount)
          Padding(
            padding: EdgeInsets.only(bottom: 10 * scaleY),
            child: Text(
              '$count نتيجة',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                color: _grey,
                fontSize: 13 * scaleX,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchField(double scaleX, double scaleY) {
    return SizedBox(
      height: 52 * scaleY,
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (value) => setState(() => _query = value),
        style: GoogleFonts.cairo(color: _darkGreen, fontSize: 14 * scaleX),
        decoration: InputDecoration(
          hintText: 'اسم النبتة...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF8A8D87),
            fontSize: 13 * scaleX,
          ),
          prefixIcon: const Icon(Icons.search, color: _green),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16 * scaleX),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.7),
          ),
        ),
      ),
    );
  }

  // وسم الفلتر المفعّل مع علامة ×
  Widget _activeChip(String label, VoidCallback onRemove, double scaleX) {
    return Padding(
      padding: EdgeInsets.only(left: 8 * scaleX),
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scaleX,
            vertical: 5 * scaleX,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0E4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  color: _darkGreen,
                  fontSize: 11.5 * scaleX,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4 * scaleX),
              Icon(Icons.close_rounded, size: 14 * scaleX, color: _green),
            ],
          ),
        ),
      ),
    );
  }

  // ورقة الفلاتر (تطلع من تحت)
  void _openFilterSheet() {
    String? w = _water;
    String? t = _tolerance;
    String? c = _care;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF9F4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final scaleX = MediaQuery.of(context).size.width / 360;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20 * scaleX,
                    20 * scaleX,
                    20 * scaleX,
                    16 * scaleX,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصفية النتائج',
                        style: GoogleFonts.cairo(
                          color: _darkGreen,
                          fontSize: 20 * scaleX,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 14 * scaleX),
                      _sheetGroup(
                        'احتياج الماء',
                        _waterOptions,
                        w,
                        (v) => setSheet(() => w = v),
                        scaleX,
                      ),
                      _sheetGroup(
                        'تحمل المناخ',
                        _toleranceOptions,
                        t,
                        (v) => setSheet(() => t = v),
                        scaleX,
                      ),
                      _sheetGroup(
                        'مستوى العناية',
                        _careOptions,
                        c,
                        (v) => setSheet(() => c = v),
                        scaleX,
                      ),
                      SizedBox(height: 6 * scaleX),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _water = w;
                                  _tolerance = t;
                                  _care = c;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 14 * scaleX,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'تطبيق',
                                style: GoogleFonts.cairo(
                                  fontSize: 15 * scaleX,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scaleX),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setSheet(() {
                                w = null;
                                t = null;
                                c = null;
                              }),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _green,
                                side: const BorderSide(color: _border),
                                padding: EdgeInsets.symmetric(
                                  vertical: 14 * scaleX,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'إعادة تعيين',
                                style: GoogleFonts.cairo(
                                  fontSize: 13 * scaleX,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // مجموعة خيارات داخل الورقة (اضغطي على المختار مرة ثانية لإلغائه)
  Widget _sheetGroup(
    String title,
    Map<String, String> options,
    String? selected,
    ValueChanged<String?> onSelect,
    double scaleX,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scaleX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: const Color(0xFF292D28),
              fontSize: 14 * scaleX,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scaleX),
          Wrap(
            spacing: 8 * scaleX,
            runSpacing: 8 * scaleX,
            children: options.entries.map((e) {
              final isSelected = selected == e.key;
              return GestureDetector(
                onTap: () => onSelect(isSelected ? null : e.key),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scaleX,
                    vertical: 9 * scaleX,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? _green : _border,
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : const Color(0xFF292D28),
                      fontSize: 13 * scaleX,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _message(String text, double scaleX) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scaleX),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: _grey,
            fontSize: 15 * scaleX,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // وسم صغير داخل الكرت
  Widget _tag(IconData icon, String text, double scaleX) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scaleX,
        vertical: 4 * scaleX,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 13 * scaleX, color: _green),
          SizedBox(width: 3 * scaleX),
          Text(
            text,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              color: const Color(0xFF292D28),
              fontSize: 10.5 * scaleX,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plantTile(Plant plant, double scaleX) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scaleX),
      padding: EdgeInsets.all(12 * scaleX),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة بديلة (لما تتوفر الصور من Perenual تتبدل)
          Container(
            width: 76 * scaleX,
            height: 76 * scaleX,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.eco_outlined,
              color: _green,
              size: 34 * scaleX,
            ),
          ),
          SizedBox(width: 12 * scaleX),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plant.displayName,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF292D28),
                    fontSize: 15 * scaleX,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  plant.scientificName,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: _grey,
                    fontSize: 11.5 * scaleX,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8 * scaleX),
                // الوسوم في صف واحد، ولو ما كفى المكان تتحرك بالسحب أفقياً
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tag(Icons.water_drop_outlined,
                            _waterLabel(plant.wateringRequirement), scaleX),
                        SizedBox(width: 6 * scaleX),
                        _tag(Icons.spa_outlined, _careLabel(plant.careLevel),
                            scaleX),
                        SizedBox(width: 6 * scaleX),
                        _tag(Icons.thermostat_outlined,
                            _toleranceLabel(plant.climateToleranceClass),
                            scaleX),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}