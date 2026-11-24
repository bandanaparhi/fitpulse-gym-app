import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/class_booking.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Card showing the member's next upcoming class reservation.
class UpcomingClassCard extends StatelessWidget {
  final ClassBooking? booking;
  final bool isLoading;

  const UpcomingClassCard({
    super.key,
    required this.booking,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const InfoCard(
        title: 'Upcoming Class',
        icon: Icons.calendar_month_rounded,
        child: SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (booking == null) {
      return InfoCard(
        title: 'Upcoming Class',
        icon: Icons.calendar_month_rounded,
        child: EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No Class Booked',
          message: 'Join group Yoga, Spin, HIIT or CrossFit classes this week.',
          actionLabel: 'Browse Class Schedule',
          onAction: () => context.go('/classes'),
        ),
      );
    }

    final item = booking!;

    return InfoCard(
      title: 'Upcoming Class',
      icon: Icons.calendar_month_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: AppRadius.roundedSm,
        ),
        child: Text(
          item.status.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TODAY',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '6 PM',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.className,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instructor: Sara Jenkins • Studio A (Cycle)',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Starts at ${AppFormatters.formatTime(item.classStartTime)} (in ~4 hours)',
                      style: AppTextStyles.caption.copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'View Booking & QR Pass',
                  icon: Icons.qr_code_rounded,
                  height: 38,
                  onPressed: () => context.go('/classes/bookings'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.textPrimary, size: 20),
                tooltip: 'Class Details',
                onPressed: () => context.go('/classes/${item.classId}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
