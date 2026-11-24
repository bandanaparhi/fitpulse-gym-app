import '../models/gym_class.dart';
import '../models/class_booking.dart';
import 'mock_data.dart';

abstract class ClassRepository {
  Future<List<GymClass>> getUpcomingClasses();
  Future<GymClass?> getClassById(String classId);
  Future<List<ClassBooking>> getMemberBookings(String memberId);
  Future<bool> bookClass(String memberId, String classId);
  Future<bool> cancelBooking(String bookingId);
}

class MockClassRepository implements ClassRepository {
  final List<GymClass> _classes = List.from(MockData.demoClasses);
  final List<ClassBooking> _bookings = List.from(MockData.demoBookings);

  @override
  Future<List<GymClass>> getUpcomingClasses() async {
    return List.unmodifiable(_classes);
  }

  @override
  Future<GymClass?> getClassById(String classId) async {
    return _classes.cast<GymClass?>().firstWhere(
          (c) => c?.id == classId,
          orElse: () => null,
        );
  }

  @override
  Future<List<ClassBooking>> getMemberBookings(String memberId) async {
    return List.unmodifiable(
      _bookings.where((b) => b.memberId == memberId).toList()
        ..sort((a, b) => b.classStartTime.compareTo(a.classStartTime)),
    );
  }

  @override
  Future<bool> bookClass(String memberId, String classId) async {
    // 1. Prevent duplicate bookings
    final alreadyBooked = _bookings.any(
      (b) =>
          b.memberId == memberId &&
          b.classId == classId &&
          b.status == 'Confirmed',
    );
    if (alreadyBooked) {
      return false;
    }

    // 2. Check class capacity and status
    final classIndex = _classes.indexWhere((c) => c.id == classId);
    if (classIndex == -1) return false;

    final targetClass = _classes[classIndex];
    if (targetClass.isFull) {
      return false;
    }

    // 3. Increment booked count on the class
    _classes[classIndex] = targetClass.copyWith(
      bookedCount: targetClass.bookedCount + 1,
    );

    // 4. Create and record new confirmed booking
    final newBooking = ClassBooking(
      id: 'BKG-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      className: targetClass.title,
      memberId: memberId,
      classStartTime: targetClass.startTime,
      bookedAt: DateTime.now(),
      status: 'Confirmed',
      trainerName: targetClass.trainerName,
      room: targetClass.room,
      durationMinutes: targetClass.durationMinutes,
    );
    _bookings.insert(0, newBooking);

    return true;
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex == -1) return false;

    final booking = _bookings[bookingIndex];
    if (!booking.canCancel) return false;

    // Update booking status to Cancelled
    _bookings[bookingIndex] = booking.copyWith(status: 'Cancelled');

    // Decrement class bookedCount
    final classIndex = _classes.indexWhere((c) => c.id == booking.classId);
    if (classIndex != -1) {
      final targetClass = _classes[classIndex];
      _classes[classIndex] = targetClass.copyWith(
        bookedCount: (targetClass.bookedCount - 1).clamp(0, targetClass.capacity),
      );
    }

    return true;
  }
}
