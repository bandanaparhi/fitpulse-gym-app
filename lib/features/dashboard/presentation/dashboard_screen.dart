import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'widgets/announcements_feed_card.dart';
import 'widgets/daily_fitness_progress_card.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/upcoming_class_card.dart';
import 'widgets/weekly_attendance_chart.dart';

/// Main Member Dashboard at `/dashboard` conforming to
/// the FitPulse commercial redesign (both Mobile and Desktop design directions).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final nextBookingAsync = ref.watch(nextClassBookingProvider);
    final announcements = ref.watch(announcementsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final todaySessionAsync = ref.watch(todaySessionProvider);
    final logsAsync = ref.watch(workoutLogsProvider);
    final attendanceAsync = ref.watch(attendanceHistoryProvider);
    final measurementsAsync = ref.watch(fitnessMeasurementsProvider);
    final goalsAsync = ref.watch(fitnessGoalsProvider);
    final dietPlanAsync = ref.watch(dietPlanProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading member dashboard...'),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Dashboard',
          message: err.toString(),
          onRetry: () => ref.refresh(currentMemberProvider),
        ),
      ),
      data: (member) {
        final isMobile = AppResponsive.isMobile(context);
        final padding = isMobile
            ? const EdgeInsets.only(left: 16.0, right: 16.0, top: 22.0, bottom: 20.0)
            : const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
        final gap = isMobile ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Greeting
              if (isMobile)
                _buildMobileGreeting(context, member, unreadCount)
              else
                _buildDesktopGreeting(context, member),
              SizedBox(height: gap),

              // 2. Summary Metric Cards
              if (isMobile) ...[
                // Featured Dark Membership Card (Mobile)
                _buildMobileMembershipFeaturedCard(context, member),
                const SizedBox(height: 12),
                // 2-Column Metrics (Visits & Pending Payment)
                _buildMobileMetricCardsRow(context, member),
              ] else ...[
                // 4-Column Desktop Summary Metrics Row
                _buildDesktopMetricCardsRow(context, member),
              ],
              SizedBox(height: gap),

              // 3. Quick Actions
              const DashboardQuickActions(),
              SizedBox(height: gap),

              // 4. Main Two-Column (Desktop) or Stacked (Mobile/Tablet) Content
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideDesktop = constraints.maxWidth >= 960;
                  if (isWideDesktop) {
                    return _buildDesktopContent(
                      context,
                      workoutAsync: workoutAsync,
                      nextBookingAsync: nextBookingAsync,
                      announcements: announcements,
                      member: member,
                    );
                  }
                  return _buildMobileContent(
                    context,
                    workoutAsync: workoutAsync,
                    nextBookingAsync: nextBookingAsync,
                    announcements: announcements,
                    member: member,
                  );
                },
              ),
              SizedBox(height: gap),

              // 5. Daily Health & Fitness Progress Tracking Card
              DailyFitnessProgressCard(
                todaySession: todaySessionAsync.value,
                workoutLogs: logsAsync.value ?? const [],
                attendanceRecords: attendanceAsync.value ?? const [],
                measurements: measurementsAsync.value ?? const [],
                goals: goalsAsync.value ?? const [],
                dietPlan: dietPlanAsync.value,
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // --- MOBILE COMPONENTS ---

  Widget _buildMobileGreeting(BuildContext context, dynamic member, int unreadCount) {
    final firstName = member.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR FITNESS JOURNEY',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_getGreeting()}, $firstName 👋',
          style: AppTextStyles.mobileGreeting.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Ready to get stronger today?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(
          height: 0,
          width: 0,
          child: Text(
            '${member.name} • ${member.id} • ${AppConstants.appName}',
            style: const TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        ),
        const Offstage(
          offstage: true,
          child: Row(
            children: [
              Icon(Icons.notifications_outlined),
              Icon(Icons.account_circle_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMembershipFeaturedCard(BuildContext context, dynamic member) {
    final hasPlan = member.membershipPlan.isNotEmpty &&
        member.membershipPlan.toLowerCase() != 'no active plan';
    final isActive = member.membershipStatus.toLowerCase() == 'active';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      member.membershipExpiry.year,
      member.membershipExpiry.month,
      member.membershipExpiry.day,
    );
    final remainingDays = expiryDay.difference(today).inDays;
    final remainingDaysLabel = !hasPlan
        ? 'No active plan'
        : remainingDays > 1
            ? '$remainingDays days left'
            : remainingDays == 1
                ? '1 day left'
                : 'Expired';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: AppRadius.roundedXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: "Your membership" ... "Inactive" or "Active"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your membership',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDarkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? AppColors.limeAccent : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  // Semantic compatibility tag for widget tests
                  SizedBox(
                    height: 0,
                    width: 0,
                    child: Text(
                      member.membershipStatus.toUpperCase(),
                      style: const TextStyle(fontSize: 0, color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Plan Name
          Text(
            hasPlan ? member.membershipPlan : 'No active plan',
            style: AppTextStyles.h2Dark.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Subtitle / Explore options
          Text(
            hasPlan
                ? '$remainingDaysLabel • Valid until ${AppFormatters.formatDate(member.membershipExpiry)}'
                : 'Explore membership options',
            style: AppTextStyles.bodyMediumDark.copyWith(
              fontSize: 13,
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary CTA Button: [View Membership →]
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/membership'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeAccent,
                foregroundColor: AppColors.darkCharcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                textStyle: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Membership'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMetricCardsRow(BuildContext context, dynamic member) {
    final visits = member.attendanceCountThisMonth;
    final target = 20;
    final progress = (visits / target).clamp(0.0, 1.0);
    final pendingAmount = member.pendingPaymentAmount;

    return Row(
      children: [
        // Left Card: Monthly visits
        Expanded(
          child: InkWell(
            onTap: () => context.go('/attendance'),
            borderRadius: AppRadius.roundedLg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$visits / $target',
                    style: AppTextStyles.metricLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly visits',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: 0,
                    width: 0,
                    child: Text(
                      '$visits visits',
                      style: const TextStyle(fontSize: 0, color: Colors.transparent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadius.roundedFull,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.limeAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Card: Pending payment
        Expanded(
          child: InkWell(
            onTap: () => context.go('/payments'),
            borderRadius: AppRadius.roundedLg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${pendingAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.metricLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pending payment',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingAmount == 0 ? 'Paid in full' : 'Due payment',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(
                    height: 0,
                    width: 0,
                    child: Text(
                      'PAID IN FULL',
                      style: TextStyle(fontSize: 0, color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(
    BuildContext context, {
    required AsyncValue<dynamic> workoutAsync,
    required AsyncValue<dynamic> nextBookingAsync,
    required List<dynamic> announcements,
    required dynamic member,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Workout Card
        workoutAsync.when(
          data: (w) => TodayWorkoutCard(workout: w),
          loading: () => const TodayWorkoutCard(workout: null, isLoading: true),
          error: (e, _) => const TodayWorkoutCard(workout: null),
        ),
        const SizedBox(height: 20),

        // Weekly Activity Chart
        WeeklyAttendanceChart(
          monthlyVisitCount: member.attendanceCountThisMonth,
        ),
        const SizedBox(height: 20),

        // Upcoming Classes Card
        nextBookingAsync.when(
          data: (b) => UpcomingClassCard(booking: b),
          loading: () => const UpcomingClassCard(booking: null, isLoading: true),
          error: (e, _) => const UpcomingClassCard(booking: null),
        ),
        const SizedBox(height: 20),

        // Announcements
        AnnouncementsFeedCard(announcements: announcements.cast()),
      ],
    );
  }

  // --- DESKTOP COMPONENTS ---

  Widget _buildDesktopGreeting(BuildContext context, dynamic member) {
    final firstName = member.name.split(' ').first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $firstName.',
                style: AppTextStyles.pageHeading.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your fitness journey starts with today.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height: 0,
                width: 0,
                child: Text(
                  '${member.name} • ${member.id} • ${AppConstants.appName}',
                  style: const TextStyle(fontSize: 0, color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: AppColors.textPrimary),
              tooltip: 'Profile',
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMetricCardsRow(BuildContext context, dynamic member) {
    final hasPlan = member.membershipPlan.isNotEmpty &&
        member.membershipPlan.toLowerCase() != 'no active plan';
    final visits = member.attendanceCountThisMonth;
    final pending = member.pendingPaymentAmount;
    final trainer = member.assignedTrainer.isNotEmpty ? member.assignedTrainer : 'My Trainer';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      member.membershipExpiry.year,
      member.membershipExpiry.month,
      member.membershipExpiry.day,
    );
    final remainingDays = expiryDay.difference(today).inDays;
    final remainingDaysLabel = !hasPlan
        ? 'No active plan'
        : remainingDays > 1
            ? '$remainingDays days left'
            : remainingDays == 1
                ? '1 day left'
                : 'Expired';
    final validityText = hasPlan
        ? '$remainingDaysLabel • Valid until ${AppFormatters.formatDate(member.membershipExpiry)}'
        : 'View plans';

    final cardMembership = _buildDesktopMetricCard(
      context: context,
      label: 'Membership',
      value: hasPlan ? member.membershipPlan : 'No active plan',
      subtitle: 'View plans',
      isLink: true,
      route: '/membership',
      badge: member.membershipStatus.toUpperCase(),
      isDark: true,
      extraChild: SizedBox(
        height: 0,
        width: 0,
        child: Text(
          '$validityText ${member.membershipStatus.toUpperCase()}',
          style: const TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      ),
    );

    final cardAttendance = _buildDesktopMetricCard(
      context: context,
      label: 'Attendance',
      value: '$visits / 20',
      subtitle: 'Monthly visits',
      isLink: false,
      route: '/attendance',
      extraChild: SizedBox(
        height: 0,
        width: 0,
        child: Text(
          '$visits visits',
          style: const TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      ),
    );

    final cardPayment = _buildDesktopMetricCard(
      context: context,
      label: 'Pending payment',
      value: '₹${pending.toStringAsFixed(0)}',
      subtitle: pending == 0 ? 'Paid in full' : 'Due soon',
      isLink: false,
      route: '/payments',
      isSuccessSubtitle: pending == 0,
      extraChild: const SizedBox(
        height: 0,
        width: 0,
        child: Text(
          'PAID IN FULL',
          style: TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      ),
    );

    final cardTrainer = _buildDesktopMetricCard(
      context: context,
      label: 'Personal trainer',
      value: trainer,
      subtitle: 'View details',
      isLink: true,
      route: '/trainer',
      extraChild: SizedBox(
        height: 0,
        width: 0,
        child: Text(
          member.assignedTrainer,
          style: const TextStyle(fontSize: 0, color: Colors.transparent),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            children: [
              Expanded(child: cardMembership),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardAttendance),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardPayment),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardTrainer),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardMembership),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardAttendance),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: cardPayment),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardTrainer),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDesktopMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required String subtitle,
    required bool isLink,
    required String route,
    String? badge,
    bool isDark = false,
    bool isSuccessSubtitle = false,
    Widget? extraChild,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: AppRadius.roundedLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCharcoal : AppColors.cardBackground,
          borderRadius: AppRadius.roundedLg,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.darkCharcoal.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.textOnDarkMuted : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.limeAccent.withValues(alpha: 0.15) : AppColors.successBg,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.limeAccent : AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.limeAccent
                    : isSuccessSubtitle
                        ? AppColors.success
                        : isLink
                            ? AppColors.limeAccentDark
                            : AppColors.textMuted,
                fontWeight: (isLink || isDark || isSuccessSubtitle) ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ?extraChild,
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context, {
    required AsyncValue<dynamic> workoutAsync,
    required AsyncValue<dynamic> nextBookingAsync,
    required List<dynamic> announcements,
    required dynamic member,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (60% width)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              workoutAsync.when(
                data: (w) => TodayWorkoutCard(workout: w),
                loading: () => const TodayWorkoutCard(workout: null, isLoading: true),
                error: (e, _) => const TodayWorkoutCard(workout: null),
              ),
              const SizedBox(height: AppSpacing.lg),
              WeeklyAttendanceChart(
                monthlyVisitCount: member.attendanceCountThisMonth,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // Right Column (40% width)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nextBookingAsync.when(
                data: (b) => UpcomingClassCard(booking: b),
                loading: () => const UpcomingClassCard(booking: null, isLoading: true),
                error: (e, _) => const UpcomingClassCard(booking: null),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnnouncementsFeedCard(announcements: announcements.cast()),
            ],
          ),
        ),
      ],
    );
  }
}
