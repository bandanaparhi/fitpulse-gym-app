import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/member.dart';
import 'auth_repository.dart';

/// Supabase-backed Authentication Repository using email/password auth,
/// persisted sessions, and database-enforced `profiles.role` authorization.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _currentRole = 'member';

  String get currentRole => _currentRole;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  String? get currentMemberId => _client.auth.currentUser?.id;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Loads existing `profiles` row or inserts one once (idempotent via upsert
  /// with `ignoreDuplicates` so re-login never duplicates profiles).
  Future<Member> _fetchOrCreateProfile(
    User user, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    Map<String, dynamic> row;
    if (existing != null) {
      row = Map<String, dynamic>.from(existing);
    } else {
      final code =
          'GM-${user.id.replaceAll('-', '').substring(0, 6).toUpperCase()}';
      final insertPayload = {
        'id': user.id,
        'member_code': code,
        'full_name': (fallbackName ??
                user.userMetadata?['full_name'] as String? ??
                (user.email?.split('@').first ?? 'FitPulse Member'))
            .trim(),
        'email': (user.email ?? '').trim().toLowerCase(),
        'phone': fallbackPhone ?? user.userMetadata?['phone'] as String?,
        // Role is strictly 'member'; triggers/RLS disallow client escalation.
        'role': 'member',
      };
      final upserted = await _client
          .from('profiles')
          .upsert(insertPayload, onConflict: 'id', ignoreDuplicates: true)
          .select()
          .maybeSingle();

      row = upserted != null
          ? Map<String, dynamic>.from(upserted)
          : insertPayload;
    }

    _currentRole = (row['role'] as String?) ?? 'member';

    return Member(
      id: user.id,
      name: (row['full_name'] as String?) ?? 'Member',
      email: (row['email'] as String?) ?? (user.email ?? ''),
      phone: (row['phone'] as String?) ?? '',
      photoUrl: row['profile_image'] as String?,
      membershipId: '',
      membershipPlan: 'Standard Member',
      membershipStatus: 'Pending',
      membershipExpiry: DateTime.now().add(const Duration(days: 30)),
      attendanceCountThisMonth: 0,
      pendingPaymentAmount: 0.0,
      assignedTrainer: '',
      joinedDate: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      dateOfBirth: row['date_of_birth'] != null
          ? DateTime.tryParse(row['date_of_birth'] as String)
          : null,
      emergencyContact: row['emergency_contact'] as String?,
    );
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const AuthResult.failure(
          message: 'Unable to sign in. Please check your credentials.',
          errorCode: 'invalid_credentials',
        );
      }

      final member = await _fetchOrCreateProfile(user);
      return AuthResult.success(
        member: member,
        message: 'Welcome back, ${member.name}!',
      );
    } catch (e) {
      return AuthResult.failure(
        message: SupabaseErrorMapper.toUserMessage(e),
      );
    }
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': name.trim(),
          'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        return const AuthResult.failure(
          message: 'Registration could not be completed. Please try again.',
        );
      }

      // If email verification is required, session will be null until confirmed.
      if (response.session == null) {
        return AuthResult.success(
          member: Member(
            id: user.id,
            name: name.trim(),
            email: normalizedEmail,
            phone: phone.trim(),
            membershipId: '',
            membershipPlan: 'Pending Verification',
            membershipStatus: 'Pending',
            membershipExpiry: DateTime.now(),
            attendanceCountThisMonth: 0,
            pendingPaymentAmount: 0,
            assignedTrainer: '',
            joinedDate: DateTime.now(),
          ),
          message:
              'Account created! Please check your email inbox to verify your address before signing in.',
        );
      }

      final member = await _fetchOrCreateProfile(
        user,
        fallbackName: name.trim(),
        fallbackPhone: phone.trim(),
      );
      return AuthResult.success(
        member: member,
        message: 'Registration successful! Welcome to FitPulse Gym.',
      );
    } catch (e) {
      return AuthResult.failure(
        message: SupabaseErrorMapper.toUserMessage(e),
      );
    }
  }

  @override
  Future<AuthResult> sendPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return AuthResult.success(
        message:
            'If an account matches ${email.trim()}, a password reset link has been sent.',
      );
    } catch (e) {
      return AuthResult.failure(
        message: SupabaseErrorMapper.toUserMessage(e),
      );
    }
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) {
        return const AuthResult.failure(
          message: 'Your session has expired. Please sign in again.',
          errorCode: 'session_expired',
        );
      }

      // Re-verify current password before updating
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      await _client.auth.updateUser(UserAttributes(password: newPassword));

      return const AuthResult.success(
        message: 'Password changed successfully!',
      );
    } catch (e) {
      return AuthResult.failure(
        message: SupabaseErrorMapper.toUserMessage(e),
      );
    }
  }

  @override
  Future<void> signOut() async {
    _currentRole = 'member';
    await _client.auth.signOut();
  }
}
