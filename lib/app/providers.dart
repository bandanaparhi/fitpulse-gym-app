import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/image_file_picker.dart';
import '../data/services/supabase_realtime_service.dart';
import '../data/services/supabase_storage_service.dart';
import '../data/repositories/supabase_auth_repository.dart';
import '../data/repositories/supabase_member_repository.dart';
import '../data/repositories/supabase_attendance_repository.dart';
import '../data/repositories/supabase_workout_repository.dart';
import '../data/repositories/supabase_training_planner_repository.dart';
import '../data/repositories/supabase_other_repositories.dart';
import '../data/models/member.dart';
import '../data/models/membership.dart';
import '../data/models/attendance_record.dart';
import '../data/models/workout.dart';
import '../data/models/completed_workout.dart';
import '../data/models/daily_health_log.dart';
import '../data/models/food_log_entry.dart';
import '../data/models/fitness_measurement.dart';
import '../data/models/fitness_goal.dart';
import '../data/models/progress_photo.dart';
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
import '../data/models/fitness_profile.dart';
import '../data/models/workout_plan.dart';
import '../data/models/workout_session.dart';
import '../data/models/workout_log.dart';
import '../data/models/personal_record.dart';
import '../data/repositories/training_planner_repository.dart';
import '../data/repositories/workout_planner_engine.dart';
import '../data/repositories/mock_data.dart';

// --- Repository Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseAuthRepository();
  }
  return HybridAuthRepository();
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseMemberRepository();
  }
  return MockMemberRepository();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseAttendanceRepository();
  }
  return MockAttendanceRepository();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseWorkoutRepository();
  }
  return MockWorkoutRepository();
});

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseClassRepository();
  }
  return MockClassRepository();
});

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseTrainerRepository();
  }
  return MockTrainerRepository();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabasePaymentRepository();
  }
  return MockPaymentRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseSettingsRepository();
  }
  return MockSettingsRepository();
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseSupportRepository();
  }
  return MockSupportRepository();
});

final trainingPlannerRepositoryProvider =
    Provider<TrainingPlannerRepository>((ref) {
  if (SupabaseService.isReady) {
    return SupabaseTrainingPlannerRepository();
  }
  return LocalTrainingPlannerRepository();
});

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return const SupabaseStorageService();
});

final supabaseNotificationNutritionServiceProvider =
    Provider<SupabaseNotificationAndNutritionService>((ref) {
  return SupabaseNotificationAndNutritionService();
});

final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  final service = SupabaseRealtimeService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// --- State Providers ---

/// Authentication state model for session & role tracking.
class AuthState {
  final bool isAuthenticated;
  final String? memberId;
  final String role; // 'member', 'trainer', 'admin'

  const AuthState({
    this.isAuthenticated = true,
    this.memberId = 'GM-1024',
    this.role = 'member',
  });

  bool get isAdmin => role == 'admin';
  bool get isTrainer => role == 'trainer';
  bool get isMember => role == 'member';

  AuthState copyWith({
    bool? isAuthenticated,
    String? memberId,
    String? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      memberId: memberId ?? this.memberId,
      role: role ?? this.role,
    );
  }
}

/// Authentication state notifier supporting session persistence and Supabase
/// auth state streams when configured.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<dynamic>? _authSub;

  @override
  AuthState build() {
    if (SupabaseService.isReady) {
      final repo = ref.read(authRepositoryProvider);
      if (repo is SupabaseAuthRepository) {
        _authSub?.cancel();
        _authSub = repo.onAuthStateChange.listen((event) {
          final session = event.session;
          if (session == null) {
            state = const AuthState(
              isAuthenticated: false,
              memberId: null,
              role: 'member',
            );
          } else {
            state = AuthState(
              isAuthenticated: true,
              memberId: session.user.id,
              role: repo.currentRole,
            );
            _syncRoleFromProfile(session.user.id);
          }
        });
        ref.onDispose(() {
          _authSub?.cancel();
        });

        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          Future.microtask(() => _syncRoleFromProfile(session.user.id));
          return AuthState(
            isAuthenticated: true,
            memberId: session.user.id,
            role: repo.currentRole,
          );
        }
        return const AuthState(
          isAuthenticated: false,
          memberId: null,
          role: 'member',
        );
      }
    }
    return const AuthState(
      isAuthenticated: true,
      memberId: 'GM-1024',
      role: 'member',
    );
  }

  Future<void> _syncRoleFromProfile(String userId) async {
    final client = SupabaseService.clientOrNull;
    if (client == null) return;
    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final dbRole = row?['role'] as String?;
      if (dbRole != null && dbRole != state.role) {
        state = state.copyWith(role: dbRole);
      }
    } catch (_) {
      // Keep existing role safely if offline
    }
  }

  void setAuthenticated(
    bool authenticated,
    String? memberId, {
    String role = 'member',
  }) {
    state = AuthState(
      isAuthenticated: authenticated,
      memberId: memberId,
      role: role,
    );
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

/// Attendance History Notifier & Provider supporting QR Check-In / Check-Out
class AttendanceHistoryNotifier extends AsyncNotifier<List<AttendanceRecord>> {
  @override
  Future<List<AttendanceRecord>> build() async {
    final repo = ref.watch(attendanceRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getAttendanceHistory(member.id);
  }

  Future<AttendanceRecord> checkInWithQr({
    String location = 'Downtown Main Floor',
  }) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final created = await repo.checkIn(
      memberId: member.id,
      method: 'QR Code',
      location: location,
    );
    final current = state.value ?? const <AttendanceRecord>[];
    state = AsyncData([created, ...current]);
    ref.invalidate(currentMemberProvider);
    return created;
  }

  Future<AttendanceRecord?> checkOutWithQr(String attendanceId) async {
    final repo = ref.read(attendanceRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    final updated = await repo.checkOut(
      attendanceId: attendanceId,
      memberId: member.id,
    );
    final current = state.value ?? const <AttendanceRecord>[];
    if (updated != null) {
      state = AsyncData(
        current.map((r) => r.id == attendanceId ? updated : r).toList(),
      );
    }
    ref.invalidate(currentMemberProvider);
    return updated;
  }
}

final attendanceHistoryProvider = AsyncNotifierProvider<
    AttendanceHistoryNotifier, List<AttendanceRecord>>(
  AttendanceHistoryNotifier.new,
);

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

/// In-app Notifications Notifier & Provider (hydrates from Supabase + Realtime when ready)
class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    if (SupabaseService.isReady) {
      final auth = ref.watch(authStateProvider);
      if (auth.isAuthenticated && auth.memberId != null) {
        Future.microtask(() => refreshFromSupabase(auth.memberId!));
      }
      return const [];
    }
    return List<NotificationItem>.from(MockData.demoNotifications);
  }

  Future<void> refreshFromSupabase(String memberId) async {
    if (!SupabaseService.isReady) return;
    try {
      final items = await ref
          .read(supabaseNotificationNutritionServiceProvider)
          .getNotifications(memberId);
      state = items;
    } catch (_) {
      // Keep current list on transient network errors
    }
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    if (SupabaseService.isReady) {
      final memberId = ref.read(authStateProvider).memberId;
      if (memberId != null) {
        ref
            .read(supabaseNotificationNutritionServiceProvider)
            .markAsRead(id, memberId)
            .catchError((_) {});
      }
    }
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
    if (SupabaseService.isReady) {
      final memberId = ref.read(authStateProvider).memberId;
      if (memberId != null) {
        for (final n in state) {
          ref
              .read(supabaseNotificationNutritionServiceProvider)
              .markAsRead(n.id, memberId)
              .catchError((_) {});
        }
      }
    }
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

/// Watches Supabase Realtime events for the signed-in member and cleans up
/// the channel automatically on dispose.
final realtimeMemberSyncProvider = Provider<void>((ref) {
  if (!SupabaseService.isReady) return;
  final auth = ref.watch(authStateProvider);
  final userId = auth.memberId;
  if (!auth.isAuthenticated || userId == null || userId.isEmpty) return;

  final realtime = ref.watch(supabaseRealtimeServiceProvider);
  realtime.subscribeToMemberUpdates(
    userId: userId,
    onNotificationsChanged: () {
      ref.read(notificationsProvider.notifier).refreshFromSupabase(userId);
    },
    onMembershipChanged: () {
      ref.invalidate(membershipProvider);
      ref.invalidate(membershipHistoryProvider);
      ref.invalidate(currentMemberProvider);
    },
    onAttendanceChanged: () {
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(currentMemberProvider);
    },
    onTrainerMessagesChanged: () {
      ref.invalidate(trainingSessionsProvider);
    },
  );
});

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

// --- Personalized Workout & Training Planner Providers ---

/// Member's saved Fitness Profile Notifier.
class FitnessProfileNotifier extends AsyncNotifier<FitnessProfile> {
  @override
  Future<FitnessProfile> build() async {
    final repo = ref.watch(trainingPlannerRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getFitnessProfile(member.id);
  }

  Future<WorkoutPlan> saveProfileAndRegenerate(FitnessProfile profile) async {
    final repo = ref.read(trainingPlannerRepositoryProvider);
    final savedProfile = await repo.saveFitnessProfile(profile);
    state = AsyncData(savedProfile);
    final plan = await repo.generateAndSavePlan(savedProfile);
    ref.invalidate(activeWorkoutPlanProvider);
    ref.invalidate(todaySessionProvider);
    return plan;
  }
}

final fitnessProfileProvider =
    AsyncNotifierProvider<FitnessProfileNotifier, FitnessProfile>(
  FitnessProfileNotifier.new,
);

/// Active Personalized Weekly Workout Plan Notifier.
class ActiveWorkoutPlanNotifier extends AsyncNotifier<WorkoutPlan> {
  @override
  Future<WorkoutPlan> build() async {
    final repo = ref.watch(trainingPlannerRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getActiveWorkoutPlan(member.id);
  }

  Future<void> regenerateFromProfile() async {
    final profile = await ref.read(fitnessProfileProvider.future);
    final repo = ref.read(trainingPlannerRepositoryProvider);
    final plan = await repo.generateAndSavePlan(profile);
    state = AsyncData(plan);
    ref.invalidate(todaySessionProvider);
  }

  Future<void> saveUpdatedPlan(WorkoutPlan plan) async {
    final repo = ref.read(trainingPlannerRepositoryProvider);
    final saved = await repo.saveWorkoutPlan(plan);
    state = AsyncData(saved);
    ref.invalidate(todaySessionProvider);
  }
}

final activeWorkoutPlanProvider =
    AsyncNotifierProvider<ActiveWorkoutPlanNotifier, WorkoutPlan>(
  ActiveWorkoutPlanNotifier.new,
);

/// Today's Scheduled Personalized Workout Session (null if rest day).
final todaySessionProvider = FutureProvider<WorkoutSession?>((ref) async {
  final plan = await ref.watch(activeWorkoutPlanProvider.future);
  final weekday = DateTime.now().weekday;
  final today = plan.dayForWeekday(weekday);
  if (today.isRestDay || today.sessionId == null) return null;
  return plan.sessionById(today.sessionId);
});

/// Resolve any planned WorkoutSession by ID from the active plan.
final plannerSessionByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, sessionId) async {
  final plan = await ref.watch(activeWorkoutPlanProvider.future);
  return plan.sessionById(sessionId);
});

/// Logged Personalized Workouts Notifier.
class WorkoutLogsNotifier extends AsyncNotifier<List<WorkoutLog>> {
  @override
  Future<List<WorkoutLog>> build() async {
    final repo = ref.watch(trainingPlannerRepositoryProvider);
    final member = await ref.watch(currentMemberProvider.future);
    return repo.getWorkoutLogs(member.id);
  }

  Future<void> saveLog(WorkoutLog log) async {
    final repo = ref.read(trainingPlannerRepositoryProvider);
    await repo.saveWorkoutLog(log);
    final updated = await repo.getWorkoutLogs(log.memberId);
    state = AsyncData(updated);
    ref.invalidate(personalRecordsProvider);
  }

  Future<void> deleteLog(String logId) async {
    final repo = ref.read(trainingPlannerRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    await repo.deleteWorkoutLog(member.id, logId);
    final updated = await repo.getWorkoutLogs(member.id);
    state = AsyncData(updated);
  }
}

final workoutLogsProvider =
    AsyncNotifierProvider<WorkoutLogsNotifier, List<WorkoutLog>>(
  WorkoutLogsNotifier.new,
);

/// Member's Personal Records Provider.
final personalRecordsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  final repo = ref.watch(trainingPlannerRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);
  return repo.getPersonalRecords(member.id);
});

/// Safe multi-session progression suggestions computed from logged workouts.
final progressionSuggestionsProvider =
    FutureProvider<List<ProgressionSuggestion>>((ref) async {
  final logs = await ref.watch(workoutLogsProvider.future);
  final plan = await ref.watch(activeWorkoutPlanProvider.future);
  return WorkoutPlannerEngine.evaluateProgressions(logs, plan);
});

/// Most recent logged performance for a given exercise ID (shown beside active sets).
final previousExerciseLogProvider =
    FutureProvider.family<ExerciseLog?, String>((ref, exerciseId) async {
  final logs = await ref.watch(workoutLogsProvider.future);
  for (final log in logs) {
    for (final ex in log.exerciseLogs) {
      if (ex.exerciseId == exerciseId && !ex.skipped && ex.completedSetsCount > 0) {
        return ex;
      }
    }
  }
  return null;
});

/// Daily Health Activity Log Notifier (Steps, Calories Burned, Water Intake, Sleep).
class DailyHealthLogNotifier extends AsyncNotifier<DailyHealthLog> {
  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _prefsKey(String memberId, String dateKey) =>
      'fitpulse_daily_health_${memberId}_$dateKey';

  @override
  Future<DailyHealthLog> build() async {
    final member = await ref.watch(currentMemberProvider.future);
    final keyDate = _todayKey();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(member.id, keyDate));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return DailyHealthLog.fromJson(decoded);
      }
    } catch (_) {
      // Fallback cleanly to fresh today log when SharedPreferences is uninitialized
    }
    return DailyHealthLog(dateKey: keyDate);
  }

  Future<void> _persist(DailyHealthLog updated) async {
    state = AsyncData(updated);
    try {
      final member = await ref.read(currentMemberProvider.future);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey(member.id, updated.dateKey),
        jsonEncode(updated.toJson()),
      );
    } catch (_) {
      // Keep in-memory state if local storage is unavailable
    }
  }

  Future<void> addSteps(int delta) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    final nextSteps = (current.steps + delta).clamp(0, 200000);
    await _persist(current.copyWith(steps: nextSteps));
  }

  Future<void> setSteps(int steps) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    await _persist(current.copyWith(steps: steps.clamp(0, 200000)));
  }

  Future<void> addCaloriesBurned(int delta) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    final nextCal = (current.caloriesBurned + delta).clamp(0, 20000);
    await _persist(current.copyWith(caloriesBurned: nextCal));
  }

  Future<void> setCaloriesBurned(int calories) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    await _persist(current.copyWith(caloriesBurned: calories.clamp(0, 20000)));
  }

  Future<void> addWaterMl(int deltaMl) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    final nextWater = (current.waterMl + deltaMl).clamp(0, 15000);
    await _persist(current.copyWith(waterMl: nextWater));
    if (deltaMl > 0 && SupabaseService.isReady) {
      try {
        final member = await ref.read(currentMemberProvider.future);
        await ref
            .read(supabaseNotificationNutritionServiceProvider)
            .logWaterIntake(userId: member.id, quantityMl: deltaMl);
      } catch (_) {
        // Non-blocking cloud sync for water intake
      }
    }
  }

  Future<void> setSleepHours(double hours) async {
    final current = state.value ?? DailyHealthLog(dateKey: _todayKey());
    final clamped = (hours * 2).round() / 2.0;
    await _persist(current.copyWith(sleepHours: clamped.clamp(0.0, 24.0)));
  }
}

final dailyHealthLogProvider =
    AsyncNotifierProvider<DailyHealthLogNotifier, DailyHealthLog>(
  DailyHealthLogNotifier.new,
);

/// Daily Food Logging Notifier & Provider (persisted locally + synced to Supabase `food_logs`).
class FoodLogsNotifier extends AsyncNotifier<List<FoodLogEntry>> {
  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  String _prefsKey(String memberId, String dateKey) =>
      'fitpulse_food_logs_${memberId}_$dateKey';

  @override
  Future<List<FoodLogEntry>> build() async {
    final member = await ref.watch(currentMemberProvider.future);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(member.id, _todayKey()));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => FoodLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // Fallback cleanly when SharedPreferences is uninitialized
    }
    return const [];
  }

  Future<void> _persist(List<FoodLogEntry> entries) async {
    state = AsyncData(entries);
    try {
      final member = await ref.read(currentMemberProvider.future);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey(member.id, _todayKey()),
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> addFoodEntry(FoodLogEntry entry) async {
    final current = state.value ?? const <FoodLogEntry>[];
    await _persist([entry, ...current]);
    if (SupabaseService.isReady) {
      try {
        final member = await ref.read(currentMemberProvider.future);
        await ref
            .read(supabaseNotificationNutritionServiceProvider)
            .logFoodEntry(
              userId: member.id,
              foodName: entry.foodName,
              quantity: entry.quantity,
              calories: entry.calories,
              protein: entry.protein,
              carbohydrates: entry.carbohydrates,
              fat: entry.fat,
            );
      } catch (_) {}
    }
  }

  Future<void> deleteFoodEntry(String id) async {
    final current = state.value ?? const <FoodLogEntry>[];
    await _persist(current.where((e) => e.id != id).toList());
  }
}

final foodLogsProvider =
    AsyncNotifierProvider<FoodLogsNotifier, List<FoodLogEntry>>(
  FoodLogsNotifier.new,
);

/// Meal Reminder Settings Notifier & Provider.
class MealReminderNotifier extends AsyncNotifier<MealReminderSettings> {
  String _prefsKey(String memberId) => 'fitpulse_meal_reminders_$memberId';

  @override
  Future<MealReminderSettings> build() async {
    final member = await ref.watch(currentMemberProvider.future);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(member.id));
      if (raw != null && raw.isNotEmpty) {
        return MealReminderSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {}
    return const MealReminderSettings();
  }

  Future<void> updateSettings(MealReminderSettings updated) async {
    state = AsyncData(updated);
    try {
      final member = await ref.read(currentMemberProvider.future);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(member.id), jsonEncode(updated.toJson()));
    } catch (_) {}
  }
}

final mealReminderSettingsProvider =
    AsyncNotifierProvider<MealReminderNotifier, MealReminderSettings>(
  MealReminderNotifier.new,
);

/// Injectable platform image picker (can be overridden in tests).
final progressPhotoPickerProvider =
    Provider<Future<PickedImageFile?> Function()>((ref) => pickImageFile);

/// Before-and-After Progress Photos Notifier & Provider (persisted locally and synced
/// to private Supabase Storage `progress-images` bucket when authenticated).
class ProgressPhotosNotifier extends AsyncNotifier<List<ProgressPhoto>> {
  String _prefsKey(String memberId) => 'fitpulse_progress_photos_$memberId';

  @override
  Future<List<ProgressPhoto>> build() async {
    final member = await ref.watch(currentMemberProvider.future);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(member.id));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => ProgressPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _persist(List<ProgressPhoto> photos) async {
    state = AsyncData(photos);
    try {
      final member = await ref.read(currentMemberProvider.future);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey(member.id),
        jsonEncode(photos.map((p) => p.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<ProgressPhoto> saveSlotPhoto({
    required String slot, // 'before' | 'after'
    required PickedImageFile file,
    double? weightKg,
    String? notes,
  }) async {
    final member = await ref.read(currentMemberProvider.future);
    String? storagePath;
    String? signedUrl;
    if (SupabaseService.isReady) {
      try {
        final storage = ref.read(supabaseStorageServiceProvider);
        storagePath = await storage.uploadProgressImage(
          userId: member.id,
          bytes: file.bytes,
          fileName: '${slot}_${file.fileName}',
        );
        signedUrl = await storage.getSignedUrl(
          bucket: SupabaseConfig.progressImagesBucket,
          path: storagePath,
        );
      } catch (_) {}
    }

    final photo = ProgressPhoto(
      id: 'PHOTO-${slot.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
      memberId: member.id,
      slot: slot,
      fileName: file.fileName,
      imageBase64: base64Encode(file.bytes),
      storagePath: storagePath,
      signedUrl: signedUrl,
      takenAt: DateTime.now(),
      weightKg: weightKg,
      notes: notes,
    );

    final current = state.value ?? const <ProgressPhoto>[];
    final updated = [
      photo,
      ...current.where((p) => p.slot != slot),
    ];
    await _persist(updated);
    return photo;
  }

  Future<void> removeSlotPhoto(String slot) async {
    final current = state.value ?? const <ProgressPhoto>[];
    await _persist(current.where((p) => p.slot != slot).toList());
  }
}

final progressPhotosProvider =
    AsyncNotifierProvider<ProgressPhotosNotifier, List<ProgressPhoto>>(
  ProgressPhotosNotifier.new,
);
