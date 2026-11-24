/// Personal training session scheduled between a gym member and their assigned coach.
class TrainingSession {
  final String id;
  final String trainerId;
  final String trainerName;
  final String memberId;
  final String sessionTitle;
  final DateTime sessionDate;
  final int durationMinutes;
  final String location;
  final String status; // 'Scheduled', 'Completed', 'Cancelled'
  final String? focusArea;
  final String? notes;

  const TrainingSession({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.memberId,
    required this.sessionTitle,
    required this.sessionDate,
    required this.durationMinutes,
    required this.location,
    this.status = 'Scheduled',
    this.focusArea,
    this.notes,
  });

  bool get isUpcoming =>
      sessionDate.isAfter(DateTime.now()) && status == 'Scheduled';

  bool get canCancel => isUpcoming;

  TrainingSession copyWith({
    String? id,
    String? trainerId,
    String? trainerName,
    String? memberId,
    String? sessionTitle,
    DateTime? sessionDate,
    int? durationMinutes,
    String? location,
    String? status,
    String? focusArea,
    String? notes,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      memberId: memberId ?? this.memberId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      status: status ?? this.status,
      focusArea: focusArea ?? this.focusArea,
      notes: notes ?? this.notes,
    );
  }
}
