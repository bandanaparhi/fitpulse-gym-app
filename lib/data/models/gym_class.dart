/// Scheduled group fitness or training class.
class GymClass {
  final String id;
  final String title;
  final String trainerName;
  final DateTime startTime;
  final int durationMinutes;
  final int capacity;
  final int bookedCount;
  final String room;
  final String category; // 'Spin', 'Yoga', 'CrossFit', 'Zumba', 'Boxing'
  final String difficulty;
  final String description;
  final String instructorBio;

  const GymClass({
    required this.id,
    required this.title,
    required this.trainerName,
    required this.startTime,
    required this.durationMinutes,
    required this.capacity,
    required this.bookedCount,
    required this.room,
    required this.category,
    this.difficulty = 'All Levels',
    this.description =
        'High-energy studio fitness session led by certified fitness coaches to maximize endurance, strength, and caloric expenditure.',
    this.instructorBio =
        'Certified fitness instructor with specialized coaching credentials and 6+ years of studio training experience.',
  });

  bool get isFull => bookedCount >= capacity;
  int get spotsRemaining => (capacity - bookedCount).clamp(0, capacity);

  GymClass copyWith({
    String? id,
    String? title,
    String? trainerName,
    DateTime? startTime,
    int? durationMinutes,
    int? capacity,
    int? bookedCount,
    String? room,
    String? category,
    String? difficulty,
    String? description,
    String? instructorBio,
  }) {
    return GymClass(
      id: id ?? this.id,
      title: title ?? this.title,
      trainerName: trainerName ?? this.trainerName,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      capacity: capacity ?? this.capacity,
      bookedCount: bookedCount ?? this.bookedCount,
      room: room ?? this.room,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      instructorBio: instructorBio ?? this.instructorBio,
    );
  }
}
