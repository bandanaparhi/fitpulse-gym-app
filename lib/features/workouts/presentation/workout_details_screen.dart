import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';

/// Workout Details screen at `/workouts/:workoutId`.
///
/// Displays:
/// - Workout name and category
/// - Exercise list with sets and repetitions
/// - Weight, duration, and rest time
/// - Step-by-step exercise instructions
/// - Start workout CTA
class WorkoutDetailsScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailsScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(singleWorkoutProvider(workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading workout details...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Workout',
          message: err.toString(),
          onRetry: () => ref.invalidate(singleWorkoutProvider(workoutId)),
        ),
      ),
      data: (workout) {
        if (workout == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(
              title: const Text('Workout Details'),
              backgroundColor: AppColors.cardBackground,
            ),
            body: Center(
              child: EmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'Workout Not Found',
                message: 'No workout matches identifier "$workoutId".',
                actionLabel: 'Back to Workouts',
                onAction: () => context.go('/workouts'),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Workouts',
              onPressed: () => context.go('/workouts'),
            ),
            title: Text(
              workout.title,
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
              child: PrimaryButton(
                label: 'Start Live Workout',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  context.go('/workouts/${workout.id}/start');
                },
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Card
                _buildHeaderCard(workout),

                const SizedBox(height: AppSpacing.xl),

                // Exercise List Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Exercise Breakdown (${workout.totalExercises})',
                      style: AppTextStyles.h3,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Target Form Cues',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.limeAccentDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Exercises List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workout.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = workout.exercises[index];
                    return _buildExerciseCard(exercise, index + 1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(Workout workout) {
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
                  workout.category.toUpperCase(),
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
                  workout.level,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            workout.title,
            style: AppTextStyles.h2,
          ),
          if (workout.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              workout.notes!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _buildHeaderMetric(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: '${workout.durationMinutes} mins',
              ),
              _buildHeaderMetric(
                icon: Icons.fitness_center_rounded,
                label: 'Exercises',
                value: '${workout.totalExercises} exercises',
              ),
              _buildHeaderMetric(
                icon: Icons.repeat_rounded,
                label: 'Total Sets',
                value:
                    '${workout.exercises.fold<int>(0, (sum, e) => sum + e.sets)} sets',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index, Exercise Name, and Target Muscle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: AppTextStyles.caption.copyWith(
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
                      exercise.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${exercise.targetMuscle}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Sets, Reps, Weight, and Rest pills
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildExercisePill(
                icon: Icons.repeat_rounded,
                label: 'Volume',
                value: '${exercise.sets} Sets × ${exercise.reps} Reps',
              ),
              if (exercise.weightKg != null)
                _buildExercisePill(
                  icon: Icons.fitness_center_rounded,
                  label: 'Recommended Weight',
                  value: '${exercise.weightKg!.toStringAsFixed(1)} kg',
                ),
              _buildExercisePill(
                icon: Icons.timer_outlined,
                label: 'Rest Period',
                value: '${exercise.restSeconds}s rest',
              ),
            ],
          ),

          // Exercise Instructions
          if (exercise.instructions != null &&
              exercise.instructions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Instructions:',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exercise.instructions!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisePill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
