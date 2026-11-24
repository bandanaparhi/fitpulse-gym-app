import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/workout.dart';

/// Assigned workout plan banner card.
class AssignedPlanCard extends StatelessWidget {
  final String trainerName;
  final Workout? primaryWorkout;

  const AssignedPlanCard({
    super.key,
    required this.trainerName,
    this.primaryWorkout,
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
          // Plan Header Badge & Trainer Info
          Row(
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
                  'CURRENT ASSIGNED PLAN',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.limeAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Coach $trainerName',
                style: AppTextStyles.bodyMediumDark.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Plan Title
          const Text(
            'Hypertrophy & Functional Conditioning',
            style: AppTextStyles.h2Dark,
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Structured 4-day progressive overload split focusing on explosive compound movements, hypertrophic volume, and metabolic conditioning.',
            style: AppTextStyles.bodyMediumDark.copyWith(
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Plan Key Attributes Row
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _buildFeaturePill(
                icon: Icons.calendar_today_rounded,
                label: '4 Days / Week',
              ),
              _buildFeaturePill(
                icon: Icons.fitness_center_rounded,
                label: 'Intermediate Level',
              ),
              _buildFeaturePill(
                icon: Icons.timer_outlined,
                label: '55 - 60 Min / Session',
              ),
              _buildFeaturePill(
                icon: Icons.trending_up_rounded,
                label: 'Progressive Overload',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Action row
          Row(
            children: [
              if (primaryWorkout != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.limeAccent,
                      side: const BorderSide(color: AppColors.limeAccent),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + 4,
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      'Start Today\'s Workout (${primaryWorkout!.title.split(' ').take(2).join(' ')})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      context.go('/workouts/${primaryWorkout!.id}');
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.limeAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
