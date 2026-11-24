/// Individual exercise item within a workout.
class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final int sets;
  final int reps;
  final double? weightKg;
  final int restSeconds;
  final String? instructions;

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    this.weightKg,
    this.restSeconds = 60,
    this.instructions,
  });
}
