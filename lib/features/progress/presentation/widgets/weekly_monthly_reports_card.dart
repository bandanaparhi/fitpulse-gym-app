import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/attendance_record.dart';
import '../../../../data/models/completed_workout.dart';
import '../../../../data/models/daily_health_log.dart';
import '../../../../data/models/fitness_measurement.dart';
import '../../../../data/models/food_log_entry.dart';

enum ReportPeriod { weekly, monthly }

/// Weekly (7-day) and Monthly (30-day) Progress Report built from live workouts,
/// attendance records, biometric measurements, daily health logs, and nutrition logs.
class WeeklyMonthlyReportsCard extends StatefulWidget {
  final List<FitnessMeasurement> measurements;
  final List<CompletedWorkout> completedWorkouts;
  final List<AttendanceRecord> attendanceRecords;
  final DailyHealthLog dailyHealthLog;
  final List<FoodLogEntry> foodLogs;
  final bool isMetric;

  const WeeklyMonthlyReportsCard({
    super.key,
    required this.measurements,
    required this.completedWorkouts,
    required this.attendanceRecords,
    required this.dailyHealthLog,
    required this.foodLogs,
    required this.isMetric,
  });

  @override
  State<WeeklyMonthlyReportsCard> createState() =>
      _WeeklyMonthlyReportsCardState();
}

class _WeeklyMonthlyReportsCardState extends State<WeeklyMonthlyReportsCard> {
  ReportPeriod _period = ReportPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysWindow = _period == ReportPeriod.weekly ? 7 : 30;
    final cutoff = now.subtract(Duration(days: daysWindow));

    final periodWorkouts = widget.completedWorkouts
        .where((w) => !w.completedAt.isBefore(cutoff))
        .toList();
    final workoutCount = periodWorkouts.length;
    final trainingMinutes = periodWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.durationMinutes,
    );
    final totalVolKg = periodWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalVolumeKg,
    );
    final volumeDisplay = widget.isMetric
        ? '${totalVolKg.toStringAsFixed(0)} kg'
        : '${(totalVolKg * 2.20462).toStringAsFixed(0)} lb';

    final periodAttendance = widget.attendanceRecords
        .where((r) => !r.checkIn.isBefore(cutoff))
        .toList();
    final visitCount = periodAttendance.length;
    final visitMinutes = periodAttendance.fold<int>(
      0,
      (sum, r) => sum + (r.duration?.inMinutes ?? 0),
    );
    final visitHoursStr = visitMinutes >= 60
        ? '${(visitMinutes / 60).toStringAsFixed(1)} hrs'
        : '$visitMinutes mins';

    final sortedMeasures = List<FitnessMeasurement>.from(widget.measurements)
      ..sort((a, b) => a.date.compareTo(b.date));
    final periodMeasures =
        sortedMeasures.where((m) => !m.date.isBefore(cutoff)).toList();

    String weightReportVal = '--';
    String weightReportSub = 'No weight trend yet';
    if (sortedMeasures.isNotEmpty) {
      final latest = sortedMeasures.last;
      final refEntry = periodMeasures.length >= 2
          ? periodMeasures.first
          : (sortedMeasures.length >= 2 ? sortedMeasures.first : latest);
      final diffKg = latest.weightKg - refEntry.weightKg;
      final diffDisplay = widget.isMetric ? diffKg : diffKg * 2.20462;
      final unit = widget.isMetric ? 'kg' : 'lb';
      final sign = diffDisplay > 0 ? '+' : '';
      weightReportVal = '$sign${diffDisplay.toStringAsFixed(1)} $unit';
      weightReportSub = periodMeasures.length >= 2
          ? 'Within selected $daysWindow-day window'
          : 'Overall recorded baseline trend';
    }

    final todayKcal = widget.foodLogs.fold<int>(0, (s, e) => s + e.calories);

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
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.assessment_rounded,
                    color: AppColors.darkCharcoal,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Weekly & Monthly Reports',
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PeriodChip(
                    label: 'Weekly Report',
                    selected: _period == ReportPeriod.weekly,
                    onTap: () => setState(() => _period = ReportPeriod.weekly),
                  ),
                  _PeriodChip(
                    label: 'Monthly Report',
                    selected: _period == ReportPeriod.monthly,
                    onTap: () => setState(() => _period = ReportPeriod.monthly),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _period == ReportPeriod.weekly
                ? 'Summary of your last 7 days of training, check-ins, and body metrics.'
                : 'Summary of your last 30 days of training, check-ins, and body metrics.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _ReportTile(
                  label: 'Workouts ($daysWindow Days)',
                  value: '$workoutCount Sessions',
                  subtitle: '$trainingMinutes mins • $volumeDisplay volume',
                  icon: Icons.bolt_rounded,
                  accent: AppColors.limeAccentDark,
                ),
                _ReportTile(
                  label: 'Gym Attendance',
                  value: '$visitCount Visits',
                  subtitle: '$visitHoursStr active in facility',
                  icon: Icons.event_available_rounded,
                  accent: AppColors.info,
                ),
                _ReportTile(
                  label: 'Weight Shift',
                  value: weightReportVal,
                  subtitle: weightReportSub,
                  icon: Icons.monitor_weight_outlined,
                  accent: AppColors.success,
                ),
                _ReportTile(
                  label: 'Today Wellness & Food',
                  value: '${widget.dailyHealthLog.steps} steps',
                  subtitle:
                      '${widget.dailyHealthLog.caloriesBurned} burned • $todayKcal kcal logged',
                  icon: Icons.local_fire_department_rounded,
                  accent: AppColors.warning,
                ),
              ];

              if (constraints.maxWidth >= 820) {
                return Row(
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: items[1]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: items[2]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: items[3]),
                  ],
                );
              }
              if (constraints.maxWidth >= 520) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: items[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: items[1]),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: items[2]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: items[3]),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  items[0],
                  const SizedBox(height: AppSpacing.sm),
                  items[1],
                  const SizedBox(height: AppSpacing.sm),
                  items[2],
                  const SizedBox(height: AppSpacing.sm),
                  items[3],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                GoRouter.maybeOf(context)?.go('/workouts/training-progress');
              },
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('Open Training Load Analytics'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkCharcoal : AppColors.cardSubtleBg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.darkCharcoal : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _ReportTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
