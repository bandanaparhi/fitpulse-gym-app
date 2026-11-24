import '../models/workout.dart';
import '../models/completed_workout.dart';
import '../models/diet_plan.dart';
import '../models/fitness_measurement.dart';
import '../models/fitness_goal.dart';
import 'mock_data.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> getWorkouts(String memberId);
  Future<Workout?> getWorkoutById(String workoutId);
  Future<List<CompletedWorkout>> getCompletedWorkouts(String memberId);
  Future<void> saveCompletedWorkout(CompletedWorkout completedWorkout);
  Future<DietPlan?> getDietPlan(String memberId);
  Future<List<FitnessMeasurement>> getMeasurements(String memberId);
  Future<void> saveMeasurement(FitnessMeasurement measurement);
  Future<void> deleteMeasurement(String measurementId);
  Future<List<FitnessGoal>> getGoals(String memberId);
  Future<void> saveGoal(FitnessGoal goal);
  Future<void> deleteGoal(String goalId);
}

class MockWorkoutRepository implements WorkoutRepository {
  final List<CompletedWorkout> _completedWorkouts = List.from(MockData.demoCompletedWorkouts);
  final List<FitnessMeasurement> _measurements = List.from(MockData.demoMeasurements);
  final List<FitnessGoal> _goals = List.from(MockData.demoGoals);

  @override
  Future<List<Workout>> getWorkouts(String memberId) async {
    return MockData.demoWorkouts;
  }

  @override
  Future<Workout?> getWorkoutById(String workoutId) async {
    return MockData.demoWorkouts.cast<Workout?>().firstWhere(
          (w) => w?.id == workoutId,
          orElse: () => null,
        );
  }

  @override
  Future<List<CompletedWorkout>> getCompletedWorkouts(String memberId) async {
    return List.unmodifiable(_completedWorkouts..sort((a, b) => b.completedAt.compareTo(a.completedAt)));
  }

  @override
  Future<void> saveCompletedWorkout(CompletedWorkout completedWorkout) async {
    _completedWorkouts.insert(0, completedWorkout);
  }

  @override
  Future<DietPlan?> getDietPlan(String memberId) async {
    return MockData.demoDietPlan;
  }

  @override
  Future<List<FitnessMeasurement>> getMeasurements(String memberId) async {
    return List.unmodifiable(_measurements..sort((a, b) => b.date.compareTo(a.date)));
  }

  @override
  Future<void> saveMeasurement(FitnessMeasurement measurement) async {
    final idx = _measurements.indexWhere((m) => m.id == measurement.id);
    if (idx != -1) {
      _measurements[idx] = measurement;
    } else {
      _measurements.add(measurement);
    }
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    _measurements.removeWhere((m) => m.id == measurementId);
  }

  @override
  Future<List<FitnessGoal>> getGoals(String memberId) async {
    return List.unmodifiable(_goals);
  }

  @override
  Future<void> saveGoal(FitnessGoal goal) async {
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      _goals[idx] = goal;
    } else {
      _goals.add(goal);
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
  }
}
