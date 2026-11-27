import 'package:fl_chart/fl_chart.dart';
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
import '../../../data/models/workout_plan.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/training_safety_banner.dart';

enum _WeeklyChartMetric { sessions, volume }

/// Weekly Consistency, Volume, and Safe Progression Analytics screen
/// at `/workouts/training-progress`.
class TrainingProgressScreen extends ConsumerStatefulWidget {
  const TrainingProgressScreen({super.key});

  @override
  ConsumerState<TrainingProgressScreen> createState() =>
      _TrainingProgressScreenState();
}

class _TrainingProgressScreenState
    extends ConsumerState<TrainingProgressScreen> {
  _WeeklyChartMetric _chartMetric = _WeeklyChartMetric.sessions;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(workoutLogsProvider);
    final planAsync = ref.watch(activeWorkoutPlanProvider);
    final suggestionsAsync = ref.watch(progressionSuggestionsProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);

    return logsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading training progress...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Training Progress',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(workoutLogsProvider);
            ref.invalidate(progressionSuggestionsProvider);
          },
        ),
      ),
      data: (logs) {
        final plan = planAsync.value;
        final profile = profileAsync.value;
        final hasMedicalConcern =
            profile?.hasMedicalClearanceNotice ?? false;
        final hasSampleData = logs.any((l) => l.isSampleData) ||
            (plan?.isSampleData ?? false) ||
            (profile?.isSampleData ?? false);

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Training Progress & Load',
                  subtitle:
                      'Monitor weekly consistency, training volume, and multi-session safe progression cues.',
                ),
                const PlannerNavStrip(
                  currentPath: '/workouts/training-progress',
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. Weekly Consistency & Volume BarChart
                _WeeklyConsistencyChartCard(
                  logs: logs,
                  plan: plan,
                  metric: _chartMetric,
                  onMetricChanged: (m) => setState(() => _chartMetric = m),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Safe Progression Recommendations
                _SafeProgressionSection(suggestionsAsync: suggestionsAsync),
                const SizedBox(height: AppSpacing.lg),

                // 3. Schedule & Equipment Adjustment + Recovery Guidance
                LayoutBuilder(
                  builder: (context, constraints) {
                    final adjustmentCard = _ProfileAdjustmentCard(
                      profile: profile,
                      onAdjust: () => context.go('/workouts/profile'),
                    );
                    const recoveryCard = _RecoveryWellnessCard();

                    if (constraints.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: adjustmentCard),
                          const SizedBox(width: AppSpacing.lg),
                          const Expanded(child: recoveryCard),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        adjustmentCard,
                        const SizedBox(height: AppSpacing.lg),
                        recoveryCard,
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),
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

class _WeekBucket {
  final DateTime weekStart;
  final String label;
  final int sessionsCount;
  final double totalVolumeKg;

  const _WeekBucket({
    required this.weekStart,
    required this.label,
    required this.sessionsCount,
    required this.totalVolumeKg,
  });
}

class _WeeklyConsistencyChartCard extends StatelessWidget {
  final List<WorkoutLog> logs;
  final WorkoutPlan? plan;
  final _WeeklyChartMetric metric;
  final ValueChanged<_WeeklyChartMetric> onMetricChanged;

  const _WeeklyConsistencyChartCard({
    required this.logs,
    required this.plan,
    required this.metric,
    required this.onMetricChanged,
  });

  List<_WeekBucket> _buildWeeklyBuckets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));

    const numWeeks = 4;
    final buckets = <_WeekBucket>[];
    for (int i = numWeeks - 1; i >= 0; i--) {
      final weekStart = currentMonday.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekLogs = logs.where((l) {
        final d = l.startedAt;
        return !d.isBefore(weekStart) && d.isBefore(weekEnd);
      }).toList();

      final completedCount = weekLogs
          .where((l) => l.isCompleted && !l.stoppedDueToDiscomfort)
          .length;
      final volume =
          weekLogs.fold<double>(0.0, (sum, l) => sum + l.totalVolumeKg);

      final shortLabel = i == 0
          ? 'This Wk'
          : AppFormatters.formatShortDate(weekStart).split(',')[0];

      buckets.add(
        _WeekBucket(
          weekStart: weekStart,
          label: shortLabel,
          sessionsCount: completedCount,
          totalVolumeKg: volume,
        ),
      );
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final targetPerWeek = plan?.trainingDaysPerWeek ?? 0;
    final hasSample = logs.any((l) => l.isSampleData);
    final buckets = _buildWeeklyBuckets();

    final isSessions = metric == _WeeklyChartMetric.sessions;
    final rawMax = buckets.fold<double>(
      0,
      (m, b) {
        final v = isSessions ? b.sessionsCount.toDouble() : b.totalVolumeKg;
        return v > m ? v : m;
      },
    );
    final maxY = isSessions
        ? ((rawMax > targetPerWeek ? rawMax : targetPerWeek.toDouble()) + 1)
            .clamp(4.0, 10.0)
        : (rawMax <= 0 ? 1000.0 : (rawMax * 1.25));

    return InfoCard(
      title: 'Weekly Consistency & Volume',
      subtitle: targetPerWeek > 0
          ? 'Planned target: $targetPerWeek sessions / week'
          : 'Recent 4-week training trend',
      icon: Icons.bar_chart_rounded,
      trailing: hasSample
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: AppRadius.roundedFull,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'SAMPLE DATA',
                style: AppTextStyles.badge.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text(
                  'Sessions',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSessions
                        ? AppColors.darkCharcoal
                        : AppColors.textPrimary,
                  ),
                ),
                selected: isSessions,
                selectedColor: AppColors.limeAccent,
                backgroundColor: AppColors.cardSubtleBg,
                side: BorderSide(
                  color: isSessions
                      ? AppColors.limeAccentDark
                      : AppColors.borderSubtle,
                ),
                onSelected: (_) => onMetricChanged(_WeeklyChartMetric.sessions),
              ),
              ChoiceChip(
                label: Text(
                  'Volume (kg)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: !isSessions
                        ? AppColors.darkCharcoal
                        : AppColors.textPrimary,
                  ),
                ),
                selected: !isSessions,
                selectedColor: AppColors.limeAccent,
                backgroundColor: AppColors.cardSubtleBg,
                side: BorderSide(
                  color: !isSessions
                      ? AppColors.limeAccentDark
                      : AppColors.borderSubtle,
                ),
                onSelected: (_) => onMetricChanged(_WeeklyChartMetric.volume),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (logs.isEmpty)
            const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No Logged Sessions Yet',
              message:
                  'Complete and log workouts to visualize your weekly session consistency and training volume.',
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: isSessions ? 1 : (maxY / 4),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.borderSubtle.withValues(alpha: 0.7),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.borderSubtle),
                      left: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              buckets[idx].label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isSessions ? 28 : 48,
                        interval: isSessions ? 1 : (maxY / 4),
                        getTitlesWidget: (value, meta) {
                          if (value < 0) return const SizedBox.shrink();
                          final text = isSessions
                              ? value.toInt().toString()
                              : '${value.toInt()}';
                          return Text(
                            text,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bucket = buckets[group.x];
                        final detail = isSessions
                            ? '${bucket.sessionsCount} sessions'
                            : '${bucket.totalVolumeKg.toStringAsFixed(0)} kg';
                        return BarTooltipItem(
                          '${bucket.label}\n$detail',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: List.generate(buckets.length, (index) {
                    final b = buckets[index];
                    final y = isSessions
                        ? b.sessionsCount.toDouble()
                        : b.totalVolumeKg;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: y,
                          width: 24,
                          color: y > 0
                              ? AppColors.limeAccent
                              : AppColors.borderSubtle,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.sm),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: AppColors.cardSubtleBg,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SafeProgressionSection extends StatelessWidget {
  final AsyncValue<List<ProgressionSuggestion>> suggestionsAsync;

  const _SafeProgressionSection({required this.suggestionsAsync});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Safe Progression Recommendations',
      subtitle:
          'Multi-session load evaluation based on completed sets and controlled effort',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Progression is only suggested after >= 2 clean logged sessions—never automatically after a single workout.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          suggestionsAsync.when(
            loading: () => const LoadingIndicator(
              message: 'Evaluating progression readiness...',
            ),
            error: (err, _) => ErrorState(
              title: 'Unable to Evaluate Progression',
              message: err.toString(),
            ),
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return const EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'No Tracked Exercises Yet',
                  message:
                      'Log at least two clean sessions for an exercise to unlock safe load progression cues.',
                );
              }
              return Column(
                children: suggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ProgressionSuggestionTile(suggestion: s),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressionSuggestionTile extends StatelessWidget {
  final ProgressionSuggestion suggestion;

  const _ProgressionSuggestionTile({required this.suggestion});

  String _formatWeight(double kg) {
    return kg == kg.roundToDouble()
        ? '${kg.toInt()} kg'
        : '${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final ready = suggestion.readyToProgress;
    final badgeBg =
        ready ? AppColors.limeAccentLight : AppColors.infoBg;
    final badgeBorder = ready
        ? AppColors.limeAccentDark.withValues(alpha: 0.4)
        : AppColors.info.withValues(alpha: 0.35);
    final badgeTextColor =
        ready ? AppColors.limeAccentDark : AppColors.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: ready
              ? AppColors.limeAccentDark.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
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
                suggestion.exerciseName,
                style: AppTextStyles.titleMedium,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: AppRadius.roundedFull,
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  ready ? 'Ready to Progress' : 'Hold & Consolidate',
                  style: AppTextStyles.badge.copyWith(
                    color: badgeTextColor,
                    fontSize: 10,
                  ),
                ),
              ),
              if (suggestion.currentWeightKg != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    'Current: ${_formatWeight(suggestion.currentWeightKg!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            suggestion.recommendation,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suggestion.rationale,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAdjustmentCard extends StatelessWidget {
  final FitnessProfile? profile;
  final VoidCallback onAdjust;

  const _ProfileAdjustmentCard({
    required this.profile,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Schedule & Equipment Adjustment',
      subtitle: 'Keep your weekly split aligned with your routine',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule or equipment changed? Update your Fitness Profile to adapt your weekly split safely.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _ProfilePill(label: '${profile!.trainingDaysPerWeek} days/week'),
                _ProfilePill(
                  label: '${profile!.workoutDurationMinutes} min/session',
                ),
                _ProfilePill(label: profile!.workoutLocation),
                _ProfilePill(label: profile!.fitnessLevel),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Update Fitness Profile',
            icon: Icons.edit_outlined,
            height: 42,
            onPressed: onAdjust,
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  final String label;

  const _ProfilePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: AppRadius.roundedFull,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecoveryWellnessCard extends StatelessWidget {
  const _RecoveryWellnessCard();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Recovery, Sleep & Hydration Guidance',
      subtitle: 'General fitness guidance — not medical advice',
      icon: Icons.spa_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: AppRadius.roundedFull,
        ),
        child: Text(
          'General Guidance',
          style: AppTextStyles.badge.copyWith(
            fontSize: 10,
            color: AppColors.info,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuidanceItem(
            icon: Icons.hotel_class_outlined,
            title: 'Rest Days Between Demanding Sessions',
            body:
                'Use your scheduled rest or light-mobility days to let hard-worked muscle groups recover before repeating high-effort lifts.',
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidanceItem(
            icon: Icons.bedtime_outlined,
            title: '7–9 Hours of Sleep',
            body:
                'Consistent 7–9 hour sleep windows support energy, focus, and healthy training adaptation across the week.',
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidanceItem(
            icon: Icons.water_drop_outlined,
            title: 'Steady Hydration',
            body:
                'Sip water steadily throughout the day and rehydrate after training sessions to support performance and comfort.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Note: These habits are general fitness guidance and are not medical advice.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GuidanceItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.limeAccent.withValues(alpha: 0.16),
            borderRadius: AppRadius.roundedSm,
          ),
          child: Icon(icon, size: 16, color: AppColors.limeAccentDark),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(
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
