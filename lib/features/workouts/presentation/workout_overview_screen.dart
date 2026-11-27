import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../data/models/workout.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/assigned_plan_card.dart';
import 'widgets/training_safety_banner.dart';
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
    final activePlanAsync = ref.watch(activeWorkoutPlanProvider);
    final todaySessionAsync = ref.watch(todaySessionProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);
    final logsAsync = ref.watch(workoutLogsProvider);

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
              padding: AppResponsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const PageHeader(
                    title: 'Workouts & Training',
                    subtitle:
                        'Review your personalized split, weekly training schedule, and track workout performance.',
                  ),

                  // Personalized Planner Quick Navigation & Hub
                  const PlannerNavStrip(currentPath: '/workouts'),
                  const SizedBox(height: AppSpacing.md),

                  _buildPersonalizedPlannerCard(
                    context,
                    activePlanAsync: activePlanAsync,
                    todaySessionAsync: todaySessionAsync,
                    profileAsync: profileAsync,
                    logsAsync: logsAsync,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TrainingSafetyBanner(
                    hasMedicalConcern:
                        profileAsync.value?.hasMedicalClearanceNotice ?? false,
                    isSampleData:
                        activePlanAsync.value?.isSampleData ?? false,
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
                      const Expanded(
                        child: Text(
                          'Assigned Workout Routines',
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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

  Widget _buildPersonalizedPlannerCard(
    BuildContext context, {
    required AsyncValue<dynamic> activePlanAsync,
    required AsyncValue<dynamic> todaySessionAsync,
    required AsyncValue<dynamic> profileAsync,
    required AsyncValue<List<dynamic>> logsAsync,
  }) {
    final plan = activePlanAsync.value;
    final todaySession = todaySessionAsync.value;
    final profile = profileAsync.value;
    final logs = logsAsync.value ?? const [];

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentSessionsCount = logs
        .where((l) => l.isCompleted && l.startedAt.isAfter(weekAgo))
        .length;
    final targetDays = plan?.trainingDaysPerWeek ?? 4;
    final completionRatio =
        targetDays > 0 ? (recentSessionsCount / targetDays).clamp(0.0, 1.0) : 0.0;

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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.limeAccentDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Flexible(
                    child: Text(
                      'Personalized Training Planner',
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
              if (profile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSubtleBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${profile.fitnessLevel} • ${profile.primaryGoal} • ${profile.workoutLocation}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (plan != null)
            Text(
              '${plan.title} — ${plan.splitSummary}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Weekly progress indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Weekly Plan Progress',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$recentSessionsCount / $targetDays sessions',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.limeAccentDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: completionRatio,
                        minHeight: 8,
                        backgroundColor: AppColors.scaffoldBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.limeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Today's session highlight or rest day preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: todaySession != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Today: ${todaySession.title}',
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            '• ${todaySession.estimatedMinutes} min • ${todaySession.totalExercises} exercises',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Focus: ${todaySession.focus}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today is a Scheduled Rest & Recovery Day',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prioritize gentle mobility, hydration, and sleep — or preview any planned session in Today\'s Workout.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick actions
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (todaySession != null)
                PrimaryButton(
                  label: 'Start Workout',
                  icon: Icons.play_arrow_rounded,
                  height: 42,
                  onPressed: () =>
                      context.go('/workouts/session/active/${todaySession.id}'),
                )
              else
                PrimaryButton(
                  label: 'Open Today\'s Workout',
                  icon: Icons.today_rounded,
                  height: 42,
                  onPressed: () => context.go('/workouts/today'),
                ),
              OutlinedButton.icon(
                onPressed: () => RestTimerDialog.show(context),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Rest Timer'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/workouts/weekly-plan'),
                icon: const Icon(Icons.calendar_view_week_rounded, size: 18),
                label: const Text('Weekly Plan'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/workouts/profile'),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Edit Fitness Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
