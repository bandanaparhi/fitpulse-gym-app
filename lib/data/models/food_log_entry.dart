/// Logged daily food/meal intake entry for calorie and macronutrient tracking.
class FoodLogEntry {
  final String id;
  final String foodName;
  final String quantity;
  final String mealLabel; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final DateTime consumedAt;

  const FoodLogEntry({
    required this.id,
    required this.foodName,
    required this.quantity,
    this.mealLabel = 'Snack',
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.consumedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodName': foodName,
        'quantity': quantity,
        'mealLabel': mealLabel,
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'consumedAt': consumedAt.toIso8601String(),
      };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    return FoodLogEntry(
      id: json['id'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '1 serving',
      mealLabel: json['mealLabel'] as String? ?? 'Snack',
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (json['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      consumedAt: json['consumedAt'] != null
          ? DateTime.tryParse(json['consumedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Member meal reminder schedule preferences for Breakfast, Lunch, and Dinner.
class MealReminderSettings {
  final bool enabled;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;

  const MealReminderSettings({
    this.enabled = false,
    this.breakfastTime = '08:00 AM',
    this.lunchTime = '01:00 PM',
    this.dinnerTime = '08:00 PM',
  });

  MealReminderSettings copyWith({
    bool? enabled,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
  }) {
    return MealReminderSettings(
      enabled: enabled ?? this.enabled,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'breakfastTime': breakfastTime,
        'lunchTime': lunchTime,
        'dinnerTime': dinnerTime,
      };

  factory MealReminderSettings.fromJson(Map<String, dynamic> json) {
    return MealReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      breakfastTime: json['breakfastTime'] as String? ?? '08:00 AM',
      lunchTime: json['lunchTime'] as String? ?? '01:00 PM',
      dinnerTime: json['dinnerTime'] as String? ?? '08:00 PM',
    );
  }
}
