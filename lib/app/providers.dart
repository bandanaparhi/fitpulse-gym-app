import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/member.dart';
import '../data/models/membership.dart';
import '../data/models/attendance_record.dart';
import '../data/models/workout.dart';
import '../data/models/completed_workout.dart';
import '../data/models/fitness_measurement.dart';
import '../data/models/fitness_goal.dart';
import '../data/models/diet_plan.dart';
import '../data/models/gym_class.dart';
import '../data/models/class_booking.dart';
import '../data/models/notification_item.dart';
import '../data/models/announcement.dart';
import '../data/models/trainer.dart';
import '../data/models/training_session.dart';
import '../data/models/payment.dart';
import '../data/repositories/member_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../data/repositories/class_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/trainer_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/support_repository.dart';
import '../data/models/notification_preferences.dart';
import '../data/models/faq_item.dart';
import '../data/models/gym_contact_info.dart';
import '../data/repositories/mock_data.dart';

// --- Repository Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HybridAuthRepository();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MockMemberRepository();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return MockAttendanceRepository();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return MockWorkoutRepository();
});

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return MockClassRepository();
});

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  return MockTrainerRepository();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return MockSupportRepository();
});

// --- State Providers ---

/// Authentication state model for session tracking.
class AuthState {
  final bool isAuthenticated;
  final String? memberId;

  const AuthState({this.isAuthenticated = true, this.memberId = 'GM-1024'});

  AuthState copyWith({bool? isAuthenticated, String? memberId}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      memberId: memberId ?? this.memberId,
    );
  }
}

/// Authentication state notifier for session tracking.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(isAuthenticated: true, memberId: 'GM-1024');
  }

  void setAuthenticated(bool authenticated, String? memberId) {
    state = AuthState(isAuthenticated: authenticated, memberId: memberId);
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AuthState(isAuthenticated: false, memberId: null);
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    return repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

/// Authentication State Provider (Mock authenticated session by default for development)
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Notification Preferences Notifier & Provider
class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.getNotificationPreferences();
  }

  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    final repo = ref.read(settingsRepositoryProvider);
    try {
      final updated = await repo.updateNotificationPreferences(preferences);
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

/// Current Member AsyncNotifier & Provider
class CurrentMemberNotifier extends AsyncNotifier<Member> {
  @override
  Future<Member> build() async {
    final repo = ref.watch(memberRepositoryProvider);
    return repo.getCurrentMember();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
    String? emergencyContact,
  }) async {
    final repo = ref.read(memberRepositoryProvider);
    try {
      final updated = await repo.updateProfile(
        name: name,
        phone: phone,
        photoUrl: photoUrl,
        emergencyContact: emergencyContact,
      );
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final currentMemberProvider =
    AsyncNotifierProvider<CurrentMemberNotifier, Member>(
  CurrentMemberNotifier.new,
);

/// Membership Provider
final membershipProvider = FutureProvider<Membership?>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  if (member.membershipId.isEmpty) return null;
  return repo.getMembership(member.membershipId);
});

/// Previous Membership History Provider
final membershipHistoryProvider = FutureProvider<List<Membership>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getMembershipHistory(member.id);
});

/// Available Plans for Renewal / Upgrade Provider
final availablePlansProvider = FutureProvider<List<Membership>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getAvailablePlans();
});

/// Attendance History Provider
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getAttendanceHistory(member.id);
});

/// Attendance Filter and Calendar State
class AttendanceFilterState {
  final DateTime selectedMonth;
  final DateTime? selectedDay;
  final String? selectedLocation;

  const AttendanceFilterState({
    required this.selectedMonth,
    this.selectedDay,
    this.selectedLocation,
  });

  AttendanceFilterState copyWith({
    DateTime? selectedMonth,
    DateTime? selectedDay,
    bool clearSelectedDay = false,
    String? selectedLocation,
    bool clearLocation = false,
  }) {
    return AttendanceFilterState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
      selectedLocation: clearLocation ? null : (selectedLocation ?? this.selectedLocation),
    );
  }
}

class AttendanceFilterNotifier extends Notifier<AttendanceFilterState> {
  @override
  AttendanceFilterState build() {
    final now = DateTime.now();
    return AttendanceFilterState(
      selectedMonth: DateTime(now.year, now.month, 1),
    );
  }

  void setMonth(DateTime month) {
    state = state.copyWith(
      selectedMonth: DateTime(month.year, month.month, 1),
      clearSelectedDay: true,
    );
  }

  void previousMonth() {
    final current = state.selectedMonth;
    final prev = DateTime(current.year, current.month - 1, 1);
    setMonth(prev);
  }

  void nextMonth() {
    final current = state.selectedMonth;
    final next = DateTime(current.year, current.month + 1, 1);
    setMonth(next);
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    setMonth(DateTime(now.year, now.month, 1));
  }

  void selectDay(DateTime? day) {
    if (day == null ||
        (state.selectedDay != null &&
            state.selectedDay!.year == day.year &&
            state.selectedDay!.month == day.month &&
            state.selectedDay!.day == day.day)) {
      state = state.copyWith(clearSelectedDay: true);
    } else {
      state = state.copyWith(selectedDay: day);
    }
  }

  void setLocation(String? location) {
    if (location == null || location.isEmpty || location == 'All Locations') {
      state = state.copyWith(clearLocation: true);
    } else {
      state = state.copyWith(selectedLocation: location);
    }
  }
}

final attendanceFilterProvider =
    NotifierProvider<AttendanceFilterNotifier, AttendanceFilterState>(
        AttendanceFilterNotifier.new);

/// Workout List Provider
final workoutListProvider = FutureProvider<List<Workout>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getWorkouts(member.id);
});

/// Single Workout Provider by ID
final singleWorkoutProvider =
    FutureProvider.family<Workout?, String>((ref, workoutId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutById(workoutId);
});

/// Completed Workouts Notifier & Provider
class CompletedWorkoutsNotifier extends AsyncNotifier<List<CompletedWorkout>> {
  @override
  Future<List<CompletedWorkout>> build() async {
    final repo = ref.watch(workoutRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getCompletedWorkouts(member.id);
  }

  Future<void> addCompletedWorkout(CompletedWorkout workout) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.saveCompletedWorkout(workout);
    state = AsyncData([workout, ...?state.value]);
  }
}

final completedWorkoutsProvider = AsyncNotifierProvider<
    CompletedWorkoutsNotifier, List<CompletedWorkout>>(
  CompletedWorkoutsNotifier.new,
);

/// Available Gym Classes Notifier & Provider
class ClassesNotifier extends AsyncNotifier<List<GymClass>> {
  @override
  Future<List<GymClass>> build() async {
    final repo = ref.watch(classRepositoryProvider);
    return repo.getUpcomingClasses();
  }

  Future<void> refresh() async {
    final repo = ref.read(classRepositoryProvider);
    state = AsyncData(await repo.getUpcomingClasses());
  }
}

final classesListProvider =
    AsyncNotifierProvider<ClassesNotifier, List<GymClass>>(
  ClassesNotifier.new,
);

/// Single Gym Class Provider by ID
final singleClassProvider =
    FutureProvider.family<GymClass?, String>((ref, classId) async {
  final repo = ref.watch(classRepositoryProvider);
  return repo.getClassById(classId);
});

/// Member Class Bookings Notifier & Provider
class MemberBookingsNotifier extends AsyncNotifier<List<ClassBooking>> {
  @override
  Future<List<ClassBooking>> build() async {
    final repo = ref.watch(classRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getMemberBookings(member.id);
  }

  Future<bool> bookClass(String classId) async {
    final repo = ref.read(classRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final success = await repo.bookClass(member.id, classId);
    if (success) {
      state = AsyncData(await repo.getMemberBookings(member.id));
      await ref.read(classesListProvider.notifier).refresh();
      ref.invalidate(singleClassProvider(classId));
    }
    return success;
  }

  Future<bool> cancelBooking(String bookingId) async {
    final repo = ref.read(classRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final success = await repo.cancelBooking(bookingId);
    if (success) {
      state = AsyncData(await repo.getMemberBookings(member.id));
      await ref.read(classesListProvider.notifier).refresh();
    }
    return success;
  }
}

final classBookingsProvider =
    AsyncNotifierProvider<MemberBookingsNotifier, List<ClassBooking>>(
  MemberBookingsNotifier.new,
);

/// In-app Notifications Notifier & Provider
class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return List<NotificationItem>.from(MockData.demoNotifications);
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        n.copyWith(isRead: true),
    ];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

/// Unread Notifications Count Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

/// Published Announcements Provider (strictly filters isPublished == true)
final announcementsProvider = Provider<List<Announcement>>((ref) {
  return MockData.demoAnnouncements.where((a) => a.isPublished).toList();
});

/// Single Announcement Provider by ID
final singleAnnouncementProvider =
    FutureProvider.family<Announcement?, String>((ref, id) async {
  final announcements = ref.watch(announcementsProvider);
  try {
    return announcements.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
});

/// Today's Workout Provider
final todayWorkoutProvider = FutureProvider<Workout?>((ref) async {
  final workouts = await ref.watch(workoutListProvider.future);
  return workouts.isNotEmpty ? workouts.first : null;
});

/// Next Upcoming Class Booking Provider
final nextClassBookingProvider = FutureProvider<ClassBooking?>((ref) async {
  final bookings = await ref.watch(classBookingsProvider.future);
  return bookings.isNotEmpty ? bookings.first : null;
});

/// Diet Plan Provider
final dietPlanProvider = FutureProvider<DietPlan?>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getDietPlan(member.id);
});

/// Unit System Provider (true: Metric kg/cm, false: Imperial lb/inches)
class UnitNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void setMetric(bool value) => state = value;
}

final isMetricUnitProvider =
    NotifierProvider<UnitNotifier, bool>(UnitNotifier.new);

/// Fitness Measurements AsyncNotifier & Provider
class FitnessMeasurementsNotifier
    extends AsyncNotifier<List<FitnessMeasurement>> {
  @override
  Future<List<FitnessMeasurement>> build() async {
    final repo = ref.watch(workoutRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getMeasurements(member.id);
  }

  Future<void> saveMeasurement(FitnessMeasurement measurement) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.saveMeasurement(measurement);
    final member = await ref.read(currentMemberProvider.future);
    state = AsyncData(await repo.getMeasurements(member.id));
  }

  Future<void> deleteMeasurement(String measurementId) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.deleteMeasurement(measurementId);
    final member = await ref.read(currentMemberProvider.future);
    state = AsyncData(await repo.getMeasurements(member.id));
  }
}

final fitnessMeasurementsProvider = AsyncNotifierProvider<
    FitnessMeasurementsNotifier, List<FitnessMeasurement>>(
  FitnessMeasurementsNotifier.new,
);

/// Fitness Goals AsyncNotifier & Provider
class FitnessGoalsNotifier extends AsyncNotifier<List<FitnessGoal>> {
  @override
  Future<List<FitnessGoal>> build() async {
    final repo = ref.watch(workoutRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getGoals(member.id);
  }

  Future<void> saveGoal(FitnessGoal goal) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.saveGoal(goal);
    final member = await ref.read(currentMemberProvider.future);
    state = AsyncData(await repo.getGoals(member.id));
  }

  Future<void> deleteGoal(String goalId) async {
    final repo = ref.read(workoutRepositoryProvider);
    await repo.deleteGoal(goalId);
    final member = await ref.read(currentMemberProvider.future);
    state = AsyncData(await repo.getGoals(member.id));
  }
}

final fitnessGoalsProvider =
    AsyncNotifierProvider<FitnessGoalsNotifier, List<FitnessGoal>>(
  FitnessGoalsNotifier.new,
);

/// Assigned Trainer Provider
final assignedTrainerProvider = FutureProvider<Trainer?>((ref) async {
  final repo = ref.watch(trainerRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  if (member.assignedTrainer.isEmpty) return null;
  return repo.getTrainerForMember(member.id);
});

/// Workouts Assigned by Trainer Provider
final trainerAssignedWorkoutsProvider =
    FutureProvider<List<Workout>>((ref) async {
  final repo = ref.watch(trainerRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getAssignedWorkouts(member.id);
});

/// Personal Training Sessions Notifier & Provider
class TrainingSessionsNotifier
    extends AsyncNotifier<List<TrainingSession>> {
  @override
  Future<List<TrainingSession>> build() async {
    final repo = ref.watch(trainerRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getTrainingSessions(member.id);
  }

  Future<bool> cancelSession(String sessionId) async {
    final repo = ref.read(trainerRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final success = await repo.cancelSession(sessionId);
    if (success) {
      state = AsyncData(await repo.getTrainingSessions(member.id));
    }
    return success;
  }

  Future<bool> sendMessage(String message) async {
    final repo = ref.read(trainerRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final trainer = await ref.read(assignedTrainerProvider.future);
    if (trainer == null) return false;
    return repo.sendTrainerMessage(
      trainerId: trainer.id,
      memberId: member.id,
      message: message,
    );
  }
}

final trainingSessionsProvider = AsyncNotifierProvider<
    TrainingSessionsNotifier, List<TrainingSession>>(
  TrainingSessionsNotifier.new,
);

/// Payment History Provider
final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getPaymentHistory(member.id);
});

/// Single Payment Provider by Transaction ID
final singlePaymentProvider =
    FutureProvider.family<Payment?, String>((ref, paymentId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentById(paymentId);
});

/// Pending Payment Amount Provider
final pendingPaymentAmountProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getPendingBalance(member.id);
});

/// Online Payment Gateway Configuration Status Provider
final isPaymentGatewayConfiguredProvider = Provider<bool>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.isOnlinePaymentConfigured();
});

/// Support & FAQ Providers
final gymContactInfoProvider = FutureProvider<GymContactInfo>((ref) async {
  final repo = ref.watch(supportRepositoryProvider);
  return repo.getContactInfo();
});

class FaqQueryState {
  final String category;
  final String searchQuery;

  const FaqQueryState({this.category = 'All', this.searchQuery = ''});

  FaqQueryState copyWith({String? category, String? searchQuery}) {
    return FaqQueryState(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FaqQueryNotifier extends Notifier<FaqQueryState> {
  @override
  FaqQueryState build() => const FaqQueryState();

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final faqQueryProvider =
    NotifierProvider<FaqQueryNotifier, FaqQueryState>(FaqQueryNotifier.new);

final faqListProvider = FutureProvider<List<FaqItem>>((ref) async {
  final repo = ref.watch(supportRepositoryProvider);
  final query = ref.watch(faqQueryProvider);
  return repo.getFaqs(
    category: query.category,
    searchQuery: query.searchQuery,
  );
});
