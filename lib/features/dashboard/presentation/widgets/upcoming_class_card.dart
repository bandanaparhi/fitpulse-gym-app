import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../data/models/class_booking.dart';

/// Card showing the member's upcoming class reservation conforming to
/// both Mobile and Desktop design direction screenshots.
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
    final isMobile = AppResponsive.isMobile(context);

    if (isLoading) {
      return Container(
        height: isMobile ? 76 : 140,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: isMobile ? AppRadius.roundedLg : AppRadius.roundedLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (isMobile) {
      return _buildMobileCard(context);
    }
    return _buildDesktopCard(context);
  }

  Widget _buildMobileCard(BuildContext context) {
    final hasBooking = booking != null;

    return InkWell(
      onTap: () => context.go(hasBooking ? '/classes/bookings' : '/classes'),
      borderRadius: AppRadius.roundedLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lightGreenSurface,
                borderRadius: AppRadius.roundedMd,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.limeAccentDark,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Upcoming classes',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBooking ? booking!.className : 'No class booked',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 0,
                    width: 0,
                    child: Text(
                      'Upcoming Class',
                      style: TextStyle(fontSize: 0, color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
            if (hasBooking) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  booking!.status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    final hasBooking = booking != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upcoming Classes',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasBooking) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    booking!.status.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasBooking
                ? booking!.className
                : 'No class booked',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasBooking) ...[
            const SizedBox(height: 2),
            Text(
              'Today at 6:00 PM • Studio A',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => context.go(hasBooking ? '/classes/bookings' : '/classes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightGreenSurface,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              textStyle: AppTextStyles.button.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: Text(hasBooking ? 'View Booking Pass' : 'Browse Classes'),
          ),
          const SizedBox(
            height: 0,
            width: 0,
            child: Text(
              'Upcoming Class',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
