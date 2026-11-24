/// Food item in a meal.
class MealFoodItem {
  final String name;
  final String portionSize;
  final String? notes;

  const MealFoodItem({
    required this.name,
    required this.portionSize,
    this.notes,
  });
}

/// Structured meal within a daily nutrition schedule.
class Meal {
  final String id;
  final String name; // e.g. 'Breakfast', 'Mid-Morning Snack', 'Lunch', 'Pre-Workout', 'Dinner'
  final String scheduledTime; // e.g. '07:30 AM'
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final List<MealFoodItem> foodItems;
  final String? trainerNotes;

  const Meal({
    required this.id,
    required this.name,
    required this.scheduledTime,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.foodItems,
    this.trainerNotes,
  });
}

/// Day entry in a multi-day diet plan.
class DietDay {
  final String dayName; // e.g. 'Monday (Training Day)', 'Tuesday (Training Day)', etc.
  final String description; // e.g. 'Higher carb & protein fueling protocol'
  final int dayCalorieTarget;
  final int dayProteinGrams;
  final int dayCarbsGrams;
  final int dayFatGrams;
  final List<Meal> meals;

  const DietDay({
    required this.dayName,
    required this.description,
    required this.dayCalorieTarget,
    required this.dayProteinGrams,
    required this.dayCarbsGrams,
    required this.dayFatGrams,
    required this.meals,
  });
}

/// Daily or weekly nutrition and diet plan.
class DietPlan {
  final String id;
  final String title;
  final String goal; // 'Muscle Gain', 'Fat Loss', 'Maintenance'
  final String assignedProfessional;
  final DateTime startDate;
  final DateTime lastUpdated;
  final int dailyCalorieTarget;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final List<String> mealSummaries;
  final String? hydrationRecommendation;
  final String? trainerGeneralNotes;
  final List<DietDay> days;

  const DietPlan({
    required this.id,
    required this.title,
    required this.goal,
    this.assignedProfessional = 'Coach Jordan Lee, CSCS',
    required this.startDate,
    required this.lastUpdated,
    required this.dailyCalorieTarget,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.mealSummaries,
    this.hydrationRecommendation,
    this.trainerGeneralNotes,
    this.days = const [],
  });
}
