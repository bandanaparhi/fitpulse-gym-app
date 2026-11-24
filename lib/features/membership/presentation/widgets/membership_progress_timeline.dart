import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

/// Visual progress timeline showing subscription duration, elapsed time, and days remaining.
class MembershipProgressTimeline extends StatelessWidget {
  final DateTime startDate;
  final DateTime expiryDate;
  final String durationMonths;

  const MembershipProgressTimeline({
    super.key,
    required this.startDate,
    required this.expiryDate,
    required this.durationMonths,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDays = expiryDate.difference(startDate).inDays.clamp(1, 3650);
    final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDays);
    final daysRemaining = expiryDate.difference(now).inDays.clamp(0, totalDays);
    final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MEMBERSHIP TIMELINE',
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: daysRemaining <= 30
                      ? AppColors.warningBg
                      : AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  '$daysRemaining days remaining',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: daysRemaining <= 30 ? AppColors.warning : AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Custom Linear Progress Track
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: AppRadius.roundedFull,
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.limeAccent,
                    borderRadius: AppRadius.roundedFull,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Milestone Dates row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Started', style: AppTextStyles.caption),
                    Text(
                      AppFormatters.formatShortDate(startDate),
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Plan Term', style: AppTextStyles.caption),
                    Text(
                      durationMonths,
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Expires', style: AppTextStyles.caption),
                    Text(
                      AppFormatters.formatShortDate(expiryDate),
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
