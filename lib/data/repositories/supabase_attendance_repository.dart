import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/attendance_record.dart';
import 'attendance_repository.dart';

/// Supabase-backed [AttendanceRepository] querying & recording entries in `public.attendance`.
class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseClient get _client => SupabaseService.client;

  AttendanceRecord _mapRow(Map<String, dynamic> row) {
    return AttendanceRecord(
      id: row['id'] as String,
      memberId: row['user_id'] as String,
      checkIn: DateTime.parse(row['check_in_time'] as String),
      checkOut: row['check_out_time'] != null
          ? DateTime.tryParse(row['check_out_time'] as String)
          : null,
      location: (row['location'] as String?) ?? 'Main Gym Floor',
      status: (row['status'] as String?) ?? 'Present',
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String memberId) async {
    try {
      final rows = await _client
          .from('attendance')
          .select()
          .eq('user_id', memberId)
          .order('check_in_time', ascending: false)
          .limit(100);
      return rows.map(_mapRow).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<int> getMonthlyVisitCount(String memberId, {DateTime? month}) async {
    try {
      final target = month ?? DateTime.now();
      final records =
          await getAttendanceForMonth(memberId, target.year, target.month);
      return records.length;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<int> getYearlyVisitCount(String memberId, {int? year}) async {
    try {
      final targetYear = year ?? DateTime.now().year;
      final rows = await _client
          .from('attendance')
          .select('id')
          .eq('user_id', memberId)
          .gte('attendance_date', '$targetYear-01-01')
          .lte('attendance_date', '$targetYear-12-31');
      return rows.length;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth(
    String memberId,
    int year,
    int month,
  ) async {
    try {
      final start = DateTime(year, month, 1).toIso8601String().split('T').first;
      final end =
          DateTime(year, month + 1, 0).toIso8601String().split('T').first;
      final rows = await _client
          .from('attendance')
          .select()
          .eq('user_id', memberId)
          .gte('attendance_date', start)
          .lte('attendance_date', end)
          .order('check_in_time', ascending: false);
      return rows.map(_mapRow).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  /// Records a new member check-in event.
  @override
  Future<AttendanceRecord> checkIn({
    required String memberId,
    String method = 'QR Code',
    String location = 'Downtown Main Floor',
  }) async {
    try {
      final now = DateTime.now();
      final row = await _client
          .from('attendance')
          .insert({
            'user_id': memberId,
            'check_in_time': now.toIso8601String(),
            'attendance_date': now.toIso8601String().split('T').first,
            'check_in_method': method,
            'location': location,
            'status': 'Present',
          })
          .select()
          .single();
      return _mapRow(row);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  /// Records check-out timestamp for an active visit.
  @override
  Future<AttendanceRecord?> checkOut({
    required String attendanceId,
    required String memberId,
  }) async {
    try {
      final row = await _client
          .from('attendance')
          .update({
            'check_out_time': DateTime.now().toIso8601String(),
            'status': 'Completed',
          })
          .eq('id', attendanceId)
          .eq('user_id', memberId)
          .select()
          .maybeSingle();
      return row != null ? _mapRow(row) : null;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
