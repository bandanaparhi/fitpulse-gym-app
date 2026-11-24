import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/landing/landing_page.dart';
import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/auth/presentation/register_screen.dart';
import 'package:app/features/auth/presentation/forgot_password_screen.dart';
import 'package:app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app/features/membership/presentation/membership_screen.dart';
import 'package:app/features/attendance/presentation/attendance_screen.dart';
import 'package:app/features/workouts/presentation/workout_overview_screen.dart';
import 'package:app/features/workouts/presentation/workout_details_screen.dart';
import 'package:app/features/workouts/presentation/active_workout_screen.dart';
import 'package:app/features/progress/presentation/progress_screen.dart';
import 'package:app/features/diet/presentation/diet_plan_screen.dart';
import 'package:app/features/classes/presentation/class_listing_screen.dart';
import 'package:app/features/classes/presentation/class_details_screen.dart';
import 'package:app/features/classes/presentation/my_bookings_screen.dart';
import 'package:app/features/trainer/presentation/trainer_screen.dart';
import 'package:app/features/payments/presentation/payment_history_screen.dart';
import 'package:app/features/payments/presentation/payment_details_screen.dart';
import 'package:app/features/notifications/presentation/notifications_screen.dart';
import 'package:app/features/announcements/presentation/announcement_listing_screen.dart';
import 'package:app/features/announcements/presentation/announcement_details_screen.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/features/settings/presentation/settings_screen.dart';
import 'package:app/features/support/presentation/support_screen.dart';

void main() {
  const viewports = <String, Size>{
    'Desktop (1280x800)': Size(1280, 800),
    'Tablet (800x1024)': Size(800, 1024),
    'Mobile (375x667)': Size(375, 667),
  };

  final screens = <String, Widget Function()>{
    'Landing Page (/original-demo)': () => const OriginalLandingPage(title: 'Demo'),
    'Login Screen (/login)': () => const LoginScreen(),
    'Register Screen (/register)': () => const RegisterScreen(),
    'Forgot Password Screen (/forgot-password)': () => const ForgotPasswordScreen(),
    'Dashboard (/dashboard)': () => const DashboardScreen(),
    'Membership Screen (/membership)': () => const MembershipScreen(),
    'Attendance Screen (/attendance)': () => const AttendanceScreen(),
    'Workout Overview (/workouts)': () => const WorkoutOverviewScreen(),
    'Workout Details (/workouts/details)': () => const WorkoutDetailsScreen(workoutId: 'WK-01'),
    'Active Workout (/workouts/active)': () => const ActiveWorkoutScreen(workoutId: 'WK-01'),
    'Progress Screen (/progress)': () => const ProgressScreen(),
    'Diet Plan Screen (/diet)': () => const DietPlanScreen(),
    'Classes Listing (/classes)': () => const ClassListingScreen(),
    'Class Details (/classes/details)': () => const ClassDetailsScreen(classId: 'CLS-01'),
    'My Bookings (/classes/my-bookings)': () => const MyBookingsScreen(),
    'Trainer Screen (/trainer)': () => const TrainerScreen(),
    'Payments History (/payments)': () => const PaymentHistoryScreen(),
    'Payment Details (/payments/details)': () => const PaymentDetailsScreen(paymentId: 'INV-2026-001'),
    'Notifications Screen (/notifications)': () => const NotificationsScreen(),
    'Announcements Listing (/announcements)': () => const AnnouncementListingScreen(),
    'Announcement Details (/announcements/details)': () => const AnnouncementDetailsScreen(announcementId: 'ANN-01'),
    'Profile Screen (/profile)': () => const ProfileScreen(),
    'Settings Screen (/settings)': () => const SettingsScreen(),
    'Support Screen (/support)': () => const SupportScreen(),
  };

  group('Responsive Layout Cross-Screen Validation', () {
    for (final entry in screens.entries) {
      final screenName = entry.key;
      final screenBuilder = entry.value;

      for (final vp in viewports.entries) {
        final vpName = vp.key;
        final vpSize = vp.value;

        testWidgets('$screenName renders without overflow at $vpName', (tester) async {
          final originalOnError = FlutterError.onError;
          FlutterErrorDetails? caughtDetails;
          FlutterError.onError = (FlutterErrorDetails details) {
            caughtDetails = details;
            debugPrint('=== CAUGHT ERROR IN $screenName at $vpName ===');
            debugPrint(details.toString());
          };
          addTearDown(() {
            FlutterError.onError = originalOnError;
          });
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: screenBuilder(),
                ),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          FlutterError.onError = originalOnError;
          final err = caughtDetails ?? tester.takeException();
          expect(err, isNull, reason: 'Screen $screenName threw an exception at $vpName');
        });
      }
    }
  });
}
