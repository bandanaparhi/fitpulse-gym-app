import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/gym_class.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';

/// Class Details screen at `/classes/:classId`.
///
/// Displays:
/// - Class title, category, schedule, room, and difficulty
/// - Capacity and spots remaining
/// - Full workout description
/// - Instructor profile & credentials
/// - Live booking status & instant booking CTA with duplicate prevention
class ClassDetailsScreen extends ConsumerWidget {
  final String classId;

  const ClassDetailsScreen({
    super.key,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(singleClassProvider(classId));
    final bookingsAsync = ref.watch(classBookingsProvider);

    return classAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading class details...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Class',
          message: err.toString(),
          onRetry: () => ref.invalidate(singleClassProvider(classId)),
        ),
      ),
      data: (gymClass) {
        if (gymClass == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(title: const Text('Class Details')),
            body: Center(
              child: EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Class Not Found',
                message: 'No studio class matches identifier "$classId".',
                actionLabel: 'Back to Classes',
                onAction: () => context.go('/classes'),
              ),
            ),
          );
        }

        final bookings = bookingsAsync.value ?? [];
        final existingBooking = bookings.cast<dynamic>().firstWhere(
              (b) => b.classId == gymClass.id && b.status == 'Confirmed',
              orElse: () => null,
            );
        final isBooked = existingBooking != null;
        final isFull = gymClass.isFull;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Classes',
              onPressed: () => context.go('/classes'),
            ),
            title: Text(
              gymClass.title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              border: const Border(
                top: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: SafeArea(
              child: isBooked
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Already Booked — View Reservation Pass',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.go('/classes/bookings'),
                    )
                  : isFull
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardSubtleBg,
                            foregroundColor: AppColors.textMuted,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: null,
                          child: const Text('Class Full (No Spots Available)'),
                        )
                      : PrimaryButton(
                          label: 'Confirm & Reserve Spot',
                          icon: Icons.bookmark_add_outlined,
                          onPressed: () async {
                            final success = await ref
                                .read(classBookingsProvider.notifier)
                                .bookClass(gymClass.id);
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.darkCharcoal,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      'Reserved! Your spot in "${gymClass.title}" is confirmed.',
                                    ),
                                    action: SnackBarAction(
                                      label: 'View Pass',
                                      textColor: AppColors.limeAccent,
                                      onPressed: () =>
                                          context.go('/classes/bookings'),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      'Unable to complete booking.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Class Header Meta Card
                _buildMetaCard(gymClass, isBooked),

                const SizedBox(height: AppSpacing.xl),

                // 2. Class Overview & Description Card
                _buildDescriptionCard(gymClass),

                const SizedBox(height: AppSpacing.xl),

                // 3. Instructor Details Card
                _buildInstructorCard(gymClass),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaCard(GymClass gymClass, bool isBooked) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  gymClass.category.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  gymClass.difficulty,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (isBooked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RESERVED',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            gymClass.title,
            style: AppTextStyles.h2,
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Schedule & Location Grid
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _buildDetailTile(
                icon: Icons.calendar_today_rounded,
                label: 'Scheduled Date',
                value: AppFormatters.formatDate(gymClass.startTime),
              ),
              _buildDetailTile(
                icon: Icons.schedule_rounded,
                label: 'Time & Duration',
                value:
                    '${AppFormatters.formatTime(gymClass.startTime)} (${gymClass.durationMinutes} min)',
              ),
              _buildDetailTile(
                icon: Icons.location_on_outlined,
                label: 'Studio Location',
                value: gymClass.room,
              ),
              _buildDetailTile(
                icon: Icons.groups_rounded,
                label: 'Seat Availability',
                value:
                    '${gymClass.spotsRemaining} spots available (${gymClass.bookedCount}/${gymClass.capacity} booked)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.limeAccentDark),
        const SizedBox(width: AppSpacing.xs + 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(GymClass gymClass) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: AppColors.darkCharcoal,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Class Description & Experience',
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            gymClass.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCard(GymClass gymClass) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppColors.darkCharcoal,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Instructor Details',
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.darkCharcoal,
                child: Text(
                  gymClass.trainerName.split(' ').map((n) => n[0]).take(2).join(),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gymClass.trainerName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Certified Group Fitness Instructor',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      gymClass.instructorBio,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
