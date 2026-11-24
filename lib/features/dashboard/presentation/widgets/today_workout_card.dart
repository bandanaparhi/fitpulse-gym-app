import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/workout.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/info_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Card previewing today's scheduled workout regime.
class TodayWorkoutCard extends StatelessWidget {
  final Workout? workout;
  final bool isLoading;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const InfoCard(
        title: "Today's Workout",
        icon: Icons.fitness_center_rounded,
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (workout == null) {
      return InfoCard(
        title: "Today's Workout",
        icon: Icons.fitness_center_rounded,
        child: EmptyState(
          icon: Icons.bedtime_outlined,
          title: 'Rest Day',
          message: 'No workouts scheduled for today. Focus on recovery and nutrition!',
          actionLabel: 'Browse Workouts',
          onAction: () => context.go('/workouts'),
        ),
      );
    }

    final item = workout!;

    return InfoCard(
      title: "Today's Workout",
      subtitle: '${item.category} • ${item.durationMinutes} mins • ${item.level}',
      icon: Icons.fitness_center_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.limeAccent.withValues(alpha: 0.2),
          borderRadius: AppRadius.roundedSm,
        ),
        child: Text(
          'TODAY',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.limeAccentDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTextStyles.titleLarge),
          if (item.notes != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.notes!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Exercise preview list
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: item.exercises.take(3).map((ex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.darkCharcoal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          ex.name,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${ex.sets} × ${ex.reps} reps${ex.weightKg != null ? ' @ ${ex.weightKg!.toStringAsFixed(0)}kg' : ''}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Start Workout',
                  icon: Icons.play_arrow_rounded,
                  height: 42,
                  onPressed: () => context.go('/workouts/${item.id}/start'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: 'View Details',
                  icon: Icons.format_list_bulleted_rounded,
                  height: 42,
                  onPressed: () => context.go('/workouts/${item.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
