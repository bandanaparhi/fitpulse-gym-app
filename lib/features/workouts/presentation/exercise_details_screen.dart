import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/fitness_profile.dart';
import '../../../data/models/personal_record.dart';
import '../../../data/models/workout_log.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/repositories/workout_planner_engine.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/training_safety_banner.dart';

/// Detailed exercise instructions, form cues, variations, alternatives,
/// previous logged sets, and personal records.
class ExerciseDetailsScreen extends ConsumerWidget {
  final String exerciseId;
  final String? sessionId;

  const ExerciseDetailsScreen({
    super.key,
    required this.exerciseId,
    this.sessionId,
  });

  ExerciseDetail? _findInSession(WorkoutSession? session) {
    if (session == null) return null;
    for (final ex in [
      ...session.warmUp,
      ...session.mainExercises,
      ...session.coolDown,
    ]) {
      if (ex.id == exerciseId) return ex;
    }
    return null;
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.info;
      case 'advanced':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _difficultyBg(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.successBg;
      case 'intermediate':
        return AppColors.infoBg;
      case 'advanced':
        return AppColors.warningBg;
      default:
        return AppColors.cardSubtleBg;
    }
  }

  void _navigateToExercise(BuildContext context, String targetExerciseId) {
    final query = sessionId != null && sessionId!.isNotEmpty
        ? '?sessionId=$sessionId'
        : '';
    context.go('/workouts/exercise/$targetExerciseId$query');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = sessionId != null && sessionId!.isNotEmpty
        ? ref.watch(plannerSessionByIdProvider(sessionId!))
        : null;
    final profileAsync = ref.watch(fitnessProfileProvider);
    final prevLogAsync = ref.watch(previousExerciseLogProvider(exerciseId));
    final prsAsync = ref.watch(personalRecordsProvider);

    final fallbackExercise = WorkoutPlannerEngine.getExerciseById(exerciseId);

    if (sessionAsync != null &&
        sessionAsync.isLoading &&
        fallbackExercise == null) {
      return const LoadingIndicator(message: 'Loading exercise details...');
    }

    final sessionExercise = _findInSession(sessionAsync?.value);
    final exercise = sessionExercise ?? fallbackExercise;

    if (exercise == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Exercise Details',
              showBackButton: true,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/workouts/today');
                }
              },
            ),
            EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'Exercise Not Found',
              message:
                  'We could not find details for exercise "$exerciseId". Return to your workout plan to select another exercise.',
              actionLabel: 'Back to Today\'s Workout',
              onAction: () => context.go('/workouts/today'),
            ),
          ],
        ),
      );
    }

    final profile = profileAsync.value;
    final prevLog = prevLogAsync.value;
    final prs = prsAsync.value ?? const <PersonalRecord>[];
    final matchingPrs = prs
        .where((pr) => pr.exerciseId == exercise.id)
        .toList();

    final alternatives = WorkoutPlannerEngine.findAlternatives(
      exercise,
      profile: profile,
    );

    final effectiveRestSeconds =
        exercise.restSeconds > 0 ? exercise.restSeconds : 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: exercise.name,
            subtitle: exercise.targetMuscles,
            showBackButton: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/workouts/today');
              }
            },
            trailing: OutlinedButton.icon(
              onPressed: () => RestTimerDialog.show(
                context,
                initialSeconds: effectiveRestSeconds,
              ),
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Rest Timer'),
            ),
          ),

          const PlannerNavStrip(currentPath: '/workouts/exercise'),
          const SizedBox(height: AppSpacing.lg),

          // Hero Exercise Summary Card
          _buildHeroCard(
            context,
            exercise: exercise,
            fromSession: sessionExercise != null,
            effectiveRestSeconds: effectiveRestSeconds,
          ),
          const SizedBox(height: AppSpacing.md),

          // Supervision Guidance Banner (when requiresSupervisionNote is true)
          if (exercise.requiresSupervisionNote) ...[
            _buildSupervisionBanner(exercise),
            const SizedBox(height: AppSpacing.md),
          ] else if (exercise.coachingCue != null &&
              exercise.coachingCue!.isNotEmpty) ...[
            _buildCoachingCueCard(exercise.coachingCue!),
            const SizedBox(height: AppSpacing.md),
          ],

          // Step-by-Step Instructions & Common Mistakes
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;
              final instructionsCard = _buildInstructionsCard(exercise);
              final mistakesCard = _buildMistakesCard(exercise);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: instructionsCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: mistakesCard),
                  ],
                );
              }
              return Column(
                children: [
                  instructionsCard,
                  const SizedBox(height: AppSpacing.md),
                  mistakesCard,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Demonstration Media Truthful Placeholder Card
          _buildDemoPlaceholderCard(),
          const SizedBox(height: AppSpacing.md),

          // Easier & Harder Variations
          _buildVariationsSection(exercise),
          const SizedBox(height: AppSpacing.md),

          // Previous Logged Performance & Matching PR
          _buildHistoryAndPrSection(
            prevLog: prevLog,
            matchingPrs: matchingPrs,
            isLoadingPrev: prevLogAsync.isLoading,
          ),
          const SizedBox(height: AppSpacing.md),

          // Equipment-Safe Alternative Exercises
          _buildAlternativesSection(
            context,
            exercise: exercise,
            alternatives: alternatives,
            profile: profile,
          ),
          const SizedBox(height: AppSpacing.lg),

          TrainingSafetyBanner(
            hasMedicalConcern: profile?.hasMedicalClearanceNotice ?? false,
            isSampleData: profile?.isSampleData ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required ExerciseDetail exercise,
    required bool fromSession,
    required int effectiveRestSeconds,
  }) {
    final diffColor = _difficultyColor(exercise.difficulty);
    final diffBg = _difficultyBg(exercise.difficulty);

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
            children: [
              _DarkBadge(
                label: exercise.category.toUpperCase(),
                bgColor: AppColors.limeAccent.withValues(alpha: 0.18),
                textColor: AppColors.limeAccent,
                borderColor: AppColors.limeAccent.withValues(alpha: 0.45),
              ),
              _DarkBadge(
                label: exercise.difficulty,
                bgColor: diffBg,
                textColor: diffColor,
                borderColor: diffColor.withValues(alpha: 0.4),
              ),
              _DarkBadge(
                label: exercise.equipment,
                icon: Icons.fitness_center_rounded,
                bgColor: AppColors.darkElevated,
                textColor: AppColors.textOnDark,
                borderColor: AppColors.darkBorder,
              ),
              if (fromSession)
                _DarkBadge(
                  label: 'SESSION PRESCRIPTION',
                  bgColor: AppColors.infoBg,
                  textColor: AppColors.info,
                  borderColor: AppColors.info.withValues(alpha: 0.35),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            exercise.name,
            style: AppTextStyles.h2Dark,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Target Muscles: ${exercise.targetMuscles}',
            style: AppTextStyles.bodyMediumDark.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkElevated,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 520;
                final prescriptionBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRESCRIBED VOLUME & REST',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.prescriptionSummary,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.restSeconds > 0
                          ? 'Rest ${exercise.restSeconds}s between sets'
                          : 'Continuous / low-rest recovery movement',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDarkMuted,
                      ),
                    ),
                  ],
                );

                final timerBtn = PrimaryButton(
                  label: 'Open Rest Timer (${effectiveRestSeconds}s)',
                  icon: Icons.timer_outlined,
                  height: 42,
                  isFullWidth: isCompact,
                  onPressed: () => RestTimerDialog.show(
                    context,
                    initialSeconds: effectiveRestSeconds,
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      prescriptionBlock,
                      const SizedBox(height: AppSpacing.md),
                      timerBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: prescriptionBlock),
                    const SizedBox(width: AppSpacing.md),
                    timerBtn,
                  ],
                );
              },
            ),
          ),
          if (exercise.sets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: exercise.sets.map((set) {
                final repText = set.repRangeLabel != null &&
                        set.repRangeLabel!.isNotEmpty
                    ? set.repRangeLabel!
                    : (set.durationSeconds != null && set.durationSeconds! > 0
                        ? '${set.durationSeconds}s'
                        : '${set.targetReps} reps');
                final weightText = set.targetWeightKg != null
                    ? ' @ ${set.targetWeightKg!.toStringAsFixed(set.targetWeightKg! % 1 == 0 ? 0 : 1)} kg'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    'Set ${set.setNumber}: $repText$weightText',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupervisionBanner(ExerciseDetail exercise) {
    final cue = exercise.coachingCue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supervision & Spotter Guidance',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This movement involves compound barbell loading or explosive power. Set safety spotter arms/pins before lifting, ask a qualified trainer or spotter when working near heavy loads, and stop immediately if technique breaks down.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (cue != null && cue.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Coaching Cue: $cue',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingCueCard(String cue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.limeAccentLight,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.limeAccentDark,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Coaching Cue: $cue',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(ExerciseDetail exercise) {
    return InfoCard(
      title: 'Step-by-Step Instructions',
      subtitle: 'Follow form cues in order before adding resistance',
      icon: Icons.format_list_numbered_rounded,
      child: exercise.instructions.isEmpty
          ? Text(
              'No step-by-step instructions provided for this movement.',
              style: AppTextStyles.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(exercise.instructions.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == exercise.instructions.length - 1
                        ? 0
                        : AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeAccentDark.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          exercise.instructions[index],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildMistakesCard(ExerciseDetail exercise) {
    return InfoCard(
      title: 'Common Mistakes to Avoid',
      subtitle: 'Check posture and joint alignment each rep',
      icon: Icons.report_problem_outlined,
      child: exercise.commonMistakes.isEmpty
          ? Text(
              'Maintain steady breathing and controlled tempo throughout.',
              style: AppTextStyles.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(exercise.commonMistakes.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == exercise.commonMistakes.length - 1
                        ? 0
                        : AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.errorBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          exercise.commonMistakes[index],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildDemoPlaceholderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final mediaBox = Container(
            width: isCompact ? double.infinity : 160,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off_outlined,
                  color: AppColors.textOnDarkMuted,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'MEDIA OFFLINE',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );

          final messageBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Demonstration Preview',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'No local video or animation asset is configured for this exercise. Follow the numbered form cues and common mistake checks above.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mediaBox,
                const SizedBox(height: AppSpacing.md),
                messageBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              mediaBox,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: messageBlock),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVariationsSection(ExerciseDetail exercise) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final easierCard = InfoCard(
          title: 'Easier Variation',
          subtitle: 'Scale down if form or mobility feels limited',
          icon: Icons.south_east_rounded,
          child: Text(
            exercise.easierVariation.isNotEmpty
                ? exercise.easierVariation
                : 'Reduce resistance or range of motion to stay in control.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        );

        final harderCard = InfoCard(
          title: 'Harder Variation',
          subtitle: 'Progress only after consistent clean sessions',
          icon: Icons.north_east_rounded,
          child: Text(
            exercise.harderVariation.isNotEmpty
                ? exercise.harderVariation
                : 'Slow the lowering tempo or increase resistance gradually.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: easierCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: harderCard),
            ],
          );
        }
        return Column(
          children: [
            easierCard,
            const SizedBox(height: AppSpacing.md),
            harderCard,
          ],
        );
      },
    );
  }

  Widget _buildHistoryAndPrSection({
    required ExerciseLog? prevLog,
    required List<PersonalRecord> matchingPrs,
    required bool isLoadingPrev,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final previousCard = InfoCard(
          title: 'Previous Logged Performance',
          subtitle: 'Most recent completed sets for this exercise',
          icon: Icons.history_rounded,
          child: isLoadingPrev
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              : prevLog == null
                  ? Text(
                      'No previous workout logged for this exercise yet. Your completed sets will appear here after your next session.',
                      style: AppTextStyles.bodyMedium,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: prevLog.sets
                              .where((s) => s.completed)
                              .map((set) {
                            final wt = set.weightKg != null
                                ? '${set.weightKg!.toStringAsFixed(set.weightKg! % 1 == 0 ? 0 : 1)} kg × '
                                : '';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardSubtleBg,
                                borderRadius: AppRadius.roundedSm,
                                border:
                                    Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                'Set ${set.setNumber}: $wt${set.repsCompleted} reps',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (prevLog.notes != null &&
                            prevLog.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Note: ${prevLog.notes}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ],
                    ),
        );

        final prCard = InfoCard(
          title: 'Personal Record',
          subtitle: 'Best logged milestone for this movement',
          icon: Icons.emoji_events_outlined,
          child: matchingPrs.isEmpty
              ? Text(
                  'No personal record logged yet for this exercise.',
                  style: AppTextStyles.bodyMedium,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: matchingPrs.map((pr) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccentLight,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(
                            color: AppColors.limeAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  pr.formattedValue,
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: AppRadius.roundedFull,
                                    border: Border.all(
                                      color: AppColors.limeAccentDark
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    pr.recordType,
                                    style: AppTextStyles.badge.copyWith(
                                      color: AppColors.limeAccentDark,
                                    ),
                                  ),
                                ),
                                if (pr.isSampleData)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: AppRadius.roundedSm,
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      'SAMPLE DATA',
                                      style: AppTextStyles.badge.copyWith(
                                        fontSize: 9,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Achieved ${AppFormatters.formatShortDate(pr.achievedAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (pr.notes != null && pr.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                pr.notes!,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: previousCard),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: prCard),
            ],
          );
        }
        return Column(
          children: [
            previousCard,
            const SizedBox(height: AppSpacing.md),
            prCard,
          ],
        );
      },
    );
  }

  Widget _buildAlternativesSection(
    BuildContext context, {
    required ExerciseDetail exercise,
    required List<ExerciseDetail> alternatives,
    required FitnessProfile? profile,
  }) {
    final primaryAltName = exercise.alternativeExerciseName;
    final primaryAltId = exercise.alternativeExerciseId;
    final primaryInList = primaryAltId != null &&
        alternatives.any((alt) => alt.id == primaryAltId);

    return InfoCard(
      title: 'Alternative Exercises (If Equipment Unavailable)',
      subtitle: profile != null
          ? 'Filtered for ${profile.workoutLocation} setup & safety preferences'
          : 'Compatible swaps targeting similar muscle groups',
      icon: Icons.swap_horiz_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (primaryAltName != null &&
              primaryAltName.isNotEmpty &&
              !primaryInList) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_outline_rounded,
                    size: 18,
                    color: AppColors.limeAccentDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Primary Swap: $primaryAltName',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  if (primaryAltId != null &&
                      WorkoutPlannerEngine.getExerciseById(primaryAltId) !=
                          null)
                    TextButton(
                      onPressed: () =>
                          _navigateToExercise(context, primaryAltId),
                      child: const Text('Inspect'),
                    ),
                ],
              ),
            ),
          ],
          if (alternatives.isEmpty)
            Text(
              'No additional alternatives found in library for this movement.',
              style: AppTextStyles.bodyMedium,
            )
          else
            Column(
              children: alternatives.map((alt) {
                final isPrimary = alt.id == primaryAltId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    onTap: () => _navigateToExercise(context, alt.id),
                    borderRadius: AppRadius.roundedMd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardSubtleBg,
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      alt.name,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    if (isPrimary)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.limeAccent
                                              .withValues(alpha: 0.2),
                                          borderRadius: AppRadius.roundedSm,
                                        ),
                                        child: Text(
                                          'RECOMMENDED SWAP',
                                          style: AppTextStyles.badge.copyWith(
                                            fontSize: 9,
                                            color: AppColors.limeAccentDark,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${alt.equipment} • ${alt.difficulty} • ${alt.targetMuscles}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () =>
                                _navigateToExercise(context, alt.id),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: const Text('Inspect'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _DarkBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _DarkBadge({
    required this.label,
    this.icon,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
