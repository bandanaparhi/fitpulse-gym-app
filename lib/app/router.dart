import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/app_shell.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/membership/presentation/membership_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/workouts/presentation/workout_overview_screen.dart';
import '../features/workouts/presentation/workout_details_screen.dart';
import '../features/workouts/presentation/active_workout_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/diet/presentation/diet_plan_screen.dart';
import '../features/classes/presentation/class_listing_screen.dart';
import '../features/classes/presentation/class_details_screen.dart';
import '../features/classes/presentation/my_bookings_screen.dart';
import '../features/trainer/presentation/trainer_screen.dart';
import '../features/payments/presentation/payment_history_screen.dart';
import '../features/payments/presentation/payment_details_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/announcements/presentation/announcement_listing_screen.dart';
import '../features/announcements/presentation/announcement_details_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/landing/landing_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');

/// Central GoRouter configuration registering all application routes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  debugLogDiagnostics: false,
  routes: [
    // Preserved Original Starter Page
    GoRoute(
      path: '/original-demo',
      builder: (context, state) => const OriginalLandingPage(title: 'Flutter Demo Home Page'),
    ),

    // Auth Routes (Top-level, outside the member shell)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Authenticated Member Routes (Inside the responsive AppShell)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(routerState: state, child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/membership',
          builder: (context, state) => const MembershipScreen(),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendanceScreen(),
        ),
        GoRoute(
          path: '/workouts',
          builder: (context, state) => const WorkoutOverviewScreen(),
          routes: [
            GoRoute(
              path: ':workoutId',
              builder: (context, state) {
                final id = state.pathParameters['workoutId'] ?? 'WK-01';
                return WorkoutDetailsScreen(workoutId: id);
              },
              routes: [
                GoRoute(
                  path: 'start',
                  builder: (context, state) {
                    final id = state.pathParameters['workoutId'] ?? 'WK-01';
                    return ActiveWorkoutScreen(workoutId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/diet-plan',
          builder: (context, state) => const DietPlanScreen(),
        ),
        GoRoute(
          path: '/classes',
          builder: (context, state) => const ClassListingScreen(),
          routes: [
            GoRoute(
              path: 'bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
            GoRoute(
              path: ':classId',
              builder: (context, state) {
                final id = state.pathParameters['classId'] ?? 'CLS-01';
                return ClassDetailsScreen(classId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/trainer',
          builder: (context, state) => const TrainerScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentHistoryScreen(),
          routes: [
            GoRoute(
              path: ':paymentId',
              builder: (context, state) {
                final id = state.pathParameters['paymentId'] ?? 'PAY-8921';
                return PaymentDetailsScreen(paymentId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/announcements',
          builder: (context, state) => const AnnouncementListingScreen(),
          routes: [
            GoRoute(
              path: ':announcementId',
              builder: (context, state) {
                final id = state.pathParameters['announcementId'] ?? 'ANN-101';
                return AnnouncementDetailsScreen(announcementId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
      ],
    ),
  ],
);
