import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// SavedPlant
// ==========================================
class SavedPlant {
  final String savedPlantId;
  final String plantId;
  final DateTime addedAt;

  const SavedPlant({
    required this.savedPlantId,
    required this.plantId,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory SavedPlant.fromMap(String id, Map<String, dynamic> map) {
    final addedAt = map['addedAt'];
    return SavedPlant(
      savedPlantId: id,
      plantId: map['plantId'] as String,
      addedAt: addedAt is Timestamp ? addedAt.toDate() : DateTime.now(),
    );
  }
}