import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_goal.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import 'create_fitness_goal_modal.dart';

/// Card displaying personal fitness goals with progress tracking and creation.
class FitnessGoalsCard extends StatelessWidget {
  final List<FitnessGoal> goals;
  final bool isMetric;
  final ValueChanged<FitnessGoal> onSaveGoal;
  final ValueChanged<String> onDeleteGoal;

  const FitnessGoalsCard({
    super.key,
    required this.goals,
    required this.isMetric,
    required this.onSaveGoal,
    required this.onDeleteGoal,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.flag_rounded,
                    color: AppColors.darkCharcoal,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Personal Fitness Goals',
                    style: AppTextStyles.h3,
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCharcoal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Set Goal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  CreateFitnessGoalModal.show(
                    context,
                    isMetric: isMetric,
                    onSave: onSaveGoal,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No fitness goals set yet. Click "Set Goal" to define your targets.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: goals.map((goal) => _buildGoalItem(context, goal)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, FitnessGoal goal) {
    final percent = (goal.progressPercentage * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    Text(
                      goal.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        goal.metricType,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.limeAccentDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Delete Goal',
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Delete Fitness Goal?',
                    message:
                        'Are you sure you want to remove the goal "${goal.title}"?',
                    confirmLabel: 'Delete Goal',
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    onDeleteGoal(goal.id);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Values trajectory: Start -> Current -> Target
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            runSpacing: 2,
            children: [
              Text(
                'Start: ${goal.startValue} ${goal.unit}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Current: ${goal.currentValue} ${goal.unit}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              Text(
                'Target: ${goal.targetValue} ${goal.unit}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.limeAccentDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Progress Bar
          LinearProgressIndicator(
            value: goal.progressPercentage,
            backgroundColor: AppColors.borderSubtle,
            color: AppColors.limeAccentDark,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Progress & Days Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent% Achieved',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.limeAccentDark,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Deadline: ${AppFormatters.formatShortDate(goal.targetDate)} (${goal.daysRemaining} days left)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
