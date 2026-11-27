import 'dart:async';
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
import '../../../data/models/workout_session.dart';
import '../../../data/repositories/workout_planner_engine.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'widgets/training_safety_banner.dart';

class _MutableSetEntry {
  final int setNumber;
  final SetSpec spec;
  final TextEditingController repsController;
  final TextEditingController weightController;
  bool completed = false;
  bool userEdited = false;
  DateTime? loggedAt;

  _MutableSetEntry({
    required this.setNumber,
    required this.spec,
    required this.repsController,
    required this.weightController,
  });

  void dispose() {
    repsController.dispose();
    weightController.dispose();
  }
}

class _ActiveExerciseState {
  ExerciseDetail exercise;
  String? replacedFromName;
  bool skipped = false;
  bool prefilledFromPrev = false;
  List<_MutableSetEntry> sets;

  _ActiveExerciseState({
    required this.exercise,
    this.replacedFromName,
    required this.sets,
  });

  bool get isFullyCompleted =>
      !skipped && sets.isNotEmpty && sets.every((s) => s.completed);

  int get completedSetsCount => sets.where((s) => s.completed).length;

  void dispose() {
    for (final s in sets) {
      s.dispose();
    }
  }
}

/// Live exercise-by-exercise workout execution mode for a planned [WorkoutSession].
/// Route: `/workouts/session/active/:sessionId`
class PlannerActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const PlannerActiveWorkoutScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<PlannerActiveWorkoutScreen> createState() =>
      _PlannerActiveWorkoutScreenState();
}

class _PlannerActiveWorkoutScreenState
    extends ConsumerState<PlannerActiveWorkoutScreen> {
  WorkoutSession? _boundSession;
  final List<_ActiveExerciseState> _exercises = [];
  int _currentIndex = 0;

  // Elapsed workout timer
  late final DateTime _startedAt;
  late final Stopwatch _stopwatch;
  Timer? _elapsedTicker;
  int _elapsedSeconds = 0;
  bool _isWorkoutPaused = false;

  // Built-in Rest Countdown Timer
  Timer? _restTimer;
  int _restTotalSeconds = 0;
  int _restRemainingSeconds = 0;
  bool _isResting = false;
  bool _isRestPaused = false;

  // Session Notes & Perceived Difficulty (RPE 1-10)
  final TextEditingController _notesController = TextEditingController();
  int _rpe = 7;

  // Saving & Completion state
  bool _isSaving = false;
  WorkoutLog? _completedLog;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _stopwatch = Stopwatch()..start();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isWorkoutPaused && _completedLog == null) {
        setState(() {
          _elapsedSeconds = _stopwatch.elapsed.inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    _notesController.dispose();
    for (final ex in _exercises) {
      ex.dispose();
    }
    super.dispose();
  }

  void _initializeSession(WorkoutSession session) {
    if (_boundSession?.id == session.id && _exercises.isNotEmpty) return;

    for (final ex in _exercises) {
      ex.dispose();
    }
    _exercises.clear();

    final sourceList = session.mainExercises.isNotEmpty
        ? session.mainExercises
        : [...session.warmUp, ...session.coolDown];

    for (final ex in sourceList) {
      _exercises.add(_buildExerciseState(ex));
    }
    _boundSession = session;
    _currentIndex = 0;
  }

  _ActiveExerciseState _buildExerciseState(
    ExerciseDetail ex, {
    String? replacedFromName,
  }) {
    final specs = ex.sets.isNotEmpty
        ? ex.sets
        : [const SetSpec(setNumber: 1, targetReps: 10)];

    final sets = specs.map((spec) {
      final initialReps = spec.targetReps > 0
          ? spec.targetReps.toString()
          : (spec.durationSeconds != null && spec.durationSeconds! > 0
              ? spec.durationSeconds.toString()
              : '10');
      final initialWeight = spec.targetWeightKg != null
          ? _formatNumericWeight(spec.targetWeightKg!)
          : '';
      return _MutableSetEntry(
        setNumber: spec.setNumber,
        spec: spec,
        repsController: TextEditingController(text: initialReps),
        weightController: TextEditingController(text: initialWeight),
      );
    }).toList();

    return _ActiveExerciseState(
      exercise: ex,
      replacedFromName: replacedFromName,
      sets: sets,
    );
  }

  String _formatNumericWeight(double val) {
    return val == val.roundToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  void _maybePrefillFromPrevious(
    _ActiveExerciseState exState,
    ExerciseLog? prevLog,
  ) {
    if (exState.prefilledFromPrev || prevLog == null) return;
    exState.prefilledFromPrev = true;

    final prevSets = prevLog.sets.where((s) => s.completed).toList();
    if (prevSets.isEmpty) return;

    for (int i = 0; i < exState.sets.length; i++) {
      final entry = exState.sets[i];
      if (entry.userEdited) continue;
      final source = i < prevSets.length ? prevSets[i] : prevSets.last;
      if (source.repsCompleted > 0) {
        entry.repsController.text = source.repsCompleted.toString();
      }
      if (source.weightKg != null) {
        entry.weightController.text = _formatNumericWeight(source.weightKg!);
      }
    }
  }

  void _toggleWorkoutPause() {
    setState(() {
      _isWorkoutPaused = !_isWorkoutPaused;
      if (_isWorkoutPaused) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  void _startRestTimer(int seconds) {
    if (seconds <= 0) return;
    _restTimer?.cancel();
    setState(() {
      _restTotalSeconds = seconds;
      _restRemainingSeconds = seconds;
      _isResting = true;
      _isRestPaused = false;
    });
    _startRestTicker();
  }

  void _startRestTicker() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isRestPaused) return;
      if (_restRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _restRemainingSeconds = 0;
          _isResting = false;
          _isRestPaused = false;
        });
      } else {
        setState(() {
          _restRemainingSeconds--;
        });
      }
    });
  }

  void _toggleRestPause() {
    if (!_isResting) return;
    setState(() {
      _isRestPaused = !_isRestPaused;
    });
  }

  void _addRestSeconds(int delta) {
    setState(() {
      _restRemainingSeconds += delta;
      if (_restRemainingSeconds > _restTotalSeconds) {
        _restTotalSeconds = _restRemainingSeconds;
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _isRestPaused = false;
      _restRemainingSeconds = 0;
    });
  }

  String _formatClock(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleSetCompleted(_ActiveExerciseState exState, _MutableSetEntry set) {
    setState(() {
      final next = !set.completed;
      set.completed = next;
      set.loggedAt = next ? DateTime.now() : null;
      if (next) {
        exState.skipped = false;
      }
    });
    if (set.completed && exState.exercise.restSeconds > 0) {
      _startRestTimer(exState.exercise.restSeconds);
    }
  }

  void _skipCurrentExercise() {
    if (_exercises.isEmpty) return;
    setState(() {
      final current = _exercises[_currentIndex];
      current.skipped = !current.skipped;
      if (current.skipped && _currentIndex < _exercises.length - 1) {
        _currentIndex++;
      }
    });
  }

  Future<void> _openReplaceExerciseModal(FitnessProfile? profile) async {
    if (_exercises.isEmpty) return;
    final currentState = _exercises[_currentIndex];
    final currentEx = currentState.exercise;
    final alternatives = WorkoutPlannerEngine.findAlternatives(
      currentEx,
      profile: profile,
    );

    final selected = await showDialog<ExerciseDetail>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Expanded(
                      child: Text('Replace Exercise', style: AppTextStyles.h3),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose an equipment-safe alternative for ${currentEx.name}:',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (alternatives.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No compatible alternatives found in the library for this movement.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: alternatives.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final alt = alternatives[idx];
                        return InkWell(
                          onTap: () => Navigator.of(ctx).pop(alt),
                          borderRadius: AppRadius.roundedMd,
                          child: Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alt.name,
                                        style: AppTextStyles.titleMedium,
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
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: SecondaryButton(
                    label: 'Cancel',
                    height: 40,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      final originalName =
          currentState.replacedFromName ?? currentState.exercise.name;
      currentState.dispose();
      _exercises[_currentIndex] = _buildExerciseState(
        selected,
        replacedFromName: originalName,
      );
    });
  }

  Future<void> _openPainSafetyModal(WorkoutSession session) async {
    final discomfortController = TextEditingController();
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.errorBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Stop & Report Pain or Discomfort',
                        style: AppTextStyles.h3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: AppRadius.roundedMd,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Do not train through sharp pain. These plans are general fitness guidance and not medical diagnosis; consult a healthcare professional if pain persists.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Optional note (area or movement causing discomfort):',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: discomfortController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sharp pinch in left shoulder during pressing',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SecondaryButton(
                      label: 'Resume Workout',
                      height: 42,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Stop & Save Partial Log'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final discomfortNote = discomfortController.text.trim();
    discomfortController.dispose();

    if (shouldStop == true && mounted) {
      await _saveAndComplete(
        session,
        stoppedDueToDiscomfort: true,
        discomfortNote: discomfortNote.isEmpty ? null : discomfortNote,
      );
    }
  }

  Future<void> _confirmAndFinishWorkout(WorkoutSession session) async {
    final completedSets = _exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.completedSetsCount,
    );
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Finish Workout?',
      message:
          'You have completed $completedSets sets across ${_exercises.where((e) => e.completedSetsCount > 0).length} exercises. Save this session to your workout log?',
      confirmLabel: 'Finish & Save',
      cancelLabel: 'Keep Training',
    );

    if (confirmed == true && mounted) {
      await _saveAndComplete(
        session,
        stoppedDueToDiscomfort: false,
      );
    }
  }

  Future<void> _saveAndComplete(
    WorkoutSession session, {
    required bool stoppedDueToDiscomfort,
    String? discomfortNote,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    _elapsedTicker?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();

    final memberId = ref.read(authStateProvider).memberId ?? 'GM-1024';
    final now = DateTime.now();
    final durationMinutes = ((_elapsedSeconds / 60).ceil()).clamp(1, 600);

    final exerciseLogs = _exercises.map((exState) {
      final setLogs = exState.sets.map((s) {
        final parsedReps = int.tryParse(s.repsController.text.trim()) ?? 0;
        final parsedWeight =
            double.tryParse(s.weightController.text.trim());
        return SetLog(
          setNumber: s.setNumber,
          repsCompleted: parsedReps,
          weightKg: parsedWeight,
          completed: s.completed,
          skipped: exState.skipped && !s.completed,
          loggedAt: s.loggedAt ?? now,
        );
      }).toList();

      return ExerciseLog(
        exerciseId: exState.exercise.id,
        exerciseName: exState.exercise.name,
        targetMuscles: exState.exercise.targetMuscles,
        sets: setLogs,
        skipped: exState.skipped,
        replacedFromName: exState.replacedFromName,
      );
    }).toList();

    final notesText = _notesController.text.trim();
    final log = WorkoutLog(
      id: 'LOG-${now.millisecondsSinceEpoch}',
      memberId: memberId,
      sessionId: session.id,
      sessionTitle: session.title,
      focus: session.focus,
      startedAt: _startedAt,
      completedAt: now,
      durationMinutes: durationMinutes,
      exerciseLogs: exerciseLogs,
      perceivedDifficulty: _rpe,
      generalNotes: notesText.isEmpty ? null : notesText,
      isCompleted: !stoppedDueToDiscomfort,
      stoppedDueToDiscomfort: stoppedDueToDiscomfort,
      discomfortNote: discomfortNote,
      isSampleData: false,
    );

    try {
      await ref.read(workoutLogsProvider.notifier).saveLog(log);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _completedLog = log;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save workout log: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(plannerSessionByIdProvider(widget.sessionId));
    final todayAsync = ref.watch(todaySessionProvider);
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);
    final prsAsync = ref.watch(personalRecordsProvider);

    if (sessionAsync.isLoading && _boundSession == null) {
      return const LoadingIndicator(message: 'Preparing workout session...');
    }

    if (sessionAsync.hasError && _boundSession == null) {
      return ErrorState(
        title: 'Unable to Load Session',
        message: sessionAsync.error.toString(),
        onRetry: () => ref.invalidate(plannerSessionByIdProvider(widget.sessionId)),
      );
    }

    final planSessions = planAsync.value?.sessions ?? const <WorkoutSession>[];
    final resolvedSession = sessionAsync.value ??
        todayAsync.value ??
        (planSessions.isNotEmpty ? planSessions.first : null);

    if (resolvedSession == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(
          icon: Icons.fitness_center_outlined,
          title: 'Workout Session Not Found',
          message:
              'We could not find session "${widget.sessionId}" in your active weekly plan.',
          actionLabel: 'View Weekly Plan',
          onAction: () => context.go('/workouts/weekly-plan'),
        ),
      );
    }

    _initializeSession(resolvedSession);

    if (_completedLog != null) {
      return _buildFinishSummaryView(
        context,
        log: _completedLog!,
        session: resolvedSession,
        profile: profileAsync.value,
      );
    }

    if (_exercises.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(
          icon: Icons.list_alt_outlined,
          title: 'No Exercises in Session',
          message: 'This session has no exercises scheduled.',
          actionLabel: 'Back to Workouts',
          onAction: () => context.go('/workouts'),
        ),
      );
    }

    final currentExState = _exercises[_currentIndex];
    final currentEx = currentExState.exercise;
    final prevLogAsync = ref.watch(previousExerciseLogProvider(currentEx.id));
    final prevLog = prevLogAsync.value;
    if (prevLog != null) {
      _maybePrefillFromPrevious(currentExState, prevLog);
    }

    final prs = prsAsync.value ?? const <PersonalRecord>[];
    PersonalRecord? matchingPr;
    for (final pr in prs) {
      if (pr.exerciseId == currentEx.id) {
        matchingPr = pr;
        break;
      }
    }

    final profile = profileAsync.value;
    final totalExercises = _exercises.length;
    final completedExercises =
        _exercises.where((e) => e.isFullyCompleted || e.skipped).length;
    final totalSets = _exercises.fold<int>(0, (s, e) => s + e.sets.length);
    final completedSets =
        _exercises.fold<int>(0, (s, e) => s + e.completedSetsCount);
    final overallProgress =
        totalSets > 0 ? (completedSets / totalSets).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Execution Bar
          _buildTopBar(
            session: resolvedSession,
            completedExercises: completedExercises,
            totalExercises: totalExercises,
            completedSets: completedSets,
            totalSets: totalSets,
            progress: overallProgress,
          ),
          const SizedBox(height: AppSpacing.md),

          // Built-in Rest Countdown Timer Banner (when active)
          if (_isResting) ...[
            _buildRestBanner(),
            const SizedBox(height: AppSpacing.md),
          ],

          // Quick Exercise Stepper Strip
          _buildExerciseStepper(),
          const SizedBox(height: AppSpacing.md),

          // Current Exercise Header + Expandable Form Cues
          _buildCurrentExerciseCard(
            context,
            session: resolvedSession,
            exState: currentExState,
          ),
          const SizedBox(height: AppSpacing.md),

          // Active Sets & Previous Performance (responsive split on desktop, stacked on mobile/tablet)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final setsPanel = _buildActiveSetsCard(currentExState);
              final prevPanel = _buildPreviousPerformanceCard(
                currentEx: currentEx,
                prevLog: prevLog,
                isLoading: prevLogAsync.isLoading,
                matchingPr: matchingPr,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: setsPanel),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: prevPanel),
                  ],
                );
              }
              return Column(
                children: [
                  prevPanel,
                  const SizedBox(height: AppSpacing.md),
                  setsPanel,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Exercise Navigation & Actions Row
          _buildExerciseActionsCard(profile),
          const SizedBox(height: AppSpacing.md),

          // Warm-Up & Cool-Down Reference
          if (resolvedSession.warmUp.isNotEmpty ||
              resolvedSession.coolDown.isNotEmpty) ...[
            _buildWarmUpCoolDownCard(resolvedSession),
            const SizedBox(height: AppSpacing.md),
          ],

          // Workout Notes & Perceived Difficulty (RPE 1-10) + Finish Button
          _buildFinishSection(resolvedSession),
          const SizedBox(height: AppSpacing.lg),

          TrainingSafetyBanner(
            hasMedicalConcern: profile?.hasMedicalClearanceNotice ?? false,
            isSampleData: profile?.isSampleData ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({
    required WorkoutSession session,
    required int completedExercises,
    required int totalExercises,
    required int completedSets,
    required int totalSets,
    required double progress,
  }) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;
              final titleColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: AppTextStyles.h2Dark,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${session.focus} • ${session.level}',
                    style: AppTextStyles.bodyMediumDark,
                  ),
                ],
              );

              final controlsWrap = Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isWorkoutPaused
                              ? Icons.pause_circle_outline_rounded
                              : Icons.timer_outlined,
                          size: 16,
                          color: _isWorkoutPaused
                              ? AppColors.warning
                              : AppColors.limeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatClock(_elapsedSeconds),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textOnDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textOnDark,
                      side: const BorderSide(color: AppColors.darkBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _toggleWorkoutPause,
                    icon: Icon(
                      _isWorkoutPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 18,
                    ),
                    label: Text(_isWorkoutPaused ? 'Resume' : 'Pause'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorBg,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _openPainSafetyModal(session),
                    icon: const Icon(Icons.health_and_safety_outlined, size: 18),
                    label: const Text('Stop / Report Pain'),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleColumn,
                    const SizedBox(height: AppSpacing.md),
                    controlsWrap,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleColumn),
                  const SizedBox(width: AppSpacing.md),
                  controlsWrap,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progress: $completedExercises / $totalExercises exercises • $completedSets / $totalSets sets',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.limeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.darkElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.limeAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestBanner() {
    final progress = _restTotalSeconds > 0
        ? (_restRemainingSeconds / _restTotalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.limeAccentLight,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(
          color: AppColors.limeAccentDark.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: AppColors.limeAccentDark,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRestPaused ? 'REST PAUSED' : 'REST COUNTDOWN',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.limeAccentDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatClock(_restRemainingSeconds),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addRestSeconds(15),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+15s'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleRestPause,
                    icon: Icon(
                      _isRestPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 16,
                    ),
                    label: Text(_isRestPaused ? 'Resume' : 'Pause'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCharcoal,
                      foregroundColor: AppColors.textOnDark,
                    ),
                    onPressed: _skipRest,
                    child: const Text('Skip Rest'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.cardBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.limeAccentDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseStepper() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_exercises.length, (idx) {
          final ex = _exercises[idx];
          final isCurrent = idx == _currentIndex;
          final isDone = ex.isFullyCompleted;
          final isSkipped = ex.skipped;

          Color bgColor = AppColors.cardBackground;
          Color borderColor = AppColors.borderSubtle;
          Color textColor = AppColors.textPrimary;

          if (isCurrent) {
            bgColor = AppColors.darkCharcoal;
            borderColor = AppColors.darkCharcoal;
            textColor = AppColors.textOnDark;
          } else if (isDone) {
            bgColor = AppColors.successBg;
            borderColor = AppColors.success.withValues(alpha: 0.45);
            textColor = AppColors.success;
          } else if (isSkipped) {
            bgColor = AppColors.warningBg;
            borderColor = AppColors.warning.withValues(alpha: 0.45);
            textColor = AppColors.warning;
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: InkWell(
              onTap: () => setState(() => _currentIndex = idx),
              borderRadius: AppRadius.roundedFull,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppRadius.roundedFull,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDone) ...[
                      Icon(Icons.check_circle_rounded, size: 14, color: textColor),
                      const SizedBox(width: 4),
                    ] else if (isSkipped) ...[
                      Icon(Icons.skip_next_rounded, size: 14, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${idx + 1}. ${ex.exercise.name}',
                      style: AppTextStyles.caption.copyWith(
                        color: textColor,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentExerciseCard(
    BuildContext context, {
    required WorkoutSession session,
    required _ActiveExerciseState exState,
  }) {
    final ex = exState.exercise;
    final replacedFrom = exState.replacedFromName;

    return InfoCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedFull,
                ),
                child: Text(
                  'Exercise ${_currentIndex + 1} of ${_exercises.length}',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  ex.equipment,
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  ex.prescriptionSummary,
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (ex.restSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'Rest ${ex.restSeconds}s',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              if (exState.skipped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'SKIPPED',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name, style: AppTextStyles.h2),
                    const SizedBox(height: 2),
                    Text(
                      'Target Muscles: ${ex.targetMuscles}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (replacedFrom != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Replaced from: $replacedFrom',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => context.push(
                  '/workouts/exercise/${ex.id}?sessionId=${session.id}',
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Full Guide'),
              ),
            ],
          ),
          if (ex.requiresSupervisionNote ||
              (ex.coachingCue != null && ex.coachingCue!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: ex.requiresSupervisionNote
                    ? AppColors.warningBg
                    : AppColors.limeAccentLight,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(
                  color: (ex.requiresSupervisionNote
                          ? AppColors.warning
                          : AppColors.limeAccentDark)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ex.requiresSupervisionNote
                        ? Icons.shield_outlined
                        : Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: ex.requiresSupervisionNote
                        ? AppColors.warning
                        : AppColors.limeAccentDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ex.coachingCue ??
                          'Use rack safeties or a spotter on challenging working sets.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: AppSpacing.xs),
              leading: const Icon(
                Icons.menu_book_outlined,
                color: AppColors.limeAccentDark,
                size: 20,
              ),
              title: const Text(
                'Instructions & Form Cues',
                style: AppTextStyles.titleMedium,
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(ex.instructions.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ex.instructions[i],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (ex.commonMistakes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Avoid:',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...ex.commonMistakes.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(color: AppColors.error),
                              ),
                              Expanded(
                                child: Text(
                                  m,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousPerformanceCard({
    required ExerciseDetail currentEx,
    required ExerciseLog? prevLog,
    required bool isLoading,
    required PersonalRecord? matchingPr,
  }) {
    return InfoCard(
      title: 'Previous Performance',
      subtitle: 'Reference weights & reps from last logged workout',
      icon: Icons.history_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else if (prevLog == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'No previous session logged for ${currentEx.name}. Target sets are pre-filled from your plan.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            Column(
              children: prevLog.sets.where((s) => s.completed).map((s) {
                final wt = s.weightKg != null
                    ? '${_formatNumericWeight(s.weightKg!)} kg × '
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSubtleBg,
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Set ${s.setNumber}',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            '$wt${s.repsCompleted} reps',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (prevLog.notes != null && prevLog.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Last note: ${prevLog.notes}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
          if (matchingPr != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: AppColors.limeAccentLight,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(
                  color: AppColors.limeAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 18,
                    color: AppColors.limeAccentDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'PR (${matchingPr.recordType}): ${matchingPr.formattedValue}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildActiveSetsCard(_ActiveExerciseState exState) {
    final isTimed = exState.sets.isNotEmpty &&
        exState.sets.first.spec.durationSeconds != null &&
        exState.sets.first.spec.durationSeconds! > 0 &&
        exState.sets.first.spec.targetReps == 0;

    return InfoCard(
      title: 'Set & Rep Tracking',
      subtitle: 'Log completed reps & load — marking a set starts rest timer',
      icon: Icons.check_box_outlined,
      trailing: exState.exercise.restSeconds > 0
          ? TextButton.icon(
              onPressed: () => _startRestTimer(exState.exercise.restSeconds),
              icon: const Icon(Icons.timer_outlined, size: 16),
              label: Text('Rest (${exState.exercise.restSeconds}s)'),
            )
          : null,
      child: Column(
        children: exState.sets.map((set) {
          final targetLabel = set.spec.repRangeLabel != null &&
                  set.spec.repRangeLabel!.isNotEmpty
              ? set.spec.repRangeLabel!
              : (isTimed
                  ? '${set.spec.durationSeconds}s'
                  : '${set.spec.targetReps} reps');

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: set.completed
                  ? AppColors.successBg.withValues(alpha: 0.45)
                  : AppColors.cardSubtleBg,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: set.completed
                    ? AppColors.success.withValues(alpha: 0.5)
                    : AppColors.borderSubtle,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 460;

                final headerBadge = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set ${set.setNumber}',
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      'Target: $targetLabel',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );

                final repsField = TextField(
                  controller: set.repsController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => set.userEdited = true,
                  decoration: InputDecoration(
                    labelText: isTimed ? 'Seconds' : 'Reps',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                );

                final weightField = TextField(
                  controller: set.weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => set.userEdited = true,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                );

                final completeButton = InkWell(
                  onTap: () => _toggleSetCompleted(exState, set),
                  borderRadius: AppRadius.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: set.completed
                          ? AppColors.success
                          : AppColors.limeAccent,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          set.completed
                              ? Icons.check_circle_rounded
                              : Icons.check_rounded,
                          size: 18,
                          color: set.completed
                              ? Colors.white
                              : AppColors.darkCharcoal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          set.completed ? 'Done' : 'Complete Set',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 13,
                            color: set.completed
                                ? Colors.white
                                : AppColors.darkCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: headerBadge),
                          completeButton,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(child: repsField),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: weightField),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(width: 105, child: headerBadge),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: repsField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: weightField),
                    const SizedBox(width: AppSpacing.sm),
                    completeButton,
                  ],
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseActionsCard(FitnessProfile? profile) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex >= _exercises.length - 1;
    final isSkipped = _exercises[_currentIndex].skipped;

    return InfoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SecondaryButton(
            label: 'Previous Exercise',
            icon: Icons.arrow_back_rounded,
            height: 42,
            onPressed:
                isFirst ? null : () => setState(() => _currentIndex--),
          ),
          SecondaryButton(
            label: isSkipped ? 'Unskip Exercise' : 'Skip Exercise',
            icon: Icons.skip_next_rounded,
            height: 42,
            onPressed: _skipCurrentExercise,
          ),
          SecondaryButton(
            label: 'Replace Exercise',
            icon: Icons.swap_horiz_rounded,
            height: 42,
            onPressed: () => _openReplaceExerciseModal(profile),
          ),
          PrimaryButton(
            label: 'Next Exercise',
            icon: Icons.arrow_forward_rounded,
            height: 42,
            onPressed: isLast ? null : () => setState(() => _currentIndex++),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmUpCoolDownCard(WorkoutSession session) {
    return InfoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.self_improvement_rounded,
            color: AppColors.limeAccentDark,
          ),
          title: const Text(
            'Warm-Up & Cool-Down Reference',
            style: AppTextStyles.titleMedium,
          ),
          subtitle: Text(
            '${session.warmUp.length} warm-up • ${session.coolDown.length} cool-down',
            style: AppTextStyles.bodySmall,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.warmUp.isNotEmpty) ...[
                  Text('Warm-Up', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  ...session.warmUp.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${w.name} (${w.prescriptionSummary})',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ],
                if (session.coolDown.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Cool-Down & Recovery', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  ...session.coolDown.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${c.name} (${c.prescriptionSummary})',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishSection(WorkoutSession session) {
    return InfoCard(
      title: 'Session Notes & Effort',
      subtitle: 'Rate perceived difficulty (RPE) and save your workout log',
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Perceived Difficulty (RPE 1–10)',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.roundedFull,
                ),
                child: Text(
                  '$_rpe / 10',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _rpe.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.limeAccentDark,
            label: '$_rpe',
            onChanged: (val) => setState(() => _rpe = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('1 (Very Light)', style: AppTextStyles.caption),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '10 (Max Effort)',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Workout Notes (Optional)',
              hintText:
                  'Note how weights felt, form cues that worked, or energy levels...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Finish Workout',
            icon: Icons.flag_rounded,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: () => _confirmAndFinishWorkout(session),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishSummaryView(
    BuildContext context, {
    required WorkoutLog log,
    required WorkoutSession session,
    required FitnessProfile? profile,
  }) {
    final stopped = log.stoppedDueToDiscomfort;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (stopped ? AppColors.warning : AppColors.limeAccent)
                        .withValues(alpha: 0.2),
                    borderRadius: AppRadius.roundedFull,
                  ),
                  child: Text(
                    stopped ? 'STOPPED SAFELY FOR DISCOMFORT' : 'WORKOUT SAVED',
                    style: AppTextStyles.badge.copyWith(
                      color:
                          stopped ? AppColors.warning : AppColors.limeAccent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  stopped
                      ? 'Session Stopped Safely'
                      : 'Finish Workout Summary',
                  style: AppTextStyles.h2Dark,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  stopped
                      ? 'Your partial workout log for ${log.sessionTitle} has been saved. Prioritizing safety and stopping when you feel discomfort is always the right decision.'
                      : 'Great consistency on ${log.sessionTitle}. Your completed sets and volume have been saved to your training log.',
                  style: AppTextStyles.bodyMediumDark.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.85),
                  ),
                ),
                if (stopped &&
                    log.discomfortNote != null &&
                    log.discomfortNote!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.darkElevated,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Text(
                      'Recorded Note: ${log.discomfortNote}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Summary Metric Cards (responsive, never GridView.count)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900 ? 4 : (width >= 560 ? 2 : 1);
              final cardWidth =
                  (width - (AppSpacing.md * (columns - 1))) / columns;

              final metrics = [
                (
                  label: 'Duration',
                  value: '${log.durationMinutes} min',
                  icon: Icons.timer_outlined,
                ),
                (
                  label: 'Exercises Completed',
                  value:
                      '${log.completedExercisesCount} / ${log.exerciseLogs.length}',
                  icon: Icons.fitness_center_rounded,
                ),
                (
                  label: 'Total Sets Completed',
                  value: '${log.completedSets}',
                  icon: Icons.check_circle_outline_rounded,
                ),
                (
                  label: 'Total Volume',
                  value: '${log.totalVolumeKg.toStringAsFixed(1)} kg',
                  icon: Icons.monitor_weight_outlined,
                ),
              ];

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: metrics.map((m) {
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: AppRadius.roundedLg,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.limeAccent.withValues(alpha: 0.2),
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: Icon(
                              m.icon,
                              color: AppColors.limeAccentDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.value, style: AppTextStyles.h3),
                                Text(m.label, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Truthful No-Wearable / Sensor Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.watch_off_outlined,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Calories burned and heart rate are not displayed because no connected wearable/sensor is configured.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Recovery & Hydration Reminder
          InfoCard(
            title: stopped
                ? 'Next Steps & Safety Reminder'
                : 'Recovery & Hydration Reminder',
            icon: Icons.water_drop_outlined,
            child: Text(
              stopped
                  ? 'Do not train through sharp pain. Rest the affected area, hydrate well, and consult a healthcare professional if discomfort persists before resuming heavy training.'
                  : (session.recoveryGuidance ??
                      'Rehydrate with water, eat a balanced post-workout meal with protein, and aim for 7–9 hours of sleep to support recovery before your next session.'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Post-Workout Navigation Actions
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PrimaryButton(
                label: 'View Workout History',
                icon: Icons.history_rounded,
                onPressed: () => context.go('/workouts/history'),
              ),
              SecondaryButton(
                label: 'View Progress',
                icon: Icons.trending_up_rounded,
                onPressed: () => context.go('/workouts/training-progress'),
              ),
              SecondaryButton(
                label: 'Back to Workouts',
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/workouts'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          TrainingSafetyBanner(
            hasMedicalConcern:
                stopped || (profile?.hasMedicalClearanceNotice ?? false),
            isSampleData: profile?.isSampleData ?? false,
          ),
        ],
      ),
    );
  }
}
