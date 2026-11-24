import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/diet_plan.dart';

/// Assigned Diet Plan Header Card displaying plan meta, trainer, dates, and notes.
class DietPlanHeaderCard extends StatelessWidget {
  final DietPlan plan;

  const DietPlanHeaderCard({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge & Assigned Professional
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'ASSIGNED NUTRITION PLAN',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.limeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      plan.assignedProfessional,
                      style: AppTextStyles.bodyMediumDark.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Plan Title
          Text(
            plan.title,
            style: AppTextStyles.h2Dark,
          ),

          const SizedBox(height: AppSpacing.xs),

          // Goal & Dates Row
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 14,
                    color: AppColors.limeAccent,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Goal: ${plan.goal}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textOnDarkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Started: ${AppFormatters.formatShortDate(plan.startDate)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.update_rounded,
                    size: 14,
                    color: AppColors.textOnDarkMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${AppFormatters.formatShortDate(plan.lastUpdated)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (plan.trainerGeneralNotes != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.limeAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trainer\'s Nutrition Guidance:',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.limeAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.trainerGeneralNotes!,
                        style: AppTextStyles.bodyMediumDark.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
