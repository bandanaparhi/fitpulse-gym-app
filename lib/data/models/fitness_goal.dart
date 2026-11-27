/// Personal fitness goal with target value and target date.
class FitnessGoal {
  final String id;
  final String memberId;
  final String title;
  final String metricType; // 'Weight', 'Body Fat', 'Chest', 'Waist', 'Muscle Mass'
  final double startValue;
  final double currentValue;
  final double targetValue;
  final String unit; // 'kg', 'lb', '%', 'cm', 'in'
  final DateTime startDate;
  final DateTime targetDate;
  final bool isAchieved;

  const FitnessGoal({
    required this.id,
    required this.memberId,
    required this.title,
    required this.metricType,
    required this.startValue,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    required this.targetDate,
    this.isAchieved = false,
  });

  double get progressPercentage {
    if (isAchieved) return 1.0;
    final totalDelta = (targetValue - startValue).abs();
    if (totalDelta == 0) return 1.0;
    final currentDelta = (currentValue - startValue).abs();
    return (currentDelta / totalDelta).clamp(0.0, 1.0);
  }

  bool get isCompleted => isAchieved || progressPercentage >= 1.0;

  int get daysRemaining {
    final now = DateTime.now();
    final diff = targetDate.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  FitnessGoal copyWith({
    String? id,
    String? memberId,
    String? title,
    String? metricType,
    double? startValue,
    double? currentValue,
    double? targetValue,
    String? unit,
    DateTime? startDate,
    DateTime? targetDate,
    bool? isAchieved,
  }) {
    return FitnessGoal(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      metricType: metricType ?? this.metricType,
      startValue: startValue ?? this.startValue,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
    );
  }
}
