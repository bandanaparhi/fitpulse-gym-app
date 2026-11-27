import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/completed_workout.dart';
import '../models/diet_plan.dart';
import '../models/exercise.dart';
import '../models/fitness_goal.dart';
import '../models/fitness_measurement.dart';
import '../models/workout.dart';
import 'workout_repository.dart';

/// Supabase-backed [WorkoutRepository] connecting workouts, completed logs,
/// diet plans + meals, body measurements, and fitness goals to Postgres.
class SupabaseWorkoutRepository implements WorkoutRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _requireUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('Your session has expired. Please sign in again.');
    }
    return uid;
  }

  Workout _mapPlanToWorkout(Map<String, dynamic> row) {
    final schedule = row['schedule'];
    final exercises = <Exercise>[];
    if (schedule is Map && schedule['sessions'] is List) {
      final sessions = schedule['sessions'] as List;
      if (sessions.isNotEmpty && sessions.first is Map) {
        final mainEx = (sessions.first as Map)['mainExercises'];
        if (mainEx is List) {
          for (final rawEx in mainEx) {
            if (rawEx is Map) {
              final setsList = rawEx['sets'] as List? ?? const [];
              final firstSet = setsList.isNotEmpty && setsList.first is Map
                  ? setsList.first as Map
                  : const {};
              exercises.add(
                Exercise(
                  id: (rawEx['id'] as String?) ?? '',
                  name: (rawEx['name'] as String?) ?? '',
                  targetMuscle: (rawEx['targetMuscles'] as String?) ?? '',
                  sets: setsList.length,
                  reps: (firstSet['targetReps'] as int?) ?? 10,
                  weightKg: (firstSet['targetWeightKg'] as num?)?.toDouble(),
                  restSeconds: (rawEx['restSeconds'] as int?) ?? 60,
                  instructions: (rawEx['instructions'] as List?)?.join(' '),
                ),
              );
            }
          }
        }
      }
    }
    return Workout(
      id: row['id'] as String,
      title: (row['plan_name'] as String?) ?? 'Workout Plan',
      category: (row['fitness_goal'] as String?) ?? 'Strength',
      durationMinutes: 60,
      level: (row['fitness_level'] as String?) ?? 'Intermediate',
      exercises: exercises,
      notes: row['split_summary'] as String?,
    );
  }

  @override
  Future<List<Workout>> getWorkouts(String memberId) async {
    try {
      final rows = await _client
          .from('workout_plans')
          .select()
          .eq('user_id', memberId)
          .order('created_at', ascending: false);
      return rows.map(_mapPlanToWorkout).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<Workout?> getWorkoutById(String workoutId) async {
    try {
      final uid = _requireUserId();
      final row = await _client
          .from('workout_plans')
          .select()
          .eq('id', workoutId)
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return _mapPlanToWorkout(row);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<CompletedWorkout>> getCompletedWorkouts(String memberId) async {
    try {
      final rows = await _client
          .from('workout_logs')
          .select()
          .eq('user_id', memberId)
          .order('completed_at', ascending: false)
          .limit(50);

      return rows.map((row) {
        final exLogs = row['exercise_logs'] as List? ?? const [];
        double totalVol = 0;
        for (final ex in exLogs) {
          if (ex is Map && ex['sets'] is List) {
            for (final s in ex['sets'] as List) {
              if (s is Map && (s['completed'] == true)) {
                final wt = (s['weightKg'] as num?)?.toDouble() ?? 0;
                final reps = (s['repsCompleted'] as num?)?.toDouble() ?? 0;
                totalVol += wt * reps;
              }
            }
          }
        }
        return CompletedWorkout(
          id: row['id'] as String,
          workoutId: (row['workout_plan_id'] as String?) ??
              (row['session_id'] as String? ?? ''),
          workoutTitle: (row['session_title'] as String?) ?? 'Workout Session',
          category: (row['focus'] as String?) ?? 'Strength',
          completedAt:
              DateTime.tryParse('${row['completed_at']}') ?? DateTime.now(),
          durationMinutes: (row['duration'] as int?) ?? 45,
          totalExercises: exLogs.length,
          totalSetsCompleted: (row['sets_completed'] as int?) ?? 0,
          totalVolumeKg: totalVol,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> saveCompletedWorkout(CompletedWorkout completedWorkout) async {
    try {
      final uid = _requireUserId();
      await _client.from('workout_logs').insert({
        'user_id': uid,
        'session_id': completedWorkout.workoutId,
        'session_title': completedWorkout.workoutTitle,
        'focus': completedWorkout.category,
        'sets_completed': completedWorkout.totalSetsCompleted,
        'repetitions': 0,
        'weight_used': completedWorkout.totalVolumeKg,
        'duration': completedWorkout.durationMinutes,
        'completed_at': completedWorkout.completedAt.toIso8601String(),
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<DietPlan?> getDietPlan(String memberId) async {
    try {
      final planRow = await _client
          .from('diet_plans')
          .select('*, meals(*)')
          .eq('user_id', memberId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (planRow == null) return null;

      final mealRows = List<Map<String, dynamic>>.from(
        planRow['meals'] as List? ?? const [],
      )..sort(
          (a, b) =>
              ((a['sort_order'] as int?) ?? 0).compareTo(
                (b['sort_order'] as int?) ?? 0,
              ),
        );

      final Map<String, List<Meal>> mealsByDay = {};
      final List<String> summaries = [];

      for (final m in mealRows) {
        final dayLabel = (m['day_label'] as String?) ?? 'Training Day';
        final rawItems = m['food_items'] as List? ?? const [];
        final items = rawItems.map((item) {
          if (item is Map) {
            return MealFoodItem(
              name: (item['name'] as String?) ?? '',
              portionSize: (item['portionSize'] as String?) ?? '',
              notes: item['notes'] as String?,
            );
          }
          return MealFoodItem(name: item.toString(), portionSize: '');
        }).toList();

        final meal = Meal(
          id: m['id'] as String,
          name: (m['meal_name'] as String?) ?? 'Meal',
          scheduledTime: (m['meal_time'] as String?) ?? '',
          calories: (m['calories'] as int?) ?? 0,
          proteinGrams: (m['protein'] as int?) ?? 0,
          carbsGrams: (m['carbohydrates'] as int?) ?? 0,
          fatGrams: (m['fat'] as int?) ?? 0,
          foodItems: items,
          trainerNotes: m['instructions'] as String?,
        );
        mealsByDay.putIfAbsent(dayLabel, () => []).add(meal);
        summaries.add('${meal.name}: ${meal.calories} kcal (${meal.proteinGrams}g P)');
      }

      final days = mealsByDay.entries.map((entry) {
        final cals = entry.value.fold(0, (s, e) => s + e.calories);
        final p = entry.value.fold(0, (s, e) => s + e.proteinGrams);
        final c = entry.value.fold(0, (s, e) => s + e.carbsGrams);
        final f = entry.value.fold(0, (s, e) => s + e.fatGrams);
        return DietDay(
          dayName: entry.key,
          description: 'Personalized nutrition protocol',
          dayCalorieTarget: cals > 0 ? cals : (planRow['daily_calories'] as int? ?? 2200),
          dayProteinGrams: p > 0 ? p : (planRow['protein_target'] as int? ?? 150),
          dayCarbsGrams: c > 0 ? c : (planRow['carbohydrate_target'] as int? ?? 250),
          dayFatGrams: f > 0 ? f : (planRow['fat_target'] as int? ?? 70),
          meals: entry.value,
        );
      }).toList();

      return DietPlan(
        id: planRow['id'] as String,
        title: (planRow['plan_name'] as String?) ?? 'Nutrition Plan',
        goal: (planRow['fitness_goal'] as String?) ?? 'General Fitness',
        startDate:
            DateTime.tryParse('${planRow['created_at']}') ?? DateTime.now(),
        lastUpdated:
            DateTime.tryParse('${planRow['updated_at']}') ?? DateTime.now(),
        dailyCalorieTarget: (planRow['daily_calories'] as int?) ?? 2200,
        proteinGrams: (planRow['protein_target'] as int?) ?? 150,
        carbsGrams: (planRow['carbohydrate_target'] as int?) ?? 250,
        fatGrams: (planRow['fat_target'] as int?) ?? 70,
        mealSummaries: summaries,
        hydrationRecommendation:
            '${(((planRow['water_target'] as int?) ?? 3500) / 1000).toStringAsFixed(1)} Litres daily',
        trainerGeneralNotes: planRow['trainer_notes'] as String?,
        days: days,
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<FitnessMeasurement>> getMeasurements(String memberId) async {
    try {
      final rows = await _client
          .from('fitness_measurements')
          .select()
          .eq('user_id', memberId)
          .order('recorded_at', ascending: false)
          .limit(50);

      return rows.map((r) {
        return FitnessMeasurement(
          id: r['id'] as String,
          memberId: r['user_id'] as String,
          date: DateTime.tryParse('${r['recorded_at']}') ?? DateTime.now(),
          weightKg: (r['weight_kg'] as num).toDouble(),
          bodyFatPercentage: (r['body_fat_pct'] as num?)?.toDouble(),
          muscleMassKg: (r['muscle_mass_kg'] as num?)?.toDouble(),
          chestCm: (r['chest_cm'] as num?)?.toDouble(),
          waistCm: (r['waist_cm'] as num?)?.toDouble(),
          hipsCm: (r['hips_cm'] as num?)?.toDouble(),
          bmi: (r['bmi'] as num?)?.toDouble(),
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> saveMeasurement(FitnessMeasurement measurement) async {
    try {
      final uid = _requireUserId();
      await _client.from('fitness_measurements').upsert({
        if (measurement.id.contains('-') && measurement.id.length == 36)
          'id': measurement.id,
        'user_id': uid,
        'recorded_at': measurement.date.toIso8601String(),
        'weight_kg': measurement.weightKg,
        'body_fat_pct': measurement.bodyFatPercentage,
        'muscle_mass_kg': measurement.muscleMassKg,
        'chest_cm': measurement.chestCm,
        'waist_cm': measurement.waistCm,
        'hips_cm': measurement.hipsCm,
        'bmi': measurement.bmi,
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      final uid = _requireUserId();
      await _client
          .from('fitness_measurements')
          .delete()
          .eq('id', measurementId)
          .eq('user_id', uid);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<FitnessGoal>> getGoals(String memberId) async {
    try {
      final rows = await _client
          .from('fitness_goals')
          .select()
          .eq('user_id', memberId)
          .order('created_at', ascending: false);

      return rows.map((r) {
        return FitnessGoal(
          id: r['id'] as String,
          memberId: r['user_id'] as String,
          title: (r['title'] as String?) ?? '',
          metricType: (r['category'] as String?) ?? 'Weight',
          startValue: (r['start_value'] as num?)?.toDouble() ?? 0,
          currentValue: (r['current_value'] as num?)?.toDouble() ?? 0,
          targetValue: (r['target_value'] as num?)?.toDouble() ?? 0,
          unit: (r['unit'] as String?) ?? 'kg',
          startDate: DateTime.tryParse('${r['start_date']}') ?? DateTime.now(),
          targetDate: DateTime.tryParse('${r['target_date']}') ?? DateTime.now(),
          isAchieved: (r['is_completed'] as bool?) ?? false,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> saveGoal(FitnessGoal goal) async {
    try {
      final uid = _requireUserId();
      await _client.from('fitness_goals').upsert({
        if (goal.id.contains('-') && goal.id.length == 36) 'id': goal.id,
        'user_id': uid,
        'title': goal.title,
        'category': goal.metricType,
        'start_value': goal.startValue,
        'current_value': goal.currentValue,
        'target_value': goal.targetValue,
        'unit': goal.unit,
        'start_date': goal.startDate.toIso8601String().split('T').first,
        'target_date': goal.targetDate.toIso8601String().split('T').first,
        'is_completed': goal.isAchieved,
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      final uid = _requireUserId();
      await _client
          .from('fitness_goals')
          .delete()
          .eq('id', goalId)
          .eq('user_id', uid);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
