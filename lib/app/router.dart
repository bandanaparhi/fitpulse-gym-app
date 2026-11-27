import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_colors.dart';
import '../core/services/supabase_service.dart';
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
import '../features/workouts/presentation/fitness_profile_screen.dart';
import '../features/workouts/presentation/weekly_plan_screen.dart';
import '../features/workouts/presentation/today_workout_screen.dart';
import '../features/workouts/presentation/exercise_details_screen.dart';
import '../features/workouts/presentation/planner_active_workout_screen.dart';
import '../features/workouts/presentation/workout_history_screen.dart';
import '../features/workouts/presentation/personal_records_screen.dart';
import '../features/workouts/presentation/training_progress_screen.dart';
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

/// Smooth, opaque fade transition for top-level shell, auth, and sibling routes.
/// Prevents transparent pages from bleeding through each other and avoids
/// abrupt horizontal Cupertino slides across the sidebar on desktop/web.
CustomTransitionPage<void> _fadePage(
  GoRouterState state,
  Widget child, {
  LocalKey? pageKey,
}) {
  return CustomTransitionPage<void>(
    key: pageKey ?? state.pageKey,
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    child: ColoredBox(
      color: AppColors.scaffoldBackground,
      child: child,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}

/// Subtle fade + slight horizontal slide for nested detail/sub-routes inside the shell.
CustomTransitionPage<void> _subRoutePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    child: ColoredBox(
      color: AppColors.scaffoldBackground,
      child: child,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

/// Central GoRouter configuration registering all application routes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  debugLogDiagnostics: false,
  redirect: (context, state) {
    if (!SupabaseService.isReady) return null;
    final isLoggedIn = SupabaseService.client.auth.currentSession != null;
    final loc = state.matchedLocation;
    final isPublicRoute = loc == '/login' ||
        loc == '/register' ||
        loc == '/forgot-password' ||
        loc == '/original-demo';
    if (!isLoggedIn && !isPublicRoute) {
      return '/login';
    }
    if (isLoggedIn && (loc == '/login' || loc == '/register')) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    // Preserved Original Starter Page
    GoRoute(
      path: '/original-demo',
      pageBuilder: (context, state) => _fadePage(
        state,
        const OriginalLandingPage(title: 'Flutter Demo Home Page'),
      ),
    ),

    // Auth Routes (Top-level, outside the member shell)
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _fadePage(state, const RegisterScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _fadePage(state, const ForgotPasswordScreen()),
    ),

    // Authenticated Member Routes (Inside the responsive AppShell)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return _fadePage(
          state,
          AppShell(routerState: state, child: child),
          pageKey: const ValueKey<String>('member-app-shell'),
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => _fadePage(state, const DashboardScreen()),
        ),
        GoRoute(
          path: '/membership',
          pageBuilder: (context, state) => _fadePage(state, const MembershipScreen()),
        ),
        GoRoute(
          path: '/attendance',
          pageBuilder: (context, state) => _fadePage(state, const AttendanceScreen()),
        ),
        GoRoute(
          path: '/workouts',
          pageBuilder: (context, state) => _fadePage(state, const WorkoutOverviewScreen()),
          routes: [
            GoRoute(
              path: 'profile',
              pageBuilder: (context, state) => _subRoutePage(state, const FitnessProfileScreen()),
            ),
            GoRoute(
              path: 'weekly-plan',
              pageBuilder: (context, state) => _subRoutePage(state, const WeeklyPlanScreen()),
            ),
            GoRoute(
              path: 'today',
              pageBuilder: (context, state) => _subRoutePage(state, const TodayWorkoutScreen()),
            ),
            GoRoute(
              path: 'history',
              pageBuilder: (context, state) => _subRoutePage(state, const WorkoutHistoryScreen()),
            ),
            GoRoute(
              path: 'records',
              pageBuilder: (context, state) => _subRoutePage(state, const PersonalRecordsScreen()),
            ),
            GoRoute(
              path: 'training-progress',
              pageBuilder: (context, state) => _subRoutePage(state, const TrainingProgressScreen()),
            ),
            GoRoute(
              path: 'exercise/:exerciseId',
              pageBuilder: (context, state) {
                final exId = state.pathParameters['exerciseId'] ?? 'ex_bench_press';
                final sessionId = state.uri.queryParameters['sessionId'];
                return _subRoutePage(
                  state,
                  ExerciseDetailsScreen(
                    exerciseId: exId,
                    sessionId: sessionId,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'session/active/:sessionId',
              pageBuilder: (context, state) {
                final sessionId = state.pathParameters['sessionId'] ?? 'SES-ADV-U1';
                return _subRoutePage(
                  state,
                  PlannerActiveWorkoutScreen(sessionId: sessionId),
                );
              },
            ),
            GoRoute(
              path: ':workoutId',
              pageBuilder: (context, state) {
                final id = state.pathParameters['workoutId'] ?? 'WK-01';
                return _subRoutePage(state, WorkoutDetailsScreen(workoutId: id));
              },
              routes: [
                GoRoute(
                  path: 'start',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['workoutId'] ?? 'WK-01';
                    return _subRoutePage(state, ActiveWorkoutScreen(workoutId: id));
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => _fadePage(state, const ProgressScreen()),
        ),
        GoRoute(
          path: '/diet-plan',
          pageBuilder: (context, state) => _fadePage(state, const DietPlanScreen()),
        ),
        GoRoute(
          path: '/classes',
          pageBuilder: (context, state) => _fadePage(state, const ClassListingScreen()),
          routes: [
            GoRoute(
              path: 'bookings',
              pageBuilder: (context, state) => _subRoutePage(state, const MyBookingsScreen()),
            ),
            GoRoute(
              path: ':classId',
              pageBuilder: (context, state) {
                final id = state.pathParameters['classId'] ?? 'CLS-01';
                return _subRoutePage(state, ClassDetailsScreen(classId: id));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/trainer',
          pageBuilder: (context, state) => _fadePage(state, const TrainerScreen()),
        ),
        GoRoute(
          path: '/payments',
          pageBuilder: (context, state) => _fadePage(state, const PaymentHistoryScreen()),
          routes: [
            GoRoute(
              path: ':paymentId',
              pageBuilder: (context, state) {
                final id = state.pathParameters['paymentId'] ?? 'PAY-8921';
                return _subRoutePage(state, PaymentDetailsScreen(paymentId: id));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => _fadePage(state, const NotificationsScreen()),
        ),
        GoRoute(
          path: '/announcements',
          pageBuilder: (context, state) => _fadePage(state, const AnnouncementListingScreen()),
          routes: [
            GoRoute(
              path: ':announcementId',
              pageBuilder: (context, state) {
                final id = state.pathParameters['announcementId'] ?? 'ANN-101';
                return _subRoutePage(state, AnnouncementDetailsScreen(announcementId: id));
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _fadePage(state, const ProfileScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _fadePage(state, const SettingsScreen()),
        ),
        GoRoute(
          path: '/support',
          pageBuilder: (context, state) => _fadePage(state, const SupportScreen()),
        ),
      ],
    ),
  ],
);
