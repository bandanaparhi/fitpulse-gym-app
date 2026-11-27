import '../models/attendance_record.dart';
import 'mock_data.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory(String memberId);
  Future<int> getMonthlyVisitCount(String memberId, {DateTime? month});
  Future<int> getYearlyVisitCount(String memberId, {int? year});
  Future<List<AttendanceRecord>> getAttendanceForMonth(String memberId, int year, int month);
  Future<AttendanceRecord> checkIn({
    required String memberId,
    String method = 'QR Code',
    String location = 'Downtown Main Floor',
  });
  Future<AttendanceRecord?> checkOut({
    required String attendanceId,
    required String memberId,
  });
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _records = List<AttendanceRecord>.from(MockData.demoAttendance);

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String memberId) async {
    return _records
        .where((r) => r.memberId == memberId)
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }

  @override
  Future<int> getMonthlyVisitCount(String memberId, {DateTime? month}) async {
    final target = month ?? DateTime.now();
    return _records
        .where((r) =>
            r.memberId == memberId &&
            r.checkIn.year == target.year &&
            r.checkIn.month == target.month)
        .length;
  }

  @override
  Future<int> getYearlyVisitCount(String memberId, {int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    return _records
        .where((r) => r.memberId == memberId && r.checkIn.year == targetYear)
        .length;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth(
      String memberId, int year, int month) async {
    return _records
        .where((r) =>
            r.memberId == memberId &&
            r.checkIn.year == year &&
            r.checkIn.month == month)
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }

  @override
  Future<AttendanceRecord> checkIn({
    required String memberId,
    String method = 'QR Code',
    String location = 'Downtown Main Floor',
  }) async {
    final record = AttendanceRecord(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      memberId: memberId,
      checkIn: DateTime.now(),
      location: location,
      status: 'Present',
    );
    _records.insert(0, record);
    return record;
  }

  @override
  Future<AttendanceRecord?> checkOut({
    required String attendanceId,
    required String memberId,
  }) async {
    final index = _records.indexWhere(
      (r) => r.id == attendanceId && r.memberId == memberId,
    );
    if (index == -1) return null;
    final current = _records[index];
    final updated = AttendanceRecord(
      id: current.id,
      memberId: current.memberId,
      checkIn: current.checkIn,
      checkOut: DateTime.now(),
      location: current.location,
      status: 'Completed',
    );
    _records[index] = updated;
    return updated;
  }
}
