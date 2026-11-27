import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_goal.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import 'create_fitness_goal_modal.dart';

/// Card displaying personal fitness goals compilation, overall completion rate,
/// progress updates, and goal creation.
class FitnessGoalsCard extends StatelessWidget {
  final List<FitnessGoal> goals;
  final bool isMetric;
  final String? primaryProfileGoal;
  final ValueChanged<FitnessGoal> onSaveGoal;
  final ValueChanged<String> onDeleteGoal;

  const FitnessGoalsCard({
    super.key,
    required this.goals,
    required this.isMetric,
    this.primaryProfileGoal,
    required this.onSaveGoal,
    required this.onDeleteGoal,
  });

  Future<void> _openUpdateProgressDialog(
    BuildContext context,
    FitnessGoal goal,
  ) async {
    final controller =
        TextEditingController(text: goal.currentValue.toString());
    final updatedVal = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update "${goal.title}"', style: AppTextStyles.titleLarge),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Current Value (${goal.unit})',
            helperText: 'Target: ${goal.targetValue} ${goal.unit}',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null) Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Save Progress'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updatedVal == null) return;

    final decreasing = goal.targetValue < goal.startValue;
    final reached = decreasing
        ? updatedVal <= goal.targetValue
        : updatedVal >= goal.targetValue;
    onSaveGoal(
      goal.copyWith(
        currentValue: updatedVal,
        isAchieved: reached,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = goals.where((g) => g.isCompleted).length;
    final activeCount = goals.length - completedCount;
    final overallProgress = goals.isEmpty
        ? 0.0
        : goals.fold<double>(0.0, (s, g) => s + g.progressPercentage) /
            goals.length;
    final overallPercent = (overallProgress * 100).round();

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
                  Flexible(
                    child: Text(
                      'Personal Fitness Goals',
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
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

          // Fitness Goal Compilation Summary Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Fitness Goal Compilation',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (primaryProfileGoal != null &&
                        primaryProfileGoal!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'Primary Goal: $primaryProfileGoal',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Total: ${goals.length}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Completed: $completedCount',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'In Progress: $activeCount',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Overall: $overallPercent%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccentDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: overallProgress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.borderSubtle,
                  color: AppColors.limeAccentDark,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ],
            ),
          ),

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
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Achieved',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
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
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                onPressed: () => _openUpdateProgressDialog(context, goal),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Update Progress',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                ),
                onPressed: () {
                  onSaveGoal(goal.copyWith(isAchieved: !goal.isAchieved));
                },
                icon: Icon(
                  goal.isCompleted
                      ? Icons.replay_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: goal.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.success,
                ),
                label: Text(
                  goal.isCompleted ? 'Reopen Goal' : 'Mark Achieved',
                  style: TextStyle(
                    fontSize: 11,
                    color: goal.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
