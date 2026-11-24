/// Record of a completed workout session.
class CompletedWorkout {
  final String id;
  final String workoutId;
  final String workoutTitle;
  final String category;
  final DateTime completedAt;
  final int durationMinutes;
  final int totalExercises;
  final int totalSetsCompleted;
  final double totalVolumeKg;

  const CompletedWorkout({
    required this.id,
    required this.workoutId,
    required this.workoutTitle,
    required this.category,
    required this.completedAt,
    required this.durationMinutes,
    required this.totalExercises,
    required this.totalSetsCompleted,
    required this.totalVolumeKg,
  });
}
