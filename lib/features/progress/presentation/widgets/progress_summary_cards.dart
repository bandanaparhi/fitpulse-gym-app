import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/completed_workout.dart';
import '../../../../data/models/fitness_measurement.dart';
import '../../../../shared/widgets/summary_card.dart';

/// Summary KPI Cards for Fitness Progress (Body Weight, Body Fat, Workout Volume, Attendance).
class ProgressSummaryCards extends StatelessWidget {
  final List<FitnessMeasurement> measurements;
  final List<CompletedWorkout> completedWorkouts;
  final int attendanceThisMonth;
  final bool isMetric;

  const ProgressSummaryCards({
    super.key,
    required this.measurements,
    required this.completedWorkouts,
    required this.attendanceThisMonth,
    required this.isMetric,
  });

  @override
  Widget build(BuildContext context) {
    // Latest measurement (sorted by date ascending, so last is newest)
    final latest = measurements.isNotEmpty ? measurements.last : null;
    final first = measurements.isNotEmpty ? measurements.first : null;

    // Weight formatting
    String weightDisplay = '--';
    String weightDelta = 'No records';
    if (latest != null) {
      if (isMetric) {
        weightDisplay = '${latest.weightKg.toStringAsFixed(1)} kg';
        if (first != null && measurements.length > 1) {
          final diff = latest.weightKg - first.weightKg;
          final sign = diff > 0 ? '+' : '';
          weightDelta = '$sign${diff.toStringAsFixed(1)} kg since initial';
        } else {
          weightDelta = 'Current baseline';
        }
      } else {
        weightDisplay = '${latest.weightLb.toStringAsFixed(1)} lb';
        if (first != null && measurements.length > 1) {
          final diff = latest.weightLb - first.weightLb;
          final sign = diff > 0 ? '+' : '';
          weightDelta = '$sign${diff.toStringAsFixed(1)} lb since initial';
        } else {
          weightDelta = 'Current baseline';
        }
      }
    }

    // Body fat formatting
    String bodyFatDisplay = '--';
    String bodyFatDelta = 'No records';
    if (latest?.bodyFatPercentage != null) {
      bodyFatDisplay = '${latest!.bodyFatPercentage!.toStringAsFixed(1)}%';
      if (first?.bodyFatPercentage != null && measurements.length > 1) {
        final diff = latest.bodyFatPercentage! - first!.bodyFatPercentage!;
        final sign = diff > 0 ? '+' : '';
        bodyFatDelta = '$sign${diff.toStringAsFixed(1)}% since initial';
      } else {
        bodyFatDelta = 'Current baseline';
      }
    }

    // Workouts volume
    final totalSessions = completedWorkouts.length;
    final totalVolumeKg = completedWorkouts.fold<double>(
      0.0,
      (sum, w) => sum + w.totalVolumeKg,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;
        final isTablet = width >= 600 && width < 900;

        final cardWeight = SummaryCard(
          label: 'Current Weight',
          value: weightDisplay,
          subtitle: weightDelta,
          icon: Icons.monitor_weight_outlined,
          iconColor: AppColors.limeAccentDark,
          iconBgColor: AppColors.limeAccent.withValues(alpha: 0.15),
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              isMetric ? 'KG' : 'LB',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.limeAccentDark,
                fontSize: 10,
              ),
            ),
          ),
        );

        final cardBodyFat = SummaryCard(
          label: 'Body Fat Percentage',
          value: bodyFatDisplay,
          subtitle: bodyFatDelta,
          icon: Icons.pie_chart_outline_rounded,
          iconColor: AppColors.info,
          iconBgColor: AppColors.info.withValues(alpha: 0.12),
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'BIO',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.info,
                fontSize: 10,
              ),
            ),
          ),
        );

        final cardWorkouts = SummaryCard(
          label: 'Workouts Completed',
          value: '$totalSessions Sessions',
          subtitle: '${(totalVolumeKg / 1000).toStringAsFixed(1)}k kg volume lifted',
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.warning,
          iconBgColor: AppColors.warning.withValues(alpha: 0.12),
        );

        final cardAttendance = SummaryCard(
          label: 'Monthly Attendance',
          value: '$attendanceThisMonth Visits',
          subtitle: 'Consistency: Regular Member',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.limeAccentDark,
          iconBgColor: AppColors.limeAccent.withValues(alpha: 0.15),
        );

        if (isDesktop) {
          return Row(
            children: [
              Expanded(child: cardWeight),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardBodyFat),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardWorkouts),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardAttendance),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardWeight),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardBodyFat),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: cardWorkouts),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardAttendance),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardWeight),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cardBodyFat),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: cardWorkouts),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cardAttendance),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}
