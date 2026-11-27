import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';
import '../../../../data/models/diet_plan.dart';
import '../../../../data/models/fitness_goal.dart';
import '../../../../data/models/fitness_measurement.dart';
import '../../../../data/models/workout_log.dart';
import '../../../../data/models/workout_session.dart';
import '../../../../shared/widgets/info_card.dart';

/// Card summarizing the member's daily fitness progress across today's workout,
/// gym check-in, latest body weight, nutrition target, and active goal.
class DailyFitnessProgressCard extends StatelessWidget {
  final WorkoutSession? todaySession;
  final List<WorkoutLog> workoutLogs;
  final List<AttendanceRecord> attendanceRecords;
  final List<FitnessMeasurement> measurements;
  final List<FitnessGoal> goals;
  final DietPlan? dietPlan;

  const DailyFitnessProgressCard({
    super.key,
    required this.todaySession,
    required this.workoutLogs,
    required this.attendanceRecords,
    required this.measurements,
    required this.goals,
    required this.dietPlan,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final now = DateTime.now();

    final todayLogs = workoutLogs
        .where((log) => log.isCompleted && _isSameDay(log.startedAt, now))
        .toList();
    final todayWorkoutValue = todayLogs.isNotEmpty
        ? 'Completed (${todayLogs.first.completedSets} sets)'
        : todaySession != null
            ? '${todaySession!.totalExercises} exercises'
            : 'Rest Day';
    final todayWorkoutSub = todayLogs.isNotEmpty
        ? '${todayLogs.first.durationMinutes} min logged'
        : todaySession != null
            ? todaySession!.title
            : 'Recovery & mobility';

    final todayAttendance = attendanceRecords
        .where((r) => _isSameDay(r.checkIn, now))
        .toList();
    final checkInValue = todayAttendance.isNotEmpty ? 'Checked In' : 'Not Checked In';
    final checkInSub = todayAttendance.isNotEmpty
        ? (todayAttendance.first.duration != null
            ? '${todayAttendance.first.duration!.inMinutes} min • ${todayAttendance.first.location}'
            : todayAttendance.first.location)
        : 'Tap to view check-in';

    final sortedMeasurements = List<FitnessMeasurement>.from(measurements)
      ..sort((a, b) => b.date.compareTo(a.date));
    final latestMeasurement =
        sortedMeasurements.isNotEmpty ? sortedMeasurements.first : null;
    final weightValue = latestMeasurement != null
        ? '${latestMeasurement.weightKg.toStringAsFixed(1)} kg'
        : 'Not logged';
    final weightSub = latestMeasurement != null
        ? 'Logged ${AppFormatters.formatShortDate(latestMeasurement.date)}'
        : 'Log body weight';

    final nutritionValue = dietPlan != null
        ? '${dietPlan!.dailyCalorieTarget} kcal'
        : 'No Plan';
    final nutritionSub = dietPlan != null
        ? '${dietPlan!.proteinGrams}g protein target'
        : 'View nutrition';

    final primaryGoal = goals.isNotEmpty ? goals.first : null;

    final tiles = [
      _DailyMetricTile(
        icon: Icons.fitness_center_rounded,
        iconColor: todayLogs.isNotEmpty ? AppColors.success : AppColors.limeAccentDark,
        label: 'Daily Workout',
        value: todayWorkoutValue,
        subtitle: todayWorkoutSub,
        onTap: () => context.go('/workouts/today'),
        isMobile: isMobile,
      ),
      _DailyMetricTile(
        icon: Icons.qr_code_scanner_rounded,
        iconColor: todayAttendance.isNotEmpty ? AppColors.success : AppColors.info,
        label: 'Today Check-In',
        value: checkInValue,
        subtitle: checkInSub,
        onTap: () => context.go('/attendance'),
        isMobile: isMobile,
      ),
      _DailyMetricTile(
        icon: Icons.monitor_weight_outlined,
        iconColor: AppColors.darkCharcoal,
        label: 'Body Weight',
        value: weightValue,
        subtitle: weightSub,
        onTap: () => context.go('/progress'),
        isMobile: isMobile,
      ),
      _DailyMetricTile(
        icon: Icons.restaurant_outlined,
        iconColor: AppColors.warning,
        label: 'Daily Nutrition',
        value: nutritionValue,
        subtitle: nutritionSub,
        onTap: () => context.go('/diet-plan'),
        isMobile: isMobile,
      ),
    ];

    return InfoCard(
      title: 'Daily Fitness Progress',
      subtitle: "Today's workout, check-in, body metrics & nutrition",
      icon: Icons.track_changes_rounded,
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('Progress'),
        onPressed: () => context.go('/progress'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 820;
              final tileGap = isMobile ? AppSpacing.sm : AppSpacing.md;

              if (isDesktop) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < tiles.length; i++) ...[
                        if (i > 0) SizedBox(width: tileGap),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[0]),
                        SizedBox(width: tileGap),
                        Expanded(child: tiles[1]),
                      ],
                    ),
                  ),
                  SizedBox(height: tileGap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[2]),
                        SizedBox(width: tileGap),
                        Expanded(child: tiles[3]),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isMobile ? AppSpacing.sm + 2 : AppSpacing.md),
          if (primaryGoal != null) ...[
            _GoalProgressBanner(goal: primaryGoal, isMobile: isMobile),
          ] else
            InkWell(
              onTap: () => context.go('/progress'),
              borderRadius: AppRadius.roundedMd,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : AppSpacing.md,
                  vertical: isMobile ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: AppColors.limeAccentDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'No fitness goal set yet — tap to set a target on Progress',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;
  final bool isMobile;

  const _DailyMetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scaffoldBackground,
      borderRadius: AppRadius.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.roundedMd,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: isMobile ? 15 : 17, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 10.5 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 5 : 6),
              Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: isMobile ? 10 : 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgressBanner extends StatelessWidget {
  final FitnessGoal goal;
  final bool isMobile;

  const _GoalProgressBanner({
    required this.goal,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progressPercentage * 100).toInt();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : AppSpacing.md,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 15,
                color: AppColors.limeAccentDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Goal: ${goal.title} (${goal.currentValue} → ${goal.targetValue} ${goal.unit})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$pct%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.limeAccentDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              minHeight: 6,
              backgroundColor: AppColors.cardBackground,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.limeAccent),
            ),
          ),
        ],
      ),
    );
  }
}
