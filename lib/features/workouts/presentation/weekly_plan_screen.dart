import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/fitness_profile.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/repositories/workout_planner_engine.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'widgets/training_safety_banner.dart';

/// Weekly Training Plan screen at `/workouts/weekly-plan`.
///
/// Displays the member's personalized 7-day split, plan metadata, quick
/// adjustment controls, per-day workout/rest cards with exercise previews,
/// exercise swap & details links, and progression/recovery guidance.
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  bool _isRegenerating = false;

  void _navigateTo(String route) {
    if (GoRouter.maybeOf(context) != null) {
      context.go(route);
    }
  }

  Future<void> _regeneratePlan() async {
    setState(() => _isRegenerating = true);
    try {
      await ref.read(activeWorkoutPlanProvider.notifier).regenerateFromProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weekly workout plan regenerated from your profile.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not regenerate plan: $err'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  Future<void> _openSwapDialog({
    required WorkoutPlan plan,
    required WorkoutSession session,
    required int exerciseIndex,
    required ExerciseDetail exercise,
    required FitnessProfile? profile,
  }) async {
    final alternatives =
        WorkoutPlannerEngine.findAlternatives(exercise, profile: profile);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.limeAccentDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Swap "${exercise.name}"',
                  style: AppTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: alternatives.isEmpty
                ? const Text(
                    'No compatible alternative exercises were found for your current equipment setup. You can update available equipment in your Fitness Profile.',
                    style: AppTextStyles.bodyMedium,
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose a compatible alternative for ${session.title}:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...alternatives.map((alt) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: InkWell(
                              borderRadius: AppRadius.roundedMd,
                              onTap: () async {
                                Navigator.of(dialogContext).pop();
                                await _applySwap(
                                  plan: plan,
                                  session: session,
                                  exerciseIndex: exerciseIndex,
                                  oldExercise: exercise,
                                  newExercise: alt,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSubtleBg,
                                  borderRadius: AppRadius.roundedMd,
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alt.name,
                                            style: AppTextStyles.titleMedium,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${alt.targetMuscles} • ${alt.equipment} • ${alt.prescriptionSummary}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.limeAccentDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applySwap({
    required WorkoutPlan plan,
    required WorkoutSession session,
    required int exerciseIndex,
    required ExerciseDetail oldExercise,
    required ExerciseDetail newExercise,
  }) async {
    final updatedExercises = List<ExerciseDetail>.from(session.mainExercises);
    updatedExercises[exerciseIndex] = newExercise;

    final updatedSession = session.copyWith(mainExercises: updatedExercises);
    final updatedSessions = plan.sessions
        .map((s) => s.id == session.id ? updatedSession : s)
        .toList();
    final updatedPlan = plan.copyWith(
      sessions: updatedSessions,
      isSampleData: false,
    );

    await ref.read(activeWorkoutPlanProvider.notifier).saveUpdatedPlan(updatedPlan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swapped ${oldExercise.name} with ${newExercise.name}.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: planAsync.when(
        loading: () => const LoadingIndicator(
          message: 'Loading your personalized weekly plan...',
        ),
        error: (err, _) => ErrorState(
          title: 'Unable to Load Weekly Plan',
          message: err.toString(),
          onRetry: () => ref.invalidate(activeWorkoutPlanProvider),
        ),
        data: (plan) {
          final hasMedicalConcern = (profile?.hasMedicalClearanceNotice ?? false) ||
              ((profile?.injuriesOrConcerns ?? '').trim().isNotEmpty);
          final schedule = List<WorkoutPlanDay>.from(plan.weekSchedule)
            ..sort((a, b) => a.weekdayIndex.compareTo(b.weekdayIndex));
          final todayWeekday = DateTime.now().weekday;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final isWide = constraints.maxWidth >= 960;
              final pagePadding = isCompact ? AppSpacing.md : AppSpacing.lg;

              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'My Weekly Plan',
                      subtitle:
                          'Structured 7-day training split balanced with active recovery and rest days.',
                    ),
                    const PlannerNavStrip(currentPath: '/workouts/weekly-plan'),
                    const SizedBox(height: AppSpacing.lg),

                    // 1. Plan Header Hero Banner
                    _PlanHeaderBanner(plan: plan),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Quick Adjustment Strip
                    _QuickAdjustmentStrip(
                      isRegenerating: _isRegenerating,
                      onEditProfile: () => _navigateTo('/workouts/profile'),
                      onRegenerate: _regeneratePlan,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. 7-Day Schedule Cards
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_view_week_rounded,
                          size: 20,
                          color: AppColors.darkCharcoal,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            '7-Day Schedule (Monday – Sunday)',
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (schedule.isEmpty)
                      EmptyState(
                        icon: Icons.event_busy_outlined,
                        title: 'No Schedule Generated Yet',
                        message:
                            'Complete your Fitness Profile to generate a tailored weekly training split.',
                        actionLabel: 'Set Up Fitness Profile',
                        onAction: () => _navigateTo('/workouts/profile'),
                      )
                    else if (isWide)
                      _buildTwoColumnSchedule(
                        plan: plan,
                        schedule: schedule,
                        todayWeekday: todayWeekday,
                        profile: profile,
                      )
                    else
                      Column(
                        children: schedule.map((day) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _DayScheduleCard(
                              plan: plan,
                              day: day,
                              session: plan.sessionById(day.sessionId),
                              isToday: day.weekdayIndex == todayWeekday,
                              onStartWorkout: (sessionId) => _navigateTo(
                                '/workouts/session/active/$sessionId',
                              ),
                              onExerciseDetails: (exId, sessionId) =>
                                  _navigateTo(
                                '/workouts/exercise/$exId?sessionId=$sessionId',
                              ),
                              onSwapExercise: (session, idx, ex) =>
                                  _openSwapDialog(
                                plan: plan,
                                session: session,
                                exerciseIndex: idx,
                                exercise: ex,
                                profile: profile,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // 4. Progression & Recovery Guidance Card
                    InfoCard(
                      title: 'Progression & Recovery Guidance',
                      subtitle:
                          'Built-in safeguards to support sustainable adaptation.',
                      icon: Icons.trending_up_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GuidanceItem(
                            icon: Icons.arrow_upward_rounded,
                            iconColor: AppColors.limeAccentDark,
                            title: 'Safe Progression',
                            body: plan.progressionGuidance,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _GuidanceItem(
                            icon: Icons.bedtime_outlined,
                            iconColor: AppColors.info,
                            title: 'Recovery & Deloads',
                            body: plan.recoveryGuidance,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    TrainingSafetyBanner(
                      hasMedicalConcern: hasMedicalConcern,
                      isSampleData: plan.isSampleData,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTwoColumnSchedule({
    required WorkoutPlan plan,
    required List<WorkoutPlanDay> schedule,
    required int todayWeekday,
    required FitnessProfile? profile,
  }) {
    final rows = <Widget>[];
    for (int i = 0; i < schedule.length; i += 2) {
      final first = schedule[i];
      final second = i + 1 < schedule.length ? schedule[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DayScheduleCard(
                  plan: plan,
                  day: first,
                  session: plan.sessionById(first.sessionId),
                  isToday: first.weekdayIndex == todayWeekday,
                  onStartWorkout: (sessionId) =>
                      _navigateTo('/workouts/session/active/$sessionId'),
                  onExerciseDetails: (exId, sessionId) =>
                      _navigateTo('/workouts/exercise/$exId?sessionId=$sessionId'),
                  onSwapExercise: (session, idx, ex) => _openSwapDialog(
                    plan: plan,
                    session: session,
                    exerciseIndex: idx,
                    exercise: ex,
                    profile: profile,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: second != null
                    ? _DayScheduleCard(
                        plan: plan,
                        day: second,
                        session: plan.sessionById(second.sessionId),
                        isToday: second.weekdayIndex == todayWeekday,
                        onStartWorkout: (sessionId) =>
                            _navigateTo('/workouts/session/active/$sessionId'),
                        onExerciseDetails: (exId, sessionId) => _navigateTo(
                          '/workouts/exercise/$exId?sessionId=$sessionId',
                        ),
                        onSwapExercise: (session, idx, ex) => _openSwapDialog(
                          plan: plan,
                          session: session,
                          exerciseIndex: idx,
                          exercise: ex,
                          profile: profile,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _PlanHeaderBanner extends StatelessWidget {
  final WorkoutPlan plan;

  const _PlanHeaderBanner({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'ACTIVE TRAINING PLAN',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              if (plan.isSampleData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkElevated,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Text(
                    'SAMPLE DATA',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(plan.title, style: AppTextStyles.h2Dark),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan.splitSummary,
            style: AppTextStyles.bodyMediumDark,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DarkPill(icon: Icons.bar_chart_rounded, label: plan.level),
              _DarkPill(icon: Icons.flag_outlined, label: plan.goal),
              _DarkPill(
                icon: plan.location == 'Gym'
                    ? Icons.apartment_rounded
                    : Icons.home_outlined,
                label: plan.location,
              ),
              _DarkPill(
                icon: Icons.event_available_outlined,
                label: '${plan.trainingDaysPerWeek} Days / Week',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        borderRadius: AppRadius.roundedFull,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdjustmentStrip extends StatelessWidget {
  final bool isRegenerating;
  final VoidCallback onEditProfile;
  final VoidCallback onRegenerate;

  const _QuickAdjustmentStrip({
    required this.isRegenerating,
    required this.onEditProfile,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          final actions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SecondaryButton(
                label: 'Edit Fitness Profile',
                icon: Icons.tune_rounded,
                height: 42,
                onPressed: onEditProfile,
              ),
              PrimaryButton(
                label: 'Regenerate Plan',
                icon: Icons.refresh_rounded,
                height: 42,
                isLoading: isRegenerating,
                onPressed: onRegenerate,
              ),
            ],
          );

          final info = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  size: 18,
                  color: AppColors.limeAccentDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need to adjust days, equipment, or goals?',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                    ),
                    Text(
                      'Update your profile or refresh your split anytime.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: AppSpacing.md),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final WorkoutPlan plan;
  final WorkoutPlanDay day;
  final WorkoutSession? session;
  final bool isToday;
  final ValueChanged<String> onStartWorkout;
  final void Function(String exerciseId, String sessionId) onExerciseDetails;
  final void Function(
    WorkoutSession session,
    int index,
    ExerciseDetail exercise,
  ) onSwapExercise;

  const _DayScheduleCard({
    required this.plan,
    required this.day,
    required this.session,
    required this.isToday,
    required this.onStartWorkout,
    required this.onExerciseDetails,
    required this.onSwapExercise,
  });

  @override
  Widget build(BuildContext context) {
    final activeSession = session;
    final isRest = day.isRestDay || activeSession == null;

    return Container(
      decoration: BoxDecoration(
        color: isRest ? AppColors.cardSubtleBg : AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(
          color: isToday ? AppColors.limeAccentDark : AppColors.borderSubtle,
          width: isToday ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Day name + badges
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                day.dayName,
                style: AppTextStyles.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRest
                      ? AppColors.infoBg
                      : AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  isRest ? 'REST & RECOVERY' : 'TRAINING',
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 10,
                    color:
                        isRest ? AppColors.info : AppColors.limeAccentDark,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCharcoal,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'TODAY',
                    style: AppTextStyles.badge.copyWith(
                      fontSize: 10,
                      color: AppColors.limeAccent,
                    ),
                  ),
                ),
              if (!isRest && day.estimatedMinutes > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${day.estimatedMinutes} min',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            activeSession == null || day.isRestDay
                ? day.sessionLabel
                : activeSession.title,
            style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            isRest
                ? (day.focusSummary.isNotEmpty
                    ? day.focusSummary
                    : 'Gentle walking, mobility, sleep & hydration')
                : day.focusSummary,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          if (activeSession == null || day.isRestDay) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.self_improvement_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Gentle walking, mobility, sleep & hydration support tissue recovery between training sessions.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${activeSession.warmUp.length} warm-up • ${activeSession.mainExercises.length} main exercises • ${activeSession.coolDown.length} cool-down',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Exercise preview list
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  for (int idx = 0; idx < activeSession.mainExercises.length; idx++)
                    _ExercisePreviewRow(
                      exercise: activeSession.mainExercises[idx],
                      showDivider: idx < activeSession.mainExercises.length - 1,
                      onDetails: () => onExerciseDetails(
                        activeSession.mainExercises[idx].id,
                        activeSession.id,
                      ),
                      onSwap: () => onSwapExercise(
                        activeSession,
                        idx,
                        activeSession.mainExercises[idx],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            PrimaryButton(
              label: 'Start Workout',
              icon: Icons.play_arrow_rounded,
              isFullWidth: true,
              height: 44,
              onPressed: () => onStartWorkout(activeSession.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  final ExerciseDetail exercise;
  final bool showDivider;
  final VoidCallback onDetails;
  final VoidCallback onSwap;

  const _ExercisePreviewRow({
    required this.exercise,
    required this.showDivider,
    required this.onDetails,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${exercise.prescriptionSummary} • ${exercise.equipment}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onSwap,
            child: Text(
              'Swap',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.limeAccentDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onDetails,
            child: Text(
              'Details',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.darkCharcoal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _GuidanceItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.roundedSm,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
