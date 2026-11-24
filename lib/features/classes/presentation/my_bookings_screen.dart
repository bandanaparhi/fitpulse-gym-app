import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/class_booking.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/booking_item_card.dart';

/// Screen displaying the member's class reservations at `/classes/bookings`.
///
/// Features:
/// - Upcoming reservations tab with cancellation capability
/// - Booking history tab (attended & cancelled past sessions)
/// - KPI summary indicators
/// - Empty, loading, and error states
class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCancelBooking(
      BuildContext context, ClassBooking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(classBookingsProvider.notifier)
        .cancelBooking(booking.id);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reservation for "${booking.className}" has been cancelled.',
          ),
          backgroundColor: AppColors.darkCharcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel reservation. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(classBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: bookingsAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(message: 'Loading your reservations...'),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load reservations',
            message: err.toString(),
            onRetry: () => ref.invalidate(classBookingsProvider),
          ),
        ),
        data: (allBookings) {
          final upcomingBookings =
              allBookings.where((b) => b.isUpcoming).toList()
                ..sort((a, b) => a.classStartTime.compareTo(b.classStartTime));

          final historyBookings =
              allBookings.where((b) => !b.isUpcoming).toList()
                ..sort((a, b) => b.classStartTime.compareTo(a.classStartTime));

          final totalAttended =
              allBookings.where((b) => b.status == 'Attended').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: PageHeader(
                        title: 'My Class Bookings',
                        subtitle:
                            'Track your reserved studio spots and view your class attendance history.',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCharcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.fitness_center_outlined, size: 18),
                      label: const Text('Browse Classes'),
                      onPressed: () => context.go('/classes'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // KPI Summaries
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          _buildSummaryCard(
                            label: 'Upcoming Reservations',
                            value: '${upcomingBookings.length}',
                            icon: Icons.calendar_today,
                            color: AppColors.limeAccentDark,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSummaryCard(
                            label: 'Sessions Attended',
                            value: '$totalAttended',
                            icon: Icons.check_circle_outline,
                            color: AppColors.info,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSummaryCard(
                            label: 'Total Bookings Made',
                            value: '${allBookings.length}',
                            icon: Icons.bookmark_outline,
                            color: AppColors.darkCharcoal,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Upcoming Reservations',
                            value: '${upcomingBookings.length}',
                            icon: Icons.calendar_today,
                            color: AppColors.limeAccentDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Sessions Attended',
                            value: '$totalAttended',
                            icon: Icons.check_circle_outline,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Total Bookings Made',
                            value: '${allBookings.length}',
                            icon: Icons.bookmark_outline,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tab Bar
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.darkCharcoal,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.limeAccentDark,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Flexible(
                              child: Text(
                                'Upcoming Reservations',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: upcomingBookings.isNotEmpty
                                    ? AppColors.limeAccentDark
                                    : AppColors.borderSubtle,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${upcomingBookings.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: upcomingBookings.isNotEmpty
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Flexible(
                              child: Text(
                                'Booking History',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.borderSubtle,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${historyBookings.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final selectedIndex = _tabController.index;
                    if (selectedIndex == 0) {
                      // Upcoming Tab
                      if (upcomingBookings.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl,
                          ),
                          child: EmptyState(
                            icon: Icons.event_seat_outlined,
                            title: 'No Upcoming Reservations',
                            message:
                                'You do not have any active class bookings scheduled. Browse our fitness schedule and reserve your spot in advance.',
                            actionLabel: 'Browse Available Classes',
                            onAction: () => context.go('/classes'),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingBookings.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final booking = upcomingBookings[index];
                          return BookingItemCard(
                            booking: booking,
                            onCancel: () =>
                                _handleCancelBooking(context, booking),
                          );
                        },
                      );
                    } else {
                      // History Tab
                      if (historyBookings.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl,
                          ),
                          child: EmptyState(
                            icon: Icons.history_outlined,
                            title: 'No Booking History',
                            message:
                                'You have not attended or cancelled any studio classes yet.',
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyBookings.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final booking = historyBookings[index];
                          return BookingItemCard(
                            booking: booking,
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
