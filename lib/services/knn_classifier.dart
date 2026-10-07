
import '../models/plant.dart';

/// خصائص نبتة جديدة ما نعرف فئة تحملها للمناخ بعد
/// (هذا اللي المستخدم أو الإدارة بيدخلونه عن نبتة جديدة)
class NewPlantFeatures {
  final String arabicName;
  final String scientificName;
  final String wateringRequirement; // Low / Medium / High
  final String lightRequirement; // Full Sun / Partial Sun / Shade
  final double matureHeight;
  final double matureSpread;
  final double minTempTolerance;

  NewPlantFeatures({
    required this.arabicName,
    required this.scientificName,
    required this.wateringRequirement,
    required this.lightRequirement,
    required this.matureHeight,
    required this.matureSpread,
    required this.minTempTolerance,
  });
}

class KnnClassifier {
  /// النباتات المصنّفة (Validated) اللي نستخدمها كمرجع للمقارنة
  final List<Plant> trainingData;

  KnnClassifier(this.trainingData);

  double _wateringScore(String value) {
    switch (value) {
      case 'Low':
        return 0;
      case 'Medium':
        return 1;
      case 'High':
        return 2;
      default:
        return 1;
    }
  }

  double _lightScore(String value) {
    switch (value) {
      case 'Shade':
        return 0;
      case 'Partial Sun':
        return 1;
      case 'Full Sun':
        return 2;
      default:
        return 1;
    }
  }

  /// مربع المسافة الإقليدية بين خصائص نبتتين
  /// (ما نحتاج الجذر التربيعي لأننا بس نرتب المسافات، مو نقارنها بقيمة مطلقة)
  double _squaredDistance(NewPlantFeatures a, Plant b) {
    final List<double> fa = [
      a.minTempTolerance,
      a.matureHeight,
      a.matureSpread,
      _wateringScore(a.wateringRequirement),
      _lightScore(a.lightRequirement),
    ];
    final List<double> fb = [
      b.minTempTolerance,
      b.matureHeight,
      b.matureSpread,
      _wateringScore(b.wateringRequirement),
      _lightScore(b.lightRequirement),
    ];

    double sum = 0;
    for (int i = 0; i < fa.length; i++) {
      final diff = fa[i] - fb[i];
      sum += diff * diff;
    }
    return sum;
  }

  /// يتوقع فئة تحمل المناخ لنبتة جديدة بناءً على أقرب K نباتات مصنّفة
  /// يرجع: 'Highly Tolerant' / 'Moderately Tolerant' / 'Poorly Tolerant'
  String classify(NewPlantFeatures newPlant, {int k = 5}) {
    if (trainingData.isEmpty) {
      return 'Moderately Tolerant'; // قيمة احتياطية لو ما فيه بيانات مرجعية
    }

    // 1. نحسب المسافة بين النبتة الجديدة وكل نبتة بالداتاسيت
    final distances = trainingData
        .map((p) => MapEntry(p, _squaredDistance(newPlant, p)))
        .toList();

    // 2. نرتب من الأقرب للأبعد
    distances.sort((a, b) => a.value.compareTo(b.value));

    // 3. ناخذ أقرب K نبتة
    final nearestK = distances.take(k).map((e) => e.key).toList();

    // 4. تصويت الأغلبية بين فئات أقرب K نبتة
    final votes = <String, int>{};
    for (final plant in nearestK) {
      votes[plant.climateToleranceClass] =
          (votes[plant.climateToleranceClass] ?? 0) + 1;
    }

    String predictedClass = 'Moderately Tolerant';
    int highestVotes = -1;
    votes.forEach((climateClass, voteCount) {
      if (voteCount > highestVotes) {
        highestVotes = voteCount;
        predictedClass = climateClass;
      }
    });

    return predictedClass;
  }
}