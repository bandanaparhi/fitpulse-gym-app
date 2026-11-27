import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/fitness_profile.dart';
import '../../../data/models/personal_record.dart';
import '../../../data/models/workout_log.dart';
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

/// Today's Scheduled Workout screen at `/workouts/today`.
///
/// Renders today's personalized session (warm-up, main exercises with previous
/// performance & multi-session progression badges, quick exercise swap, and
/// cool-down) or a thoughtful Rest & Recovery view with optional session preview.
class TodayWorkoutScreen extends ConsumerStatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  String? _previewSessionId;

  void _navigateTo(String route) {
    if (GoRouter.maybeOf(context) != null) {
      context.go(route);
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
                  'Replace "${exercise.name}"',
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
                    'No compatible alternatives found for your equipment profile. You can update available equipment in your Fitness Profile.',
                    style: AppTextStyles.bodyMedium,
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a compatible replacement exercise:',
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
        content: Text('Replaced ${oldExercise.name} with ${newExercise.name}.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  WorkoutLog? _findTodayLogForSession(
    List<WorkoutLog> logs,
    String sessionId,
  ) {
    final now = DateTime.now();
    for (final log in logs) {
      final sameDay = log.startedAt.year == now.year &&
          log.startedAt.month == now.month &&
          log.startedAt.day == now.day;
      if (sameDay && log.sessionId == sessionId) {
        return log;
      }
    }
    return null;
  }

  ProgressionSuggestion? _findSuggestion(
    List<ProgressionSuggestion> suggestions,
    String exerciseId,
  ) {
    for (final s in suggestions) {
      if (s.exerciseId == exerciseId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todaySessionProvider);
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final logsAsync = ref.watch(workoutLogsProvider);
    final suggestionsAsync = ref.watch(progressionSuggestionsProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);

    final profile = profileAsync.value;
    final logs = logsAsync.value ?? const <WorkoutLog>[];
    final suggestions =
        suggestionsAsync.value ?? const <ProgressionSuggestion>[];

    final hasMedicalConcern = (profile?.hasMedicalClearanceNotice ?? false) ||
        ((profile?.injuriesOrConcerns ?? '').trim().isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: planAsync.when(
        loading: () => const LoadingIndicator(
          message: 'Loading today\'s training plan...',
        ),
        error: (err, _) => ErrorState(
          title: 'Unable to Load Today\'s Workout',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(activeWorkoutPlanProvider);
            ref.invalidate(todaySessionProvider);
          },
        ),
        data: (plan) {
          return todayAsync.when(
            loading: () => const LoadingIndicator(
              message: 'Checking today\'s schedule...',
            ),
            error: (err, _) => ErrorState(
              title: 'Unable to Load Today\'s Session',
              message: err.toString(),
              onRetry: () => ref.invalidate(todaySessionProvider),
            ),
            data: (scheduledToday) {
              final activeSession = scheduledToday ??
                  (_previewSessionId != null
                      ? plan.sessionById(_previewSessionId)
                      : null);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  final pagePadding = isCompact ? AppSpacing.md : AppSpacing.lg;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageHeader(
                          title: "Today's Workout",
                          subtitle: scheduledToday != null
                              ? 'Scheduled session from your ${plan.level} ${plan.goal} plan.'
                              : 'Scheduled recovery day — prioritize sleep, hydration, and light movement.',
                        ),
                        const PlannerNavStrip(currentPath: '/workouts/today'),
                        const SizedBox(height: AppSpacing.lg),

                        if (scheduledToday == null) ...[
                          _RestDayCard(
                            plan: plan,
                            previewSessionId: _previewSessionId,
                            onPreviewSession: (id) {
                              setState(() => _previewSessionId = id);
                            },
                            onClearPreview: () {
                              setState(() => _previewSessionId = null);
                            },
                            onStartSession: (id) =>
                                _navigateTo('/workouts/session/active/$id'),
                          ),
                          if (activeSession != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: AppRadius.roundedMd,
                                border: Border.all(
                                  color: AppColors.info.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Previewing "${activeSession.title}" on your rest day.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _previewSessionId = null,
                                    ),
                                    child: const Text('Hide Preview'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ..._buildSessionContent(
                              plan: plan,
                              session: activeSession,
                              logs: logs,
                              suggestions: suggestions,
                              profile: profile,
                              isRestPreview: true,
                            ),
                          ],
                        ] else ...[
                          ..._buildSessionContent(
                            plan: plan,
                            session: scheduledToday,
                            logs: logs,
                            suggestions: suggestions,
                            profile: profile,
                            isRestPreview: false,
                          ),
                        ],

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
          );
        },
      ),
    );
  }

  List<Widget> _buildSessionContent({
    required WorkoutPlan plan,
    required WorkoutSession session,
    required List<WorkoutLog> logs,
    required List<ProgressionSuggestion> suggestions,
    required FitnessProfile? profile,
    required bool isRestPreview,
  }) {
    final todayLog = _findTodayLogForSession(logs, session.id);

    return [
      // 1. Dark Hero Card
      _TodayHeroCard(
        session: session,
        todayLog: todayLog,
        isSampleData: plan.isSampleData,
        isRestPreview: isRestPreview,
        onStartWorkout: () =>
            _navigateTo('/workouts/session/active/${session.id}'),
        onOpenRestTimer: () => RestTimerDialog.show(context),
      ),
      const SizedBox(height: AppSpacing.lg),

      // 2. Structured Warm-Up Section
      InfoCard(
        title: 'Warm-Up (5–10 min)',
        subtitle: 'Prepare joints, raise body temperature, and rehearse movement patterns.',
        icon: Icons.wb_sunny_outlined,
        child: session.warmUp.isEmpty
            ? const Text(
                'Perform 5 minutes of brisk walking and light dynamic mobility before your first set.',
                style: AppTextStyles.bodyMedium,
              )
            : Column(
                children: [
                  for (int i = 0; i < session.warmUp.length; i++)
                    _PhaseExerciseTile(
                      exercise: session.warmUp[i],
                      phaseColor: AppColors.warning,
                      showDivider: i < session.warmUp.length - 1,
                      onDetails: () => _navigateTo(
                        '/workouts/exercise/${session.warmUp[i].id}?sessionId=${session.id}',
                      ),
                    ),
                ],
              ),
      ),
      const SizedBox(height: AppSpacing.md),

      // 3. Structured Main Exercises Section
      Row(
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 20,
            color: AppColors.darkCharcoal,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Main Exercises (${session.mainExercises.length})',
              style: AppTextStyles.h3,
            ),
          ),
          Text(
            '${session.totalMainSets} total sets',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),

      if (session.mainExercises.isEmpty)
        const EmptyState(
          icon: Icons.fitness_center_outlined,
          title: 'No Main Exercises',
          message: 'Regenerate your weekly plan from your Fitness Profile to populate exercises.',
        )
      else
        Column(
          children: [
            for (int idx = 0; idx < session.mainExercises.length; idx++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MainExerciseCard(
                  index: idx + 1,
                  exercise: session.mainExercises[idx],
                  suggestion: _findSuggestion(
                    suggestions,
                    session.mainExercises[idx].id,
                  ),
                  onDetails: () => _navigateTo(
                    '/workouts/exercise/${session.mainExercises[idx].id}?sessionId=${session.id}',
                  ),
                  onReplace: () => _openSwapDialog(
                    plan: plan,
                    session: session,
                    exerciseIndex: idx,
                    exercise: session.mainExercises[idx],
                    profile: profile,
                  ),
                ),
              ),
          ],
        ),

      // 4. Structured Cool-Down & Recovery Section
      InfoCard(
        title: 'Cool-Down & Recovery',
        subtitle: 'Bring heart rate down smoothly and reinforce range of motion.',
        icon: Icons.self_improvement_rounded,
        child: session.coolDown.isEmpty
            ? const Text(
                'Walk slowly for 3–5 minutes, stretch comfortably, and rehydrate.',
                style: AppTextStyles.bodyMedium,
              )
            : Column(
                children: [
                  for (int i = 0; i < session.coolDown.length; i++)
                    _PhaseExerciseTile(
                      exercise: session.coolDown[i],
                      phaseColor: AppColors.info,
                      showDivider: i < session.coolDown.length - 1,
                      onDetails: () => _navigateTo(
                        '/workouts/exercise/${session.coolDown[i].id}?sessionId=${session.id}',
                      ),
                    ),
                ],
              ),
      ),

      // 5. Coaching Notes & Session Recovery
      if (session.coachingNotes != null || session.recoveryGuidance != null) ...[
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: 'Session Coaching Notes',
          icon: Icons.notes_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.coachingNotes != null) ...[
                Text(
                  session.coachingNotes!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              if (session.coachingNotes != null &&
                  session.recoveryGuidance != null)
                const SizedBox(height: AppSpacing.sm),
              if (session.recoveryGuidance != null)
                Text(
                  session.recoveryGuidance!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }
}

class _RestDayCard extends StatelessWidget {
  final WorkoutPlan plan;
  final String? previewSessionId;
  final ValueChanged<String> onPreviewSession;
  final VoidCallback onClearPreview;
  final ValueChanged<String> onStartSession;

  const _RestDayCard({
    required this.plan,
    required this.previewSessionId,
    required this.onPreviewSession,
    required this.onClearPreview,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'REST & RECOVERY DAY',
                  style: AppTextStyles.badge.copyWith(color: AppColors.info),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Scheduled Recovery & Adaptation',
                style: AppTextStyles.h2Dark,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                plan.recoveryGuidance.isNotEmpty
                    ? plan.recoveryGuidance
                    : 'Your muscles and nervous system adapt during rest. Enjoy gentle movement, stay hydrated, and aim for 7–9 hours of quality sleep.',
                style: AppTextStyles.bodyMediumDark,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _RecoverySuggestionPill(
                    icon: Icons.water_drop_outlined,
                    label: 'Steady Hydration',
                  ),
                  _RecoverySuggestionPill(
                    icon: Icons.bedtime_outlined,
                    label: '7–9 hrs Sleep',
                  ),
                  _RecoverySuggestionPill(
                    icon: Icons.directions_walk_rounded,
                    label: '15–30 min Easy Walk',
                  ),
                  _RecoverySuggestionPill(
                    icon: Icons.self_improvement_rounded,
                    label: 'Gentle Mobility',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (plan.sessions.isNotEmpty)
          InfoCard(
            title: 'Want to Train or Preview a Session Today?',
            subtitle:
                'Choose any session from your weekly split to preview exercises or start early.',
            icon: Icons.playlist_play_rounded,
            child: Column(
              children: [
                for (int i = 0; i < plan.sessions.length; i++) ...[
                  _RestSessionChoiceTile(
                    session: plan.sessions[i],
                    isPreviewing: previewSessionId == plan.sessions[i].id,
                    onPreview: () {
                      if (previewSessionId == plan.sessions[i].id) {
                        onClearPreview();
                      } else {
                        onPreviewSession(plan.sessions[i].id);
                      }
                    },
                    onStart: () => onStartSession(plan.sessions[i].id),
                  ),
                  if (i < plan.sessions.length - 1)
                    const Divider(color: AppColors.borderSubtle, height: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecoverySuggestionPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecoverySuggestionPill({required this.icon, required this.label});

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

class _RestSessionChoiceTile extends StatelessWidget {
  final WorkoutSession session;
  final bool isPreviewing;
  final VoidCallback onPreview;
  final VoidCallback onStart;

  const _RestSessionChoiceTile({
    required this.session,
    required this.isPreviewing,
    required this.onPreview,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 2),
            Text(
              '${session.focus} • ~${session.estimatedMinutes} min • ${session.totalExercises} exercises',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            OutlinedButton(
              onPressed: onPreview,
              child: Text(isPreviewing ? 'Hide Preview' : 'Preview'),
            ),
            PrimaryButton(
              label: 'Start',
              icon: Icons.play_arrow_rounded,
              height: 40,
              onPressed: onStart,
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              info,
              const SizedBox(height: AppSpacing.sm),
              buttons,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: AppSpacing.md),
            buttons,
          ],
        );
      },
    );
  }
}

class _TodayHeroCard extends StatelessWidget {
  final WorkoutSession session;
  final WorkoutLog? todayLog;
  final bool isSampleData;
  final bool isRestPreview;
  final VoidCallback onStartWorkout;
  final VoidCallback onOpenRestTimer;

  const _TodayHeroCard({
    required this.session,
    required this.todayLog,
    required this.isSampleData,
    required this.isRestPreview,
    required this.onStartWorkout,
    required this.onOpenRestTimer,
  });

  @override
  Widget build(BuildContext context) {
    final totalSets = session.totalMainSets > 0 ? session.totalMainSets : 1;
    final completedSets = todayLog?.completedSets ?? 0;
    final progress = (completedSets / totalSets).clamp(0.0, 1.0);
    final isDoneToday = todayLog != null &&
        todayLog!.isCompleted &&
        !todayLog!.stoppedDueToDiscomfort;

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
                  isRestPreview ? 'SESSION PREVIEW' : "TODAY'S SESSION",
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              if (isDoneToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'COMPLETED TODAY',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (todayLog != null && todayLog!.stoppedDueToDiscomfort)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'STOPPED FOR DISCOMFORT',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              if (isSampleData)
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
          Text(session.title, style: AppTextStyles.h2Dark),
          const SizedBox(height: AppSpacing.xs),
          Text(session.focus, style: AppTextStyles.bodyMediumDark),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroPill(
                icon: Icons.timer_outlined,
                label: '~${session.estimatedMinutes} min',
              ),
              _HeroPill(
                icon: Icons.bar_chart_rounded,
                label: session.level,
              ),
              _HeroPill(
                icon: Icons.flag_outlined,
                label: session.goal,
              ),
              _HeroPill(
                icon: Icons.fitness_center_rounded,
                label:
                    '${session.totalExercises} exercises • ${session.totalMainSets} sets',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Completion progress indicator
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todayLog == null
                            ? '0 / ${session.totalMainSets} sets logged today — Ready to Start'
                            : '$completedSets / ${session.totalMainSets} sets logged today • RPE ${todayLog!.perceivedDifficulty}/10',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.roundedFull,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.limeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Actions
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(
                label: isDoneToday ? 'Run Session Again' : 'Start Workout',
                icon: Icons.play_arrow_rounded,
                onPressed: onStartWorkout,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textOnDark,
                  side: const BorderSide(color: AppColors.darkBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 13,
                  ),
                ),
                onPressed: onOpenRestTimer,
                icon: const Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppColors.limeAccent,
                ),
                label: const Text('Rest Timer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

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

class _PhaseExerciseTile extends StatelessWidget {
  final ExerciseDetail exercise;
  final Color phaseColor;
  final bool showDivider;
  final VoidCallback onDetails;

  const _PhaseExerciseTile({
    required this.exercise,
    required this.phaseColor,
    required this.showDivider,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.borderSubtle))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: phaseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                ),
                Text(
                  '${exercise.prescriptionSummary} • ${exercise.targetMuscles} • ${exercise.equipment}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onDetails,
            child: const Text('Form'),
          ),
        ],
      ),
    );
  }
}

class _MainExerciseCard extends ConsumerWidget {
  final int index;
  final ExerciseDetail exercise;
  final ProgressionSuggestion? suggestion;
  final VoidCallback onDetails;
  final VoidCallback onReplace;

  const _MainExerciseCard({
    required this.index,
    required this.exercise,
    required this.suggestion,
    required this.onDetails,
    required this.onReplace,
  });

  String _formatPreviousPerformance(ExerciseLog prev) {
    final completedSets = prev.sets.where((s) => s.completed).toList();
    if (completedSets.isEmpty) {
      return 'Last session: skipped or 0 completed sets';
    }
    final topWt = prev.topWeightKg;
    final reps = completedSets.first.repsCompleted;
    if (topWt != null && topWt > 0) {
      final wtStr = topWt == topWt.roundToDouble()
          ? topWt.toInt().toString()
          : topWt.toStringAsFixed(1);
      return 'Last logged: ${completedSets.length} × $reps reps @ $wtStr kg';
    }
    if (reps > 0) {
      return 'Last logged: ${completedSets.length} × $reps reps';
    }
    return 'Last logged: ${completedSets.length} sets completed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prevLogAsync = ref.watch(previousExerciseLogProvider(exercise.id));
    final prevLog = prevLogAsync.value;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.limeAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.targetMuscles,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Meta Pills
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                icon: Icons.repeat_rounded,
                label: exercise.prescriptionSummary,
                highlighted: true,
              ),
              _MetaChip(
                icon: Icons.timer_outlined,
                label: '${exercise.restSeconds}s rest',
              ),
              _MetaChip(
                icon: Icons.fitness_center_rounded,
                label: exercise.equipment,
              ),
              _MetaChip(
                icon: Icons.signal_cellular_alt_rounded,
                label: exercise.difficulty,
              ),
            ],
          ),

          if (exercise.requiresSupervisionNote) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: AppRadius.roundedSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exercise.coachingCue ??
                          'Use rack safeties or a spotter when lifting heavy loads.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Previous Performance & Progression Readiness
          if (prevLog != null || suggestion != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prevLog != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatPreviousPerformance(prevLog),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (prevLog != null && suggestion != null)
                    const SizedBox(height: AppSpacing.xs),
                  if (suggestion != null)
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: suggestion!.readyToProgress
                                ? AppColors.successBg
                                : AppColors.infoBg,
                            borderRadius: AppRadius.roundedSm,
                          ),
                          child: Text(
                            suggestion!.readyToProgress
                                ? 'READY TO PROGRESS'
                                : 'HOLD & CONSOLIDATE',
                            style: AppTextStyles.badge.copyWith(
                              fontSize: 10,
                              color: suggestion!.readyToProgress
                                  ? AppColors.success
                                  : AppColors.info,
                            ),
                          ),
                        ),
                        Text(
                          suggestion!.recommendation,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Actions Row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SecondaryButton(
                label: 'Details & Form',
                icon: Icons.info_outline_rounded,
                height: 38,
                onPressed: onDetails,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 9,
                  ),
                ),
                onPressed: onReplace,
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppColors.limeAccentDark,
                ),
                label: const Text('Replace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.limeAccent.withValues(alpha: 0.18)
            : AppColors.cardSubtleBg,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: highlighted
              ? AppColors.limeAccentDark.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlighted
                ? AppColors.limeAccentDark
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: highlighted
                  ? AppColors.limeAccentDark
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
