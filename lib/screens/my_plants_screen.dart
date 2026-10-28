import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant.dart';
import '../services/my_plant_service.dart';
import '../services/plant_image_service.dart';
import '../utils/confirm_dialog.dart';
import 'plant_details_screen.dart';
import 'search_screen.dart';

// ==========================================
// صفحة "نباتاتي" (حسب التصميم):
// - رجوع (مثل صفحة تفاصيل النبات) + العنوان، وزر "إضافة نبات" أسفل الشاشة
// - بطاقة عدد النباتات
// - شبكة من عمودين: صورة + اسم + "عرض التفاصيل" (والسلة على الصورة للحذف)
// - قائمة ⋮ لكل نبتة (عرض التفاصيل / حذف مع تأكيد)
// ==========================================
class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  static const Color _background = Color(0xFFFAF9F4);
  static const Color _green = Color(0xFF315B32);
  static const Color _darkGreen = Color(0xFF234525);
  static const Color _sage = Color(0xFF6F8F64);
  static const Color _lightSage = Color(0xFFE8F0E4);
  static const Color _border = Color(0xFFDCE4D8);
  static const Color _grey = Color(0xFF7D8079);
  static const Color _textSecondary = Color(0xFF555A52);

  late Future<List<Plant>> _plantsFuture;

  @override
  void initState() {
    super.initState();
    _plantsFuture = MyPlantService.instance.getMyPlants();
  }

  void _reload() {
    setState(() {
      _plantsFuture = MyPlantService.instance.getMyPlants();
    });
  }

  Future<void> _openDetails(Plant plant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlantDetailsScreen(plant: plant)),
    );
    if (mounted) _reload();
  }

  // "إضافة نبات": نفتح صفحة البحث عشان تختار نبتة وتضيفها.
  Future<void> _openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            elevation: 0,
            foregroundColor: _darkGreen,
          ),
          body: const SearchScreen(),
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<Plant>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState != ConnectionState.done;
          final plants = snapshot.data ?? [];
          final showAddButton =
              !isLoading && !snapshot.hasError && plants.isNotEmpty;

          return Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _background,
              surfaceTintColor: _background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _darkGreen,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // زر "إضافة نبات" بعرض كامل أسفل الشاشة (نفس شكل أزرار التطبيق)
            bottomNavigationBar: showAddButton
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _openSearch,
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(
                            'إضافة نبات',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: _green),
                          );
                        }
                        if (snapshot.hasError) {
                          return _message(
                            Icons.error_outline,
                            'تعذر تحميل نباتاتك',
                            'يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
                            actionText: 'إعادة المحاولة',
                            onAction: _reload,
                          );
                        }
                        if (plants.isEmpty) {
                          return _message(
                            Icons.local_florist_outlined,
                            'لا توجد نباتات في نباتاتي بعد',
                            'النباتات التي تضيفها ستظهر هنا',
                            actionText: 'إضافة نبات',
                            onAction: _openSearch,
                          );
                        }
                        return _content(plants);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- الرأس: رجوع + العنوان ----------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: _green, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'نباتاتي',
                          style: GoogleFonts.cairo(
                            color: _darkGreen,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'نباتاتك في مكان واحد، وبعنايتك تزدهر دائمًا.',
                      style: GoogleFonts.cairo(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ---------- المحتوى: بطاقة العدد + الشبكة ----------
  Widget _content(List<Plant> plants) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _countCard(plants.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.64,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _plantCard(plants[index]),
              childCount: plants.length,
            ),
          ),
        ),
      ],
    );
  }

  String _countText(int n) {
    if (n == 1) return 'نبات واحد';
    if (n == 2) return 'نباتان';
    if (n <= 10) return '$n نباتات';
    return '$n نباتًا';
  }

  Widget _countCard(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightSage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _countText(count),
                  style: GoogleFonts.cairo(
                    color: _darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'تظهر هنا النباتات التي أضفتها وتتابعها في حديقتك.',
                  style: GoogleFonts.cairo(color: _textSecondary, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- بطاقة النبتة ----------
  Widget _plantCard(Plant plant) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openDetails(plant),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _plantImage(plant),
                  ),
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    child: _deleteButton(plant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  plant.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: _darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'عرض التفاصيل',
                style: GoogleFonts.cairo(
                  color: _darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // زر الحذف على الصورة (يفتح نافذة تأكيد)
  Widget _deleteButton(Plant plant) {
    return Tooltip(
      message: 'حذف من نباتاتي',
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _confirmRemove(plant),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: Color(0xFFB3261E),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- حذف مع تأكيد + رسالة "تراجع" ----------
  Future<void> _confirmRemove(Plant plant) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف النبات؟',
      message: 'سيتم حذف ${plant.displayName} من نباتاتي.',
      confirmText: 'حذف',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await MyPlantService.instance.removePlant(plant);
      if (!mounted) return;
      _reload();

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkGreen,
          duration: const Duration(seconds: 5),
          content: Text(
            'تم حذف ${plant.displayName} من نباتاتي',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: const Color(0xFFBFD8B8),
            onPressed: () async {
              try {
                await MyPlantService.instance.addPlant(plant);
              } catch (_) {}
              if (mounted) _reload();
            },
          ),
        ),
      );
      // فلاتر ما يقفل الرسالة اللي فيها زر تلقائيًا، فنقفلها بعد 5 ثواني
      Future.delayed(const Duration(seconds: 5), controller.close);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر حذف النبات، يرجى المحاولة مرة أخرى',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  Widget _plantImage(Plant plant) {
    Widget placeholder() => Container(
          color: const Color(0xFFE9EBE4),
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, color: _grey, size: 30),
        );

    return FutureBuilder<String?>(
      future: PlantImageService.instance.imageFor(plant.scientificName),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) return placeholder();
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder(),
        );
      },
    );
  }

  // ---------- رسالة (فاضية / خطأ) ----------
  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _sage, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: _darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: _grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                actionText,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}