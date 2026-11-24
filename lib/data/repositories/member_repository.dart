import '../models/member.dart';
import '../models/membership.dart';
import '../models/trainer.dart';
import 'mock_data.dart';

/// Abstract repository defining member data contract.
abstract class MemberRepository {
  Future<Member> getCurrentMember();
  Future<Membership> getMembership(String membershipId);
  Future<List<Membership>> getMembershipHistory(String memberId);
  Future<List<Membership>> getAvailablePlans();
  Future<bool> renewMembership({required String memberId, required String planId});
  Future<Trainer?> getTrainer(String trainerId);
  Future<Member> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
    String? emergencyContact,
  });
}

/// Mock implementation that returns centralized test data.
/// Can easily be replaced by FirestoreMemberRepository.
class MockMemberRepository implements MemberRepository {
  Member _member = MockData.demoMember;
  Membership _currentMembership = MockData.demoMembership;

  @override
  Future<Member> getCurrentMember() async {
    // Return mock demo member immediately
    return _member;
  }

  @override
  Future<Membership> getMembership(String membershipId) async {
    return _currentMembership;
  }

  @override
  Future<List<Membership>> getMembershipHistory(String memberId) async {
    return MockData.demoMembershipHistory;
  }

  @override
  Future<List<Membership>> getAvailablePlans() async {
    return MockData.availablePlans;
  }

  @override
  Future<bool> renewMembership({required String memberId, required String planId}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final chosenPlan = MockData.availablePlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => MockData.demoMembership,
    );
    _currentMembership = Membership(
      id: 'MEM-RENEW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      planName: chosenPlan.planName,
      status: 'Active',
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      price: chosenPlan.price,
      durationMonths: chosenPlan.durationMonths,
      benefits: chosenPlan.benefits,
    );
    _member = _member.copyWith(
      membershipPlan: chosenPlan.planName,
      membershipStatus: 'Active',
      membershipExpiry: _currentMembership.expiryDate,
    );
    return true;
  }

  @override
  Future<Trainer?> getTrainer(String trainerId) async {
    return MockData.demoTrainer;
  }

  @override
  Future<Member> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
    String? emergencyContact,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _member = _member.copyWith(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      emergencyContact: emergencyContact,
    );
    return _member;
  }
}
