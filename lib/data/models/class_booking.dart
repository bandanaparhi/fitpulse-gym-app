/// Member's reservation for a gym class.
class ClassBooking {
  final String id;
  final String classId;
  final String className;
  final String memberId;
  final DateTime classStartTime;
  final DateTime bookedAt;
  final String status; // 'Confirmed', 'Waitlisted', 'Cancelled', 'Attended'
  final String trainerName;
  final String room;
  final int durationMinutes;

  const ClassBooking({
    required this.id,
    required this.classId,
    required this.className,
    required this.memberId,
    required this.classStartTime,
    required this.bookedAt,
    this.status = 'Confirmed',
    this.trainerName = 'Sara Jenkins',
    this.room = 'Studio A (Cycle Studio)',
    this.durationMinutes = 45,
  });

  bool get isUpcoming =>
      classStartTime.isAfter(DateTime.now()) && status == 'Confirmed';

  bool get canCancel => isUpcoming;

  ClassBooking copyWith({
    String? id,
    String? classId,
    String? className,
    String? memberId,
    DateTime? classStartTime,
    DateTime? bookedAt,
    String? status,
    String? trainerName,
    String? room,
    int? durationMinutes,
  }) {
    return ClassBooking(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      memberId: memberId ?? this.memberId,
      classStartTime: classStartTime ?? this.classStartTime,
      bookedAt: bookedAt ?? this.bookedAt,
      status: status ?? this.status,
      trainerName: trainerName ?? this.trainerName,
      room: room ?? this.room,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
