import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/garden_profile.dart';
import '../models/plant.dart';
import '../models/saved_plant.dart';
import 'plant_service.dart';

// ==========================================
// MyPlantService
// ==========================================
class MyPlantService {
  MyPlantService._();
  static final MyPlantService instance = MyPlantService._();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول حالياً');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _savedPlants =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('savedPlants');

  Future<bool> isAlreadySaved(Plant plant) async {
    final snapshot = await _savedPlants
        .where('plantId', isEqualTo: plant.id)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> addPlant(Plant plant) async {
    if (await isAlreadySaved(plant)) return false;

    final saved = SavedPlant(
      savedPlantId: '',
      plantId: plant.id,
      addedAt: DateTime.now(),
    );
    await _savedPlants.add(saved.toMap());
    return true;
  }

  Future<List<Plant>> getMyPlants() async {
    final snapshot =
        await _savedPlants.orderBy('addedAt', descending: true).get();
    final allPlants = await PlantService.instance.loadPlants();

    final result = <Plant>[];
    for (final doc in snapshot.docs) {
      final saved = SavedPlant.fromMap(doc.id, doc.data());
      for (final plant in allPlants) {
        if (plant.id == saved.plantId) {
          result.add(plant);
          break;
        }
      }
    }
    return result;
  }

  // حذف النبتة من نباتاتي (يحذف سجل SavedPlant الخاص بها).
  Future<void> removePlant(Plant plant) async {
    final snapshot =
        await _savedPlants.where('plantId', isEqualTo: plant.id).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // أسباب عدم مناسبة النبتة للحديقة (قائمة فاضية = مناسبة).
  // نقارن فقط: مقاومة المناخ، مستوى العناية، ومستوى الري.
  // النباتات اللي قيمتها مركّبة مثل "Low / Moderate" نأخذ أقل قيمة.
  List<String> unsuitableReasons(Plant plant, GardenProfile garden) {
    final reasons = <String>[];

    if (plant.climateToleranceClass == 'Sensitive') {
      reasons.add('حساس لمناخ الرياض');
    }

    final careWanted = _rank(garden.careLevel.name);
    final careNeeded = _rank(plant.careLevel);
    if (careNeeded != null && careNeeded > careWanted!) {
      reasons.add('يحتاج عناية أعلى من مستوى العناية في حديقتك');
    }

    final waterLevel = garden.wateringLevel;
    final waterNeeded = _rank(plant.wateringRequirement);
    if (waterLevel != null &&
        waterNeeded != null &&
        waterNeeded > _rank(waterLevel.name)!) {
      reasons.add('يحتاج ري أكثر من مستوى الري في حديقتك');
    }

    return reasons;
  }

  // low = 0, moderate/medium = 1, high = 2 (وإذا مركّبة نأخذ الأقل)
  int? _rank(String value) {
    final ranks = <int>[];
    for (final part in value.toLowerCase().split('/')) {
      final v = part.trim();
      if (v == 'low') ranks.add(0);
      if (v == 'moderate' || v == 'medium') ranks.add(1);
      if (v == 'high') ranks.add(2);
    }
    if (ranks.isEmpty) return null;
    ranks.sort();
    return ranks.first;
  }
}