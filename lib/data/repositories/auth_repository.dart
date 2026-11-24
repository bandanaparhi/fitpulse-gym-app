import '../models/member.dart';
import '../services/firebase_service.dart';
import 'mock_data.dart';

/// Result wrapper for authentication operations.
class AuthResult {
  final bool isSuccess;
  final String? message;
  final Member? member;
  final String? errorCode;

  const AuthResult.success({this.member, this.message})
      : isSuccess = true,
        errorCode = null;

  const AuthResult.failure({required this.message, this.errorCode})
      : isSuccess = false,
        member = null;
}

/// Abstract contract for Authentication handling.
abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<AuthResult> sendPasswordReset({required String email});

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();

  bool get isAuthenticated;
  String? get currentMemberId;
}

/// Implementation supporting Mock mode with fallback to Firebase Authentication.
class HybridAuthRepository implements AuthRepository {
  bool _isAuthenticated = true;
  String? _currentMemberId = MockData.demoMember.id;
  String _currentPassword = 'Password@123';

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get currentMemberId => _currentMemberId;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // If Firebase is configured, delegate to real Firebase Auth
    if (FirebaseService.isConfigured) {
      // Future implementation when Firebase is linked:
      // final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(...)
    }

    // Mock Authentication Logic
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();

    // Check against demo user
    if (normalizedEmail == MockData.demoMember.email.toLowerCase()) {
      if (password == 'Password@123' || password == 'admin123' || password.length >= 6) {
        _isAuthenticated = true;
        _currentMemberId = MockData.demoMember.id;
        return AuthResult.success(
          member: MockData.demoMember,
          message: 'Welcome back, ${MockData.demoMember.name}!',
        );
      } else {
        return const AuthResult.failure(
          message: 'Incorrect password. Please try again.',
          errorCode: 'wrong-password',
        );
      }
    }

    // Allow mock sign-in for any valid registered email
    _isAuthenticated = true;
    _currentMemberId = 'GM-1025';
    return AuthResult.success(
      member: MockData.demoMember.copyWith(email: normalizedEmail, id: 'GM-1025'),
      message: 'Signed in successfully!',
    );
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (FirebaseService.isConfigured) {
      // Future implementation:
      // await FirebaseAuth.instance.createUserWithEmailAndPassword(...)
    }

    // Mock registration logic
    await Future.delayed(const Duration(milliseconds: 800));

    final newMemberId = 'GM-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newMember = Member(
      id: newMemberId,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      membershipId: 'MEM-BASIC-NEW',
      membershipPlan: 'Standard Member',
      membershipStatus: 'Active',
      membershipExpiry: DateTime.now().add(const Duration(days: 365)),
      attendanceCountThisMonth: 0,
      pendingPaymentAmount: 0.0,
      assignedTrainer: 'Jordan Lee',
      joinedDate: DateTime.now(),
    );

    _isAuthenticated = true;
    _currentMemberId = newMemberId;

    return AuthResult.success(
      member: newMember,
      message: 'Registration successful! Welcome to the gym family.',
    );
  }

  @override
  Future<AuthResult> sendPasswordReset({required String email}) async {
    if (FirebaseService.isConfigured) {
      // Future implementation:
      // await FirebaseAuth.instance.sendPasswordResetEmail(...)
    }

    // Mock password recovery
    await Future.delayed(const Duration(milliseconds: 600));

    return AuthResult.success(
      message: 'Password reset link sent to ${email.trim()}. Please check your inbox.',
    );
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (FirebaseService.isConfigured) {
      // Future implementation when Firebase is linked:
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null && user.email != null) {
      //   final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      //   await user.reauthenticateWithCredential(cred);
      //   await user.updatePassword(newPassword);
      // }
    }

    // Mock password verification and update
    await Future.delayed(const Duration(milliseconds: 500));

    if (currentPassword != _currentPassword && currentPassword != 'admin123') {
      return const AuthResult.failure(
        message: 'Current password is incorrect. Please verify your credentials and try again.',
        errorCode: 'wrong-password',
      );
    }

    if (newPassword.length < 6) {
      return const AuthResult.failure(
        message: 'New password must be at least 6 characters long.',
        errorCode: 'weak-password',
      );
    }

    if (newPassword == currentPassword) {
      return const AuthResult.failure(
        message: 'New password must be different from your current password.',
        errorCode: 'same-password',
      );
    }

    _currentPassword = newPassword;

    return const AuthResult.success(
      message: 'Password changed successfully! Your account security has been updated.',
    );
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isAuthenticated = false;
    _currentMemberId = null;
  }
}
