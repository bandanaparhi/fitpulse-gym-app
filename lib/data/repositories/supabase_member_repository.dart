import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/trainer.dart';
import '../services/supabase_storage_service.dart';
import 'member_repository.dart';

/// Supabase-backed [MemberRepository] reading/updating `profiles`,
/// `memberships`, `membership_plans`, `trainers`, and `attendance` counts.
class SupabaseMemberRepository implements MemberRepository {
  SupabaseClient get _client => SupabaseService.client;
  final SupabaseStorageService _storage = const SupabaseStorageService();

  String _requireUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('Your session has expired. Please sign in again.');
    }
    return uid;
  }

  @override
  Future<Member> getCurrentMember() async {
    try {
      final uid = _requireUserId();
      final profileRow =
          await _client.from('profiles').select().eq('id', uid).single();

      // Active or most recent membership joined with plan name
      final memRows = await _client
          .from('memberships')
          .select('*, membership_plans(name)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      String membershipId = '';
      String membershipPlan = 'No Active Plan';
      String membershipStatus = 'Inactive';
      DateTime membershipExpiry = DateTime.now();

      if (memRows.isNotEmpty) {
        final m = memRows.first;
        membershipId = m['id'] as String;
        membershipStatus = (m['status'] as String?) ?? 'Active';
        membershipExpiry = DateTime.tryParse('${m['end_date']}') ?? DateTime.now();
        final planMap = m['membership_plans'];
        if (planMap is Map && planMap['name'] != null) {
          membershipPlan = planMap['name'] as String;
        }
      }

      // Monthly attendance count
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final attendanceRows = await _client
          .from('attendance')
          .select('id')
          .eq('user_id', uid)
          .gte('attendance_date', monthStart.split('T').first);

      // Pending payment balance from verified ledger
      final pendingRows = await _client
          .from('payments')
          .select('amount')
          .eq('user_id', uid)
          .eq('payment_status', 'Pending');
      double pendingTotal = 0;
      for (final row in pendingRows) {
        pendingTotal += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      // Assigned trainer name
      String assignedTrainerName = '';
      final assignRows = await _client
          .from('trainer_assignments')
          .select('trainers(full_name)')
          .eq('member_id', uid)
          .eq('is_active', true)
          .limit(1);
      if (assignRows.isNotEmpty) {
        final tMap = assignRows.first['trainers'];
        if (tMap is Map && tMap['full_name'] != null) {
          assignedTrainerName = tMap['full_name'] as String;
        }
      }

      // Resolve signed URL if profile_image is a storage path
      String? photoUrl = profileRow['profile_image'] as String?;
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          !photoUrl.startsWith('http')) {
        try {
          photoUrl = await _storage.getSignedUrl(
            bucket: SupabaseConfig.profileImagesBucket,
            path: photoUrl,
          );
        } catch (_) {
          // Keep null/raw if signed URL fails
        }
      }

      return Member(
        id: uid,
        name: (profileRow['full_name'] as String?) ?? 'Member',
        email: (profileRow['email'] as String?) ?? '',
        phone: (profileRow['phone'] as String?) ?? '',
        photoUrl: photoUrl,
        membershipId: membershipId,
        membershipPlan: membershipPlan,
        membershipStatus: membershipStatus,
        membershipExpiry: membershipExpiry,
        attendanceCountThisMonth: attendanceRows.length,
        pendingPaymentAmount: pendingTotal,
        assignedTrainer: assignedTrainerName,
        joinedDate: profileRow['created_at'] != null
            ? DateTime.tryParse('${profileRow['created_at']}') ?? DateTime.now()
            : DateTime.now(),
        dateOfBirth: profileRow['date_of_birth'] != null
            ? DateTime.tryParse('${profileRow['date_of_birth']}')
            : null,
        emergencyContact: profileRow['emergency_contact'] as String?,
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Membership _mapMembership(Map<String, dynamic> row) {
    final planData = row['membership_plans'] as Map<String, dynamic>?;
    return Membership(
      id: row['id'] as String,
      planName: (planData?['name'] as String?) ?? 'Membership',
      status: (row['status'] as String?) ?? 'Active',
      startDate: DateTime.tryParse('${row['start_date']}') ?? DateTime.now(),
      expiryDate: DateTime.tryParse('${row['end_date']}') ?? DateTime.now(),
      price: (row['amount'] as num?)?.toDouble() ?? 0,
      durationMonths: (planData?['duration'] as String?) ?? '1 Month',
      benefits: List<String>.from(planData?['features'] as List? ?? const []),
    );
  }

  @override
  Future<Membership> getMembership(String membershipId) async {
    try {
      final uid = _requireUserId();
      final row = await _client
          .from('memberships')
          .select('*, membership_plans(name, duration, features)')
          .eq('id', membershipId)
          .eq('user_id', uid)
          .single();
      return _mapMembership(row);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<Membership>> getMembershipHistory(String memberId) async {
    try {
      final rows = await _client
          .from('memberships')
          .select('*, membership_plans(name, duration, features)')
          .eq('user_id', memberId)
          .order('start_date', ascending: false);
      return rows.map((r) => _mapMembership(r)).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<Membership>> getAvailablePlans() async {
    try {
      final rows = await _client
          .from('membership_plans')
          .select()
          .eq('active_status', true)
          .order('price', ascending: false);

      return rows.map((r) {
        return Membership(
          id: r['id'] as String,
          planName: (r['name'] as String?) ?? '',
          status: 'Available',
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(
            Duration(days: ((r['duration_months'] as int?) ?? 1) * 30),
          ),
          price: (r['price'] as num?)?.toDouble() ?? 0,
          durationMonths: (r['duration'] as String?) ?? '',
          benefits: List<String>.from(r['features'] as List? ?? const []),
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<bool> renewMembership({
    required String memberId,
    required String planId,
  }) async {
    // Membership activation & payment confirmation require front-desk or
    // server-side payment verification (RLS enforces payment_status = 'Pending'
    // on member-initiated requests).
    try {
      final plan = await _client
          .from('membership_plans')
          .select()
          .eq('id', planId)
          .single();
      final start = DateTime.now();
      final months = (plan['duration_months'] as int?) ?? 1;
      final end = DateTime(start.year, start.month + months, start.day);

      await _client.from('memberships').insert({
        'user_id': memberId,
        'membership_plan_id': planId,
        'start_date': start.toIso8601String().split('T').first,
        'end_date': end.toIso8601String().split('T').first,
        'status': 'Pending',
        'amount': plan['price'],
        'payment_status': 'Pending',
      });
      return true;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<Trainer?> getTrainer(String trainerId) async {
    try {
      final row = await _client
          .from('trainers')
          .select()
          .eq('id', trainerId)
          .maybeSingle();
      if (row == null) return null;
      return Trainer(
        id: row['id'] as String,
        name: (row['full_name'] as String?) ?? '',
        specialty: (row['specialization'] as String?) ?? '',
        bio: (row['bio'] as String?) ?? '',
        photoUrl: row['profile_image'] as String?,
        rating: (row['rating'] as num?)?.toDouble() ?? 5.0,
        totalClients: 0,
        phone: '',
        email: '',
        qualifications:
            List<String>.from(row['certifications'] as List? ?? const []),
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<Member> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
    String? emergencyContact,
  }) async {
    try {
      final uid = _requireUserId();
      await _client.from('profiles').update({
        'full_name': name.trim(),
        'phone': phone.trim(),
        'profile_image': ?photoUrl,
        if (emergencyContact != null)
          'emergency_contact': emergencyContact.trim(),
      }).eq('id', uid);

      return await getCurrentMember();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
