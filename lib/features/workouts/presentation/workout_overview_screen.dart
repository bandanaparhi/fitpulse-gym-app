import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/workout.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/assigned_plan_card.dart';
import 'widgets/weekly_schedule_view.dart';
import 'widgets/workout_history_card.dart';

/// Workout Overview screen at `/workouts`.
///
/// Displays:
/// - Assigned workout plan & assigned trainer
/// - Weekly workout schedule & training days
/// - Assigned workout routines (WK-01, WK-02) with start & detail actions
/// - Completed workouts history log
class WorkoutOverviewScreen extends ConsumerWidget {
  const WorkoutOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final workoutsAsync = ref.watch(workoutListProvider);
    final completedAsync = ref.watch(completedWorkoutsProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading workout plans...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Workouts',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(currentMemberProvider);
            ref.invalidate(workoutListProvider);
          },
        ),
      ),
      data: (member) {
        return workoutsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: LoadingIndicator(message: 'Loading workout routines...'),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: ErrorState(
              title: 'Unable to Load Workout Routines',
              message: err.toString(),
              onRetry: () {
                ref.invalidate(workoutListProvider);
              },
            ),
          ),
          data: (workouts) {
            final completedList = completedAsync.value ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const PageHeader(
                    title: 'Workouts & Training',
                    subtitle:
                        'Review your personalized split, weekly training schedule, and track workout performance.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Assigned Workout Plan Banner
                  AssignedPlanCard(
                    trainerName: member.assignedTrainer,
                    primaryWorkout: workouts.isNotEmpty ? workouts.first : null,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. Assigned Workout Routines Section
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.darkCharcoal,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'Assigned Workout Routines',
                        style: AppTextStyles.h3,
                      ),
                      const Spacer(),
                      Text(
                        '${workouts.length} Routines',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Workouts Grid (WK-01 and WK-02)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 768;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: workouts.map((w) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: w == workouts.last ? 0 : AppSpacing.md,
                                ),
                                child: _buildWorkoutCard(context, w),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        return Column(
                          children: workouts.map((w) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildWorkoutCard(context, w),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Weekly Schedule (Training Days vs Rest Days)
                  WeeklyScheduleView(workouts: workouts),

                  const SizedBox(height: AppSpacing.xl),

                  // 4. Completed Workouts History
                  WorkoutHistoryCard(completedWorkouts: completedList),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
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
          // Category and duration row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
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
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.durationMinutes} min',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Workout Title
          Text(
            workout.title,
            style: AppTextStyles.titleLarge,
          ),

          if (workout.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              workout.notes!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Exercise preview list
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workout.totalExercises} Exercises in routine:',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...workout.exercises.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_right_rounded,
                          size: 16,
                          color: AppColors.limeAccentDark,
                        ),
                        Expanded(
                          child: Text(
                            '${e.name} (${e.sets}×${e.reps})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm + 2,
                    ),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () {
                    context.go('/workouts/${workout.id}');
                  },
                  child: const Text('View Routine'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    context.go('/workouts/${workout.id}/start');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
