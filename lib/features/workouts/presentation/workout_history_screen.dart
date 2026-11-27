import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/workout_log.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/summary_card.dart';
import 'widgets/training_safety_banner.dart';

/// Filter options for [WorkoutHistoryScreen].
enum _HistoryFilter {
  all('All'),
  completed('Completed'),
  stoppedDiscomfort('Stopped (Discomfort)');

  final String label;
  const _HistoryFilter(this.label);
}

/// Chronological log of completed & stopped personalized workout sessions
/// at `/workouts/history`.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  _HistoryFilter _selectedFilter = _HistoryFilter.all;
  final Set<String> _expandedLogIds = <String>{};

  void _toggleExpanded(String logId) {
    setState(() {
      if (_expandedLogIds.contains(logId)) {
        _expandedLogIds.remove(logId);
      } else {
        _expandedLogIds.add(logId);
      }
    });
  }

  Future<void> _confirmDelete(WorkoutLog log) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Workout Log',
      message:
          'Remove "${log.sessionTitle}" logged on ${AppFormatters.formatShortDate(log.startedAt)}? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(workoutLogsProvider.notifier).deleteLog(log.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout log removed from history.')),
    );
  }

  String _formatVolume(double kg) {
    if (kg == kg.roundToDouble()) {
      return '${kg.toInt()} kg';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(workoutLogsProvider);
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);

    final planTarget = planAsync.value?.trainingDaysPerWeek ?? 0;
    final hasMedicalConcern =
        profileAsync.value?.hasMedicalClearanceNotice ?? false;

    return logsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading workout history...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Workout History',
          message: err.toString(),
          onRetry: () => ref.invalidate(workoutLogsProvider),
        ),
      ),
      data: (logs) {
        final sortedLogs = List<WorkoutLog>.from(logs)
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        final now = DateTime.now();
        final weekCutoff = now.subtract(const Duration(days: 7));
        final weeklyCompleted = sortedLogs
            .where((l) =>
                l.startedAt.isAfter(weekCutoff) &&
                l.isCompleted &&
                !l.stoppedDueToDiscomfort)
            .length;

        final totalSets =
            sortedLogs.fold<int>(0, (sum, l) => sum + l.completedSets);
        final totalVolume =
            sortedLogs.fold<double>(0.0, (sum, l) => sum + l.totalVolumeKg);
        final avgRpe = sortedLogs.isEmpty
            ? 0.0
            : sortedLogs.fold<int>(0, (sum, l) => sum + l.perceivedDifficulty) /
                sortedLogs.length;

        final filteredLogs = sortedLogs.where((log) {
          switch (_selectedFilter) {
            case _HistoryFilter.all:
              return true;
            case _HistoryFilter.completed:
              return log.isCompleted && !log.stoppedDueToDiscomfort;
            case _HistoryFilter.stoppedDiscomfort:
              return log.stoppedDueToDiscomfort;
          }
        }).toList();

        final hasSampleData = sortedLogs.any((l) => l.isSampleData);

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Workout History',
                  subtitle:
                      'Review completed sessions, exercise sets, perceived effort, and weekly training consistency.',
                ),
                const PlannerNavStrip(currentPath: '/workouts/history'),
                const SizedBox(height: AppSpacing.lg),

                // Weekly Consistency & Volume Summary
                _WeeklyConsistencyRow(
                  weeklyCompleted: weeklyCompleted,
                  planTarget: planTarget,
                  totalSets: totalSets,
                  totalVolumeText: _formatVolume(totalVolume),
                  avgRpeText: sortedLogs.isEmpty
                      ? '—'
                      : '${avgRpe.toStringAsFixed(1)}/10',
                  sessionCount: sortedLogs.length,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Filter Chips
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _HistoryFilter.values.map((filter) {
                    final selected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(
                        filter.label,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.darkCharcoal
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.limeAccent,
                      backgroundColor: AppColors.cardBackground,
                      side: BorderSide(
                        color: selected
                            ? AppColors.limeAccentDark
                            : AppColors.borderSubtle,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Logs List or Empty State
                if (filteredLogs.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: AppRadius.roundedLg,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: sortedLogs.isEmpty
                          ? 'No Workouts Logged Yet'
                          : 'No Matching Sessions',
                      message: sortedLogs.isEmpty
                          ? 'Start your scheduled session to log sets, weights, and perceived effort.'
                          : 'No workout entries match the "${_selectedFilter.label}" filter.',
                      actionLabel: sortedLogs.isEmpty
                          ? 'Go to Today\'s Workout'
                          : 'Show All Logs',
                      onAction: () {
                        if (sortedLogs.isEmpty) {
                          context.go('/workouts/today');
                        } else {
                          setState(() => _selectedFilter = _HistoryFilter.all);
                        }
                      },
                    ),
                  )
                else
                  Column(
                    children: filteredLogs.map((log) {
                      final isExpanded = _expandedLogIds.contains(log.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _WorkoutLogEntryCard(
                          log: log,
                          isExpanded: isExpanded,
                          volumeText: _formatVolume(log.totalVolumeKg),
                          onToggleExpand: () => _toggleExpanded(log.id),
                          onDelete: () => _confirmDelete(log),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppSpacing.md),
                TrainingSafetyBanner(
                  hasMedicalConcern: hasMedicalConcern,
                  isSampleData: hasSampleData,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyConsistencyRow extends StatelessWidget {
  final int weeklyCompleted;
  final int planTarget;
  final int totalSets;
  final String totalVolumeText;
  final String avgRpeText;
  final int sessionCount;

  const _WeeklyConsistencyRow({
    required this.weeklyCompleted,
    required this.planTarget,
    required this.totalSets,
    required this.totalVolumeText,
    required this.avgRpeText,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final targetDisplay = planTarget > 0 ? '$weeklyCompleted / $planTarget' : '$weeklyCompleted';
    final targetSubtitle = planTarget > 0
        ? 'Last 7 days vs $planTarget/wk target'
        : 'Logged in last 7 days';

    final cards = [
      SummaryCard(
        label: 'Workouts (7d)',
        value: targetDisplay,
        subtitle: targetSubtitle,
        icon: Icons.event_available_rounded,
        iconColor: AppColors.limeAccentDark,
        iconBgColor: AppColors.limeAccent.withValues(alpha: 0.2),
      ),
      SummaryCard(
        label: 'Total Sets',
        value: '$totalSets',
        subtitle: 'Across $sessionCount sessions',
        icon: Icons.repeat_rounded,
        iconColor: AppColors.info,
        iconBgColor: AppColors.infoBg,
      ),
      SummaryCard(
        label: 'Total Volume',
        value: totalVolumeText,
        subtitle: 'Completed sets load',
        icon: Icons.fitness_center_rounded,
        iconColor: AppColors.darkCharcoal,
        iconBgColor: AppColors.cardSubtleBg,
      ),
      SummaryCard(
        label: 'Avg Difficulty',
        value: avgRpeText,
        subtitle: 'Perceived effort (RPE)',
        icon: Icons.speed_rounded,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.warningBg,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: AppSpacing.md),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WorkoutLogEntryCard extends StatelessWidget {
  final WorkoutLog log;
  final bool isExpanded;
  final String volumeText;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;

  const _WorkoutLogEntryCard({
    required this.log,
    required this.isExpanded,
    required this.volumeText,
    required this.onToggleExpand,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(
          color: log.stoppedDueToDiscomfort
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Title + Badges + Delete Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.sessionTitle, style: AppTextStyles.titleLarge),
                    if (log.focus.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        log.focus,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                tooltip: 'Delete workout log',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Status & Sample Pills
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _PillBadge(
                label: log.stoppedDueToDiscomfort
                    ? 'Stopped (Discomfort)'
                    : (log.isCompleted ? 'Completed' : 'Partial'),
                bgColor: log.stoppedDueToDiscomfort
                    ? AppColors.warningBg
                    : AppColors.successBg,
                textColor: log.stoppedDueToDiscomfort
                    ? AppColors.warning
                    : AppColors.success,
                icon: log.stoppedDueToDiscomfort
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              if (log.isSampleData)
                const _PillBadge(
                  label: 'SAMPLE DATA',
                  bgColor: AppColors.cardSubtleBg,
                  textColor: AppColors.textSecondary,
                  borderColor: AppColors.borderSubtle,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Metrics Strip
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricChip(
                icon: Icons.calendar_today_outlined,
                text:
                    '${AppFormatters.formatShortDate(log.startedAt)} • ${AppFormatters.formatTime(log.startedAt)}',
              ),
              _MetricChip(
                icon: Icons.timer_outlined,
                text: '${log.durationMinutes} min',
              ),
              _MetricChip(
                icon: Icons.layers_outlined,
                text: '${log.completedSets} sets',
              ),
              _MetricChip(
                icon: Icons.fitness_center_rounded,
                text: volumeText,
              ),
              _MetricChip(
                icon: Icons.speed_rounded,
                text: 'RPE ${log.perceivedDifficulty}/10',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Expand / Collapse Breakdown Button
          InkWell(
            onTap: onToggleExpand,
            borderRadius: AppRadius.roundedSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.darkCharcoal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isExpanded
                          ? 'Hide Exercise Breakdown (${log.exerciseLogs.length})'
                          : 'View Exercise Breakdown (${log.exerciseLogs.length})',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            if (log.stoppedDueToDiscomfort &&
                log.discomfortNote != null &&
                log.discomfortNote!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Discomfort note: ${log.discomfortNote!}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (log.generalNotes != null &&
                log.generalNotes!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Notes: ${log.generalNotes!}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (log.exerciseLogs.isEmpty)
              Text(
                'No individual exercises recorded for this session.',
                style: AppTextStyles.bodySmall,
              )
            else
              Column(
                children: log.exerciseLogs
                    .map((exLog) => _ExerciseBreakdownTile(exLog: exLog))
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseBreakdownTile extends StatelessWidget {
  final ExerciseLog exLog;

  const _ExerciseBreakdownTile({required this.exLog});

  String _formatSet(SetLog s) {
    final weight = s.weightKg;
    final wtStr = weight != null && weight > 0
        ? '${weight == weight.roundToDouble() ? weight.toInt() : weight.toStringAsFixed(1)} kg × '
        : '';
    final statusSuffix = s.skipped
        ? ' (skipped)'
        : (!s.completed ? ' (incomplete)' : '');
    return 'Set ${s.setNumber}: $wtStr${s.repsCompleted} reps$statusSuffix';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                exLog.exerciseName,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
              ),
              if (exLog.skipped)
                const _PillBadge(
                  label: 'Skipped',
                  bgColor: AppColors.warningBg,
                  textColor: AppColors.warning,
                ),
              if (exLog.replacedFromName != null &&
                  exLog.replacedFromName!.isNotEmpty)
                _PillBadge(
                  label: 'Replaced ${exLog.replacedFromName}',
                  bgColor: AppColors.infoBg,
                  textColor: AppColors.info,
                ),
            ],
          ),
          if (exLog.targetMuscles.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              exLog.targetMuscles,
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: exLog.sets.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(
                    color: s.completed
                        ? AppColors.limeAccentDark.withValues(alpha: 0.4)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  _formatSet(s),
                  style: AppTextStyles.caption.copyWith(
                    color: s.completed
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (exLog.notes != null && exLog.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              exLog.notes!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetricChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;

  const _PillBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedFull,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: textColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
