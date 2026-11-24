import '../models/trainer.dart';
import '../models/training_session.dart';
import '../models/workout.dart';
import 'mock_data.dart';

/// Contract for trainer profile and personal coaching session interactions.
abstract class TrainerRepository {
  Future<Trainer?> getTrainerForMember(String memberId);
  Future<List<TrainingSession>> getTrainingSessions(String memberId);
  Future<List<Workout>> getAssignedWorkouts(String memberId);
  Future<bool> sendTrainerMessage({
    required String trainerId,
    required String memberId,
    required String message,
  });
  Future<bool> cancelSession(String sessionId);
}

/// Centralized mock implementation of TrainerRepository.
class MockTrainerRepository implements TrainerRepository {
  final List<TrainingSession> _sessions =
      List<TrainingSession>.from(MockData.demoTrainingSessions);

  final List<Map<String, dynamic>> _sentMessages = [];

  @override
  Future<Trainer?> getTrainerForMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Check if the current member has an assigned trainer
    if (MockData.demoMember.assignedTrainer.isNotEmpty) {
      return MockData.demoTrainer;
    }
    return null;
  }

  @override
  Future<List<TrainingSession>> getTrainingSessions(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sessions.where((s) => s.memberId == memberId).toList();
  }

  @override
  Future<List<Workout>> getAssignedWorkouts(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockData.demoWorkouts;
  }

  @override
  Future<bool> sendTrainerMessage({
    required String trainerId,
    required String memberId,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sentMessages.add({
      'trainerId': trainerId,
      'memberId': memberId,
      'message': message,
      'sentAt': DateTime.now(),
    });
    return true;
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(status: 'Cancelled');
      return true;
    }
    return false;
  }
}
