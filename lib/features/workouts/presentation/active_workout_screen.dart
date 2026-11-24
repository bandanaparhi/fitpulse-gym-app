import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/completed_workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/primary_button.dart';
import 'workout_completion_screen.dart';

/// Active live workout session screen at `/workouts/:workoutId/start`.
///
/// Features:
/// - Current exercise & instructions
/// - Current set tracker
/// - Previous and next exercise controls
/// - Mark Set Complete button
/// - Rest timer countdown between sets
/// - Complete Workout button with mandatory user confirmation
/// - Saves workout completion status, timestamp, and volume
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const ActiveWorkoutScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  // Track completed sets per exercise: Map<exerciseId, Set<setIndex (1-based)>>
  final Map<String, Set<int>> _completedSets = {};

  // Workout duration timer
  late final Stopwatch _stopwatch;
  Timer? _tickerTimer;
  int _elapsedSeconds = 0;

  // Rest countdown timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  // Completion state
  CompletedWorkout? _completedResult;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = _stopwatch.elapsed.inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = seconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isResting = false;
            _restSecondsRemaining = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _restSecondsRemaining--;
          });
        }
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _addRestSeconds(int seconds) {
    setState(() {
      _restSecondsRemaining += seconds;
    });
  }

  void _markSetComplete(Workout workout, Exercise currentExercise) {
    setState(() {
      final done = _completedSets.putIfAbsent(currentExercise.id, () => {});
      done.add(_currentSet);

      if (_currentSet < currentExercise.sets) {
        // Advance to next set for this exercise
        _currentSet++;
        _startRestTimer(currentExercise.restSeconds);
      } else {
        // All sets for this exercise finished
        if (_currentExerciseIndex < workout.exercises.length - 1) {
          _currentExerciseIndex++;
          _currentSet = 1;
          _startRestTimer(currentExercise.restSeconds);
        } else {
          // Final exercise & set finished
          _promptWorkoutCompletion(workout);
        }
      }
    });
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSet = 1;
        _isResting = false;
      });
    }
  }

  void _nextExercise(Workout workout) {
    if (_currentExerciseIndex < workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
    }
  }

  int _countTotalCompletedSets() {
    return _completedSets.values.fold<int>(0, (sum, sets) => sum + sets.length);
  }

  int _countTotalPlannedSets(Workout workout) {
    return workout.exercises.fold<int>(0, (sum, e) => sum + e.sets);
  }

  double _calculateTotalVolume(Workout workout) {
    double totalKg = 0.0;
    for (final exercise in workout.exercises) {
      final setsDone = _completedSets[exercise.id]?.length ?? 0;
      final weight = exercise.weightKg ?? 20.0;
      totalKg += setsDone * exercise.reps * weight;
    }
    return totalKg;
  }

  Future<void> _promptWorkoutCompletion(Workout workout) async {
    final completedSetsCount = _countTotalCompletedSets();
    final totalPlanned = _countTotalPlannedSets(workout);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Complete Workout?',
      message:
          'You have completed $completedSetsCount of $totalPlanned sets.\nAre you ready to finish and record this workout session?',
      confirmLabel: 'Confirm & Complete',
      cancelLabel: 'Resume Workout',
      isDestructive: false,
    );

    if (confirmed == true && mounted) {
      _finishWorkout(workout);
    }
  }

  void _finishWorkout(Workout workout) {
    _tickerTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();

    final durationMins = (_elapsedSeconds / 60).ceil().clamp(1, 180);
    final completedRecord = CompletedWorkout(
      id: 'COMP-${DateTime.now().millisecondsSinceEpoch}',
      workoutId: workout.id,
      workoutTitle: workout.title,
      category: workout.category,
      completedAt: DateTime.now(),
      durationMinutes: durationMins,
      totalExercises: workout.totalExercises,
      totalSetsCompleted: _countTotalCompletedSets(),
      totalVolumeKg: _calculateTotalVolume(workout),
    );

    // Save completion status to reactive Riverpod provider
    ref
        .read(completedWorkoutsProvider.notifier)
        .addCompletedWorkout(completedRecord);

    setState(() {
      _completedResult = completedRecord;
    });
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // If completed, transition directly to the WorkoutCompletionScreen
    if (_completedResult != null) {
      return WorkoutCompletionScreen(completedWorkout: _completedResult!);
    }

    final workoutAsync = ref.watch(singleWorkoutProvider(widget.workoutId));

    return workoutAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Preparing live workout session...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Launch Workout',
          message: err.toString(),
          onRetry: () =>
              ref.invalidate(singleWorkoutProvider(widget.workoutId)),
        ),
      ),
      data: (workout) {
        if (workout == null || workout.exercises.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(title: const Text('Live Workout')),
            body: Center(
              child: EmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'Workout Not Found',
                message: 'No exercises found for workout ${widget.workoutId}.',
                actionLabel: 'Back to Workouts',
                onAction: () => context.go('/workouts'),
              ),
            ),
          );
        }

        final currentExercise = workout.exercises[_currentExerciseIndex];
        final completedForThisExercise =
            _completedSets[currentExercise.id] ?? <int>{};
        final isSetCompleted = completedForThisExercise.contains(_currentSet);

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Exit Session',
              onPressed: () async {
                final shouldExit = await ConfirmationDialog.show(
                  context,
                  title: 'Exit Workout Session?',
                  message:
                      'Are you sure you want to exit? Your in-progress workout session will not be saved unless confirmed complete.',
                  confirmLabel: 'Exit Session',
                  cancelLabel: 'Keep Going',
                  isDestructive: true,
                );
                if (shouldExit == true && context.mounted) {
                  context.go('/workouts/${workout.id}');
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Exercise ${_currentExerciseIndex + 1} of ${workout.totalExercises}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              // Live Timer Pill
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.limeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(_elapsedSeconds),
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.limeAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // Finish Workout Button
              TextButton(
                onPressed: () => _promptWorkoutCompletion(workout),
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(
            workout: workout,
            currentExercise: currentExercise,
            isSetCompleted: isSetCompleted,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Exercise Progress Bar
                LinearProgressIndicator(
                  value: (_currentExerciseIndex + 1) / workout.totalExercises,
                  backgroundColor: AppColors.borderSubtle,
                  color: AppColors.limeAccentDark,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Active Rest Timer Banner (when active)
                if (_isResting) ...[
                  _buildRestTimerCard(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Current Exercise Card
                _buildCurrentExerciseCard(currentExercise),

                const SizedBox(height: AppSpacing.lg),

                // Set Tracker List
                _buildSetTrackerCard(
                  currentExercise: currentExercise,
                  completedSets: completedForThisExercise,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Instructions Card
                if (currentExercise.instructions != null &&
                    currentExercise.instructions!.isNotEmpty)
                  _buildInstructionsCard(currentExercise.instructions!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestTimerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.snooze_rounded,
              color: AppColors.limeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Time Remaining',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
                Text(
                  '${_restSecondsRemaining}s',
                  style: AppTextStyles.h2Dark.copyWith(
                    color: AppColors.limeAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _addRestSeconds(30),
            child: const Text('+30s'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textOnDark,
              side: const BorderSide(color: AppColors.darkBorder),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            onPressed: _skipRest,
            child: const Text('Skip Rest'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentExerciseCard(Exercise exercise) {
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
                  'CURRENT EXERCISE',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
              Text(
                'Target: ${exercise.targetMuscle}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            exercise.name,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            children: [
              _buildExerciseAttribute(
                label: 'Current Set',
                value: 'Set $_currentSet of ${exercise.sets}',
              ),
              _buildExerciseAttribute(
                label: 'Target Reps',
                value: '${exercise.reps} reps',
              ),
              if (exercise.weightKg != null)
                _buildExerciseAttribute(
                  label: 'Recommended Weight',
                  value: '${exercise.weightKg!.toStringAsFixed(1)} kg',
                ),
              _buildExerciseAttribute(
                label: 'Rest Duration',
                value: '${exercise.restSeconds}s',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseAttribute({
    required String label,
    required String value,
  }) {
    return Column(
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
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSetTrackerCard({
    required Exercise currentExercise,
    required Set<int> completedSets,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sets Progress',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                '${completedSets.length} / ${currentExercise.sets} Sets Completed',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.limeAccentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: List.generate(currentExercise.sets, (index) {
              final setNumber = index + 1;
              final isDone = completedSets.contains(setNumber);
              final isCurrent = setNumber == _currentSet && !isDone;

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.limeAccent.withValues(alpha: 0.12)
                      : isDone
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.limeAccentDark
                        : isDone
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.limeAccentDark
                                : AppColors.borderSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '$setNumber',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Set $setNumber • ${currentExercise.reps} reps ${currentExercise.weightKg != null ? '@ ${currentExercise.weightKg} kg' : ''}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      isDone
                          ? 'Done'
                          : isCurrent
                              ? 'Active Set'
                              : 'Pending',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDone
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.limeAccentDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(String instructions) {
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
            children: const [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Coaching Form Cues',
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            instructions,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({
    required Workout workout,
    required Exercise currentExercise,
    required bool isSetCompleted,
  }) {
    final hasPrevious = _currentExerciseIndex > 0;
    final hasNext = _currentExerciseIndex < workout.exercises.length - 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top action: Mark Set Complete button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: isSetCompleted
                    ? 'Next Set (${_currentSet < currentExercise.sets ? 'Set ${_currentSet + 1}' : 'Next Exercise'})'
                    : 'Mark Set $_currentSet Complete',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => _markSetComplete(workout, currentExercise),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Exercise Navigation Row: Previous Exercise, Complete Workout, Next Exercise
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous Ex'),
                    onPressed: hasPrevious ? _previousExercise : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => _promptWorkoutCompletion(workout),
                    child: const Text('Finish Workout'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Next Ex'),
                    onPressed: hasNext ? () => _nextExercise(workout) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
