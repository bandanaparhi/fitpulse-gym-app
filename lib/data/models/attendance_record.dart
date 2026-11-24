/// Attendance entry for gym check-in and check-out.
class AttendanceRecord {
  final String id;
  final String memberId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String location;
  final String status; // 'Present', 'Completed', 'Late'

  const AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.checkIn,
    this.checkOut,
    required this.location,
    this.status = 'Present',
  });

  Duration? get duration {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }
}
