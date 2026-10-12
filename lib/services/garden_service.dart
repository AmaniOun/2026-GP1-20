import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/garden_profile.dart';

// ==========================================
// GardenService
//
// يحفظ بيانات الحديقة داخل مستند المستخدم
// في Firestore، تحت الحقل "garden"
// (حسب ER: كل User له 0..1 GardenProfile).
// ==========================================
class GardenService {
  GardenService._internal();
  static final GardenService instance = GardenService._internal();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول حالياً');
    }
    return user.uid;
  }

  Future<void> saveGarden(GardenProfile garden) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .set({'garden': garden.toMap()}, SetOptions(merge: true));
  }

  Future<GardenProfile?> getGarden() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['garden'] == null) return null;

    return GardenProfile.fromMap(
      Map<String, dynamic>.from(data['garden'] as Map),
    );
  }

  Future<void> updateGarden(GardenProfile garden) async {
    await saveGarden(garden);
  }

  void clear() {
    // لا حاجة فعلية هنا مع Firestore، أبقيناها حتى لا ينكسر الكود القديم
  }
}
