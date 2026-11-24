import '../models/attendance_record.dart';
import 'mock_data.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory(String memberId);
  Future<int> getMonthlyVisitCount(String memberId, {DateTime? month});
  Future<int> getYearlyVisitCount(String memberId, {int? year});
  Future<List<AttendanceRecord>> getAttendanceForMonth(String memberId, int year, int month);
}

class MockAttendanceRepository implements AttendanceRepository {
  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String memberId) async {
    return MockData.demoAttendance
        .where((r) => r.memberId == memberId)
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }

  @override
  Future<int> getMonthlyVisitCount(String memberId, {DateTime? month}) async {
    final target = month ?? DateTime.now();
    return MockData.demoAttendance
        .where((r) =>
            r.memberId == memberId &&
            r.checkIn.year == target.year &&
            r.checkIn.month == target.month)
        .length;
  }

  @override
  Future<int> getYearlyVisitCount(String memberId, {int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    return MockData.demoAttendance
        .where((r) => r.memberId == memberId && r.checkIn.year == targetYear)
        .length;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth(
      String memberId, int year, int month) async {
    return MockData.demoAttendance
        .where((r) =>
            r.memberId == memberId &&
            r.checkIn.year == year &&
            r.checkIn.month == month)
        .toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
  }
}
