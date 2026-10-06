import '../models/garden_profile.dart';

// ==========================================
// GardenService
//
// مؤقتاً: يخزن بيانات الحديقة بالذاكرة فقط (Mock)،
// لحد ما يتم ربط Firebase/Firestore فعلياً من قبل
// العضوة المسؤولة عن قاعدة البيانات.
//
// كل الدوال async وترجع Future، بنفس الشكل اللي
// راح تكون فيه مع Firestore (save/get/update)، عشان لما
// يصير الربط الفعلي نغيّر بس "جسم" الدالة بدون ما نغيّر
// أي كود بالشاشات اللي تستخدم هذا الـ Service.
// ==========================================
class GardenService {
  GardenService._internal();
  static final GardenService instance = GardenService._internal();

  GardenProfile? _savedGarden;

  Future<void> saveGarden(GardenProfile garden) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _savedGarden = garden;
  }

  Future<GardenProfile?> getGarden() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _savedGarden;
  }

  Future<void> updateGarden(GardenProfile garden) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _savedGarden = garden;
  }

  void clear() {
    _savedGarden = null;
  }
}