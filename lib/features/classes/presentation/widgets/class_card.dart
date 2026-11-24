import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/gym_class.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Card representing a single group fitness class in the listing.
class ClassCard extends StatelessWidget {
  final GymClass gymClass;
  final bool isBookedByMember;
  final VoidCallback onBook;

  const ClassCard({
    super.key,
    required this.gymClass,
    required this.isBookedByMember,
    required this.onBook,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'spin':
        return AppColors.warning;
      case 'yoga':
        return AppColors.info;
      case 'crossfit':
        return AppColors.error;
      case 'boxing':
        return AppColors.darkCharcoal;
      case 'zumba':
        return AppColors.limeAccentDark;
      default:
        return AppColors.limeAccentDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(gymClass.category);
    final spotsLeft = gymClass.spotsRemaining;
    final isFull = gymClass.isFull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isBookedByMember
              ? AppColors.limeAccentDark.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge, booked indicator, and spots remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      gymClass.category.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  if (isBookedByMember) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'BOOKED',
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
                ],
              ),
              // Spots left indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isFull
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isFull
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  isFull ? 'CLASS FULL' : '$spotsLeft spots left',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFull ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Class Title
          Text(
            gymClass.title,
            style: AppTextStyles.titleLarge,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Instructor & Room Info
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Instructor: ${gymClass.trainerName}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gymClass.room,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Schedule Details Row
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.darkCharcoal,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${AppFormatters.formatShortDate(gymClass.startTime)} • ${AppFormatters.formatTime(gymClass.startTime)} (${gymClass.durationMinutes} min)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () => context.go('/classes/${gymClass.id}'),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: isBookedByMember
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
                          ),
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Reserved'),
                        onPressed: () => context.go('/classes/bookings'),
                      )
                    : isFull
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cardSubtleBg,
                              foregroundColor: AppColors.textMuted,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: null,
                            child: const Text('Class Full'),
                          )
                        : PrimaryButton(
                            label: 'Book Class',
                            icon: Icons.bookmark_add_outlined,
                            onPressed: onBook,
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
