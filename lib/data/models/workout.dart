import 'exercise.dart';

/// Workout plan definition.
class Workout {
  final String id;
  final String title;
  final String category; // 'Strength', 'Cardio', 'HIIT', 'Flexibility'
  final int durationMinutes;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final List<Exercise> exercises;
  final String? notes;

  const Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.level,
    required this.exercises,
    this.notes,
  });

  int get totalExercises => exercises.length;
}
