/// Periodic body and fitness progress metric.
class FitnessMeasurement {
  final String id;
  final String memberId;
  final DateTime date;
  final double weightKg;
  final double? bodyFatPercentage;
  final double? muscleMassKg;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bmi;

  const FitnessMeasurement({
    required this.id,
    required this.memberId,
    required this.date,
    required this.weightKg,
    this.bodyFatPercentage,
    this.muscleMassKg,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bmi,
  });

  // Unit conversion helpers
  double get weightLb => weightKg * 2.20462;
  double? get muscleMassLb =>
      muscleMassKg != null ? muscleMassKg! * 2.20462 : null;
  double? get chestInches => chestCm != null ? chestCm! * 0.393701 : null;
  double? get waistInches => waistCm != null ? waistCm! * 0.393701 : null;
  double? get hipsInches => hipsCm != null ? hipsCm! * 0.393701 : null;

  FitnessMeasurement copyWith({
    String? id,
    String? memberId,
    DateTime? date,
    double? weightKg,
    double? bodyFatPercentage,
    double? muscleMassKg,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bmi,
  }) {
    return FitnessMeasurement(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      bmi: bmi ?? this.bmi,
    );
  }
}
