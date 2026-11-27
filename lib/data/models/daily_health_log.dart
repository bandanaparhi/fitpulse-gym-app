/// Daily personal wellness & activity tracking snapshot (steps, calories burned,
/// water intake, and sleep duration).
class DailyHealthLog {
  final String dateKey;
  final int steps;
  final int stepsGoal;
  final int caloriesBurned;
  final int caloriesGoal;
  final int waterMl;
  final int waterGoalMl;
  final double sleepHours;
  final double sleepGoalHours;

  const DailyHealthLog({
    required this.dateKey,
    this.steps = 0,
    this.stepsGoal = 8000,
    this.caloriesBurned = 0,
    this.caloriesGoal = 500,
    this.waterMl = 0,
    this.waterGoalMl = 3000,
    this.sleepHours = 0.0,
    this.sleepGoalHours = 8.0,
  });

  double get stepsProgress =>
      stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;

  double get caloriesProgress =>
      caloriesGoal > 0 ? (caloriesBurned / caloriesGoal).clamp(0.0, 1.0) : 0.0;

  double get waterProgress =>
      waterGoalMl > 0 ? (waterMl / waterGoalMl).clamp(0.0, 1.0) : 0.0;

  double get sleepProgress =>
      sleepGoalHours > 0 ? (sleepHours / sleepGoalHours).clamp(0.0, 1.0) : 0.0;

  DailyHealthLog copyWith({
    String? dateKey,
    int? steps,
    int? stepsGoal,
    int? caloriesBurned,
    int? caloriesGoal,
    int? waterMl,
    int? waterGoalMl,
    double? sleepHours,
    double? sleepGoalHours,
  }) {
    return DailyHealthLog(
      dateKey: dateKey ?? this.dateKey,
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      waterMl: waterMl ?? this.waterMl,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'steps': steps,
        'stepsGoal': stepsGoal,
        'caloriesBurned': caloriesBurned,
        'caloriesGoal': caloriesGoal,
        'waterMl': waterMl,
        'waterGoalMl': waterGoalMl,
        'sleepHours': sleepHours,
        'sleepGoalHours': sleepGoalHours,
      };

  factory DailyHealthLog.fromJson(Map<String, dynamic> json) {
    return DailyHealthLog(
      dateKey: json['dateKey'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
      stepsGoal: json['stepsGoal'] as int? ?? 8000,
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      caloriesGoal: json['caloriesGoal'] as int? ?? 500,
      waterMl: json['waterMl'] as int? ?? 0,
      waterGoalMl: json['waterGoalMl'] as int? ?? 3000,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
      sleepGoalHours: (json['sleepGoalHours'] as num?)?.toDouble() ?? 8.0,
    );
  }
}
