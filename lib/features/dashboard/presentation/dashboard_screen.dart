import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/summary_card.dart';
import 'widgets/announcements_feed_card.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/today_workout_card.dart';
import 'widgets/upcoming_class_card.dart';
import 'widgets/weekly_attendance_chart.dart';

/// Main Member Dashboard at `/dashboard`.
///
/// Displays:
/// - Personalized welcome message
/// - Member profile and notification icons
/// - Membership status and expiry date
/// - Monthly attendance
/// - Today's workout
/// - Pending payment
/// - Weekly attendance chart
/// - Upcoming class booking
/// - Recent gym announcements
/// - Quick action shortcuts
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
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Welcome & Profile Banner
              _buildWelcomeBanner(context, member, unreadCount),
              const SizedBox(height: AppSpacing.lg),

              // 2. Summary Metric KPI Cards
              _buildKpiMetricsGrid(context, member),
              const SizedBox(height: AppSpacing.xl),

              // 3. Quick Actions Section
              const DashboardQuickActions(),
              const SizedBox(height: AppSpacing.xl),

              // 4. Main Content Area (Two-column layout on desktop, stacked on mobile)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 960;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Today's Workout + Weekly Attendance Chart
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              workoutAsync.when(
                                data: (w) => TodayWorkoutCard(workout: w),
                                loading: () => const TodayWorkoutCard(workout: null, isLoading: true),
                                error: (e, _) => TodayWorkoutCard(workout: null),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              WeeklyAttendanceChart(
                                monthlyVisitCount: member.attendanceCountThisMonth,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),

                        // Right Column: Upcoming Class Booking + Gym Announcements
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              nextBookingAsync.when(
                                data: (b) => UpcomingClassCard(booking: b),
                                loading: () => const UpcomingClassCard(booking: null, isLoading: true),
                                error: (e, _) => UpcomingClassCard(booking: null),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnnouncementsFeedCard(announcements: announcements),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile / Tablet stacked presentation
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      workoutAsync.when(
                        data: (w) => TodayWorkoutCard(workout: w),
                        loading: () => const TodayWorkoutCard(workout: null, isLoading: true),
                        error: (e, _) => TodayWorkoutCard(workout: null),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      nextBookingAsync.when(
                        data: (b) => UpcomingClassCard(booking: b),
                        loading: () => const UpcomingClassCard(booking: null, isLoading: true),
                        error: (e, _) => UpcomingClassCard(booking: null),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      WeeklyAttendanceChart(
                        monthlyVisitCount: member.attendanceCountThisMonth,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnnouncementsFeedCard(announcements: announcements),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  /// Top Welcome header with member identification, status badge, and notification shortcut.
  Widget _buildWelcomeBanner(BuildContext context, dynamic member, int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: AppRadius.roundedLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Member Avatar
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: AppRadius.roundedFull,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.darkElevated,
              child: Text(
                'AM',
                style: AppTextStyles.h3.copyWith(color: AppColors.limeAccent),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Personalized Welcome Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${_getGreeting()}, ${member.name} 👋',
                        style: AppTextStyles.h2Dark.copyWith(fontSize: 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppConstants.appName} • Member ID: ${member.id} • Coach: ${member.assignedTrainer}',
                  style: AppTextStyles.bodyMediumDark.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Notification shortcut button
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textOnDark),
                tooltip: 'View Notifications',
                onPressed: () => context.go('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.limeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkCharcoal,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Profile shortcut button
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.textOnDark),
            tooltip: 'View Profile',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  /// 4 Key KPI metrics: Membership Status, Monthly Attendance, Pending Payment, Coach.
  Widget _buildKpiMetricsGrid(BuildContext context, dynamic member) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 960 ? 4 : (constraints.maxWidth >= 540 ? 2 : 1);

        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 2.5 : 1.7,
          children: [
            // 1. Membership Status & Expiry
            SummaryCard(
              label: 'Membership Status',
              value: member.membershipPlan,
              subtitle: 'Valid until ${AppFormatters.formatDate(member.membershipExpiry)}',
              icon: Icons.workspace_premium_outlined,
              iconColor: AppColors.limeAccentDark,
              iconBgColor: AppColors.limeAccent.withValues(alpha: 0.18),
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  member.membershipStatus.toUpperCase(),
                  style: AppTextStyles.badge.copyWith(color: AppColors.success),
                ),
              ),
              onTap: () => context.go('/membership'),
            ),

            // 2. Monthly Attendance
            SummaryCard(
              label: 'Monthly Attendance',
              value: '${member.attendanceCountThisMonth} visits',
              subtitle: 'Target: 20 visits (90% goal)',
              icon: Icons.qr_code_scanner_outlined,
              iconColor: AppColors.darkCharcoal,
              iconBgColor: AppColors.scaffoldBackground,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'ON TRACK 🔥',
                  style: AppTextStyles.badge.copyWith(color: AppColors.limeAccentDark),
                ),
              ),
              onTap: () => context.go('/attendance'),
            ),

            // 3. Pending Payment
            SummaryCard(
              label: 'Pending Payment',
              value: AppFormatters.formatCurrency(member.pendingPaymentAmount),
              subtitle: 'Next renewal: Dec 2026',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.info,
              iconBgColor: AppColors.infoBg,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'PAID IN FULL',
                  style: AppTextStyles.badge.copyWith(color: AppColors.success),
                ),
              ),
              onTap: () => context.go('/payments'),
            ),

            // 4. Assigned Trainer
            SummaryCard(
              label: 'Personal Trainer',
              value: member.assignedTrainer,
              subtitle: 'CSCS Coach (Rating 4.9★)',
              icon: Icons.sports_gymnastics_outlined,
              iconColor: AppColors.darkCharcoal,
              iconBgColor: AppColors.scaffoldBackground,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'ACTIVE COACH',
                  style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
                ),
              ),
              onTap: () => context.go('/trainer'),
            ),
          ],
        );
      },
    );
  }
}
