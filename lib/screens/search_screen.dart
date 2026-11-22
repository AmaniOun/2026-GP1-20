import '../widgets/ruwa_saved_badge.dart';
import '../widgets/ruwa_plant_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/plant_service.dart';
import '../utils/plant_display_formatter.dart';
import 'plant_details_screen.dart';

/// Arabic-first plant catalogue. Search/filter behavior remains in PlantService.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _green = Color(0xFF315B32);
  static const _dark = Color(0xFF234525);
  static const _bg = Color(0xFFFAF9F4);
  static const _light = Color(0xFFE8F0E4);
  static const _border = Color(0xFFDCE4D8);
  static const _muted = Color(0xFF596A59);

  final TextEditingController _searchController = TextEditingController();
  List<Plant> _allPlants = const [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _water;
  String? _tolerance;
  String? _care;

  static const Map<String, String> _waterOptions = {
    'Low': 'ري منخفض',
    'Moderate': 'ري متوسط',
    'High': 'ري مرتفع',
  };
  static const Map<String, String> _toleranceOptions = {
    'Tolerant': 'مقاوم',
    'Sensitive': 'حساس',
  };
  static const Map<String, String> _careOptions = {
    'Low': 'عناية قليلة',
    'Moderate': 'عناية متوسطة',
    'High': 'عناية عالية',
  };

  bool get _hasFilters => _water != null || _tolerance != null || _care != null;
  int get _filterCount => [_water, _tolerance, _care].where((v) => v != null).length;

  List<Plant> get _results => PlantService.instance.filter(
        PlantService.instance.search(_allPlants, _query),
        water: _water,
        tolerance: _tolerance,
        care: _care,
      );

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plants = await PlantService.instance.loadPlants();
      if (!mounted) return;
      setState(() {
        _allPlants = plants;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SEARCH PLANTS LOAD ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل النباتات حاليًا. يرجى المحاولة مرة أخرى.';
        _loading = false;
      });
    }
  }

  void _resetFilters() => setState(() {
        _water = null;
        _tolerance = null;
        _care = null;
      });

  TextStyle _style(double size,
          {FontWeight weight = FontWeight.w500, Color color = _dark}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: 1.45);

  void _openPlant(Plant plant) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlantDetailsScreen(plant: plant)),
      );

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('استكشف النباتات', style: _style(25, weight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('ابحث عن نبات باسمه العربي أو العلمي، واكتشف احتياجاته.',
                          style: _style(14, color: _muted)),
                      const SizedBox(height: 20),
                      _searchField(),
                      const SizedBox(height: 14),
                      _filterToolbar(),
                      if (_hasFilters) ...[
                        const SizedBox(height: 12),
                        _activeFilters(),
                      ],
                      const SizedBox(height: 19),
                      if (!_loading && _error == null && _allPlants.isNotEmpty)
                        Row(children: [
                          Text('النباتات', style: _style(18, weight: FontWeight.w800)),
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                            decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(30)),
                            child: Text('${results.length}', style: _style(13, weight: FontWeight.w700)),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: _green)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _stateMessage(Icons.cloud_off_outlined, _error!,
                      action: 'إعادة المحاولة', onTap: _loadPlants),
                )
              else if (results.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _stateMessage(
                    Icons.search_off_rounded,
                    _allPlants.isEmpty
                        ? 'لا توجد نباتات متاحة حاليًا.'
                        : _hasFilters
                            ? 'لا توجد نباتات تطابق الفلاتر المحددة.'
                            : 'لا توجد نتائج مطابقة لبحثك.',
                    action: _hasFilters ? 'مسح الفلاتر' : null,
                    onTap: _hasFilters ? _resetFilters : null,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
                  sliver: SliverList.builder(
                    itemCount: results.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _plantTile(results[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() => TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value),
        style: _style(15),
        decoration: InputDecoration(
          hintText: 'ابحث باسم النبات...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: _style(14, color: _muted),
          prefixIcon: const Icon(Icons.search_rounded, color: _green, size: 24),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded, color: _muted),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _green, width: 1.8),
          ),
        ),
      );

  Widget _filterToolbar() => Row(
        children: [
          Material(
            color: _hasFilters ? _green : _light,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _openFilterSheet,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tune_rounded, size: 20,
                        color: _hasFilters ? Colors.white : _green),
                    const SizedBox(width: 8),
                    Text('تصفية النتائج',
                        style: _style(14, weight: FontWeight.w700,
                            color: _hasFilters ? Colors.white : _dark)),
                    if (_hasFilters) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white,
                        child: Text('$_filterCount', style: _style(12, weight: FontWeight.w800, color: _green)),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_hasFilters)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text('إعادة تعيين', style: _style(14, weight: FontWeight.w700, color: _green)),
              style: TextButton.styleFrom(foregroundColor: _green, minimumSize: const Size(48, 48)),
            ),
        ],
      );

  Widget _activeFilters() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          if (_water != null)
            _activeChip(_waterOptions[_water]!, () => setState(() => _water = null)),
          if (_tolerance != null)
            _activeChip(_toleranceOptions[_tolerance]!, () => setState(() => _tolerance = null)),
          if (_care != null)
            _activeChip(_careOptions[_care]!, () => setState(() => _care = null)),
        ]),
      );

  Widget _activeChip(String label, VoidCallback remove) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Material(
          color: _light,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: remove,
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: _style(13, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  const Icon(Icons.close_rounded, size: 18, color: _green),
                ]),
              ),
            ),
          ),
        ),
      );

  Future<void> _openFilterSheet() async {
    String? water = _water;
    String? tolerance = _tolerance;
    String? care = _care;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 5,
                      decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: Text('تصفية النتائج', style: _style(21, weight: FontWeight.w800))),
                    IconButton(tooltip: 'إغلاق', onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, color: _dark)),
                  ]),
                  const SizedBox(height: 15),
                  _filterGroup('احتياج الماء', _waterOptions, water,
                      (value) => updateSheet(() => water = value)),
                  _filterGroup('تحمّل المناخ', _toleranceOptions, tolerance,
                      (value) => updateSheet(() => tolerance = value)),
                  _filterGroup('مستوى العناية', _careOptions, care,
                      (value) => updateSheet(() => care = value)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(flex: 2, child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _water = water;
                          _tolerance = tolerance;
                          _care = care;
                        });
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white,
                        elevation: 0, minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('تطبيق الفلاتر', style: _style(15, weight: FontWeight.w800, color: Colors.white)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(
                      onPressed: () => updateSheet(() {
                        water = null;
                        tolerance = null;
                        care = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green, side: const BorderSide(color: _border),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('مسح', style: _style(14, weight: FontWeight.w700)),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterGroup(String title, Map<String, String> options,
      String? selected, ValueChanged<String?> onSelect) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _style(16, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: options.entries.map((entry) {
            final chosen = selected == entry.key;
            return Material(
              color: chosen ? _green : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: chosen ? _green : _border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onSelect(chosen ? null : entry.key),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 46),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                    child: Text(entry.value, style: _style(14, weight: FontWeight.w700,
                        color: chosen ? Colors.white : _dark)),
                  ),
                ),
              ),
            );
          }).toList()),
        ]),
      );

  Widget _stateMessage(IconData icon, String message, {String? action, VoidCallback? onTap}) =>
      Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 66, height: 66,
            decoration: const BoxDecoration(color: _light, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: _green),
          ),
          const SizedBox(height: 13),
          Text(message, textAlign: TextAlign.center, style: _style(15, color: _muted)),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onTap,
                child: Text(action, style: _style(14, weight: FontWeight.w700, color: _green))),
          ],
        ]),
      ));

  Widget _tag(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: _green),
          const SizedBox(width: 4),
          Text(text, style: _style(12, weight: FontWeight.w600)),
        ]),
      );

  // Temperature tolerance uses the same green/orange visual language
  // as the recommendations screen. Unknown classification remains neutral.
  Widget _temperatureTag(String? toleranceClass) {
    final isSensitive = toleranceClass?.trim().toLowerCase() == 'sensitive';
    final color = isSensitive ? const Color(0xFF98691F) : _green;
    final background = isSensitive
        ? const Color(0xFFFFF0D7)
        : const Color(0xFFF0F4ED);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thermostat_outlined, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            PlantDisplayFormatter.toleranceTag(toleranceClass),
            style: _style(12, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _plantTile(Plant plant) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 112,
                      height: 127,
                      child: _plantImage(plant),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _style(16, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plant.scientificName,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            color: _muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: RuwaSavedBadge(plantId: plant.id),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 5,
                          runSpacing: 6,
                          children: [
                            _tag(
                              Icons.water_drop_outlined,
                              PlantDisplayFormatter.waterTag(
                                plant.wateringRequirement,
                              ),
                            ),
                            _tag(
                              Icons.spa_outlined,
                              PlantDisplayFormatter.careTag(plant.careLevel),
                            ),
                            _temperatureTag(plant.climateToleranceClass),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              // Full card-width action below both the photo and information.
              // Only this button opens details; the card itself is not tappable.
              Material(
                color: _light,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openPlant(plant),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Center(
                      child: Text(
                        'عرض التفاصيل',
                        style: _style(
                          14,
                          weight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _plantImage(Plant plant) =>
      RuwaPlantImage(scientificName: plant.scientificName);
}
