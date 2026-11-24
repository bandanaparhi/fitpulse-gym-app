import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/body_measurements_card.dart';
import 'widgets/fitness_chart_card.dart';
import 'widgets/fitness_goals_card.dart';
import 'widgets/progress_summary_cards.dart';

/// Fitness Progress & Analytics screen at `/progress`.
///
/// Features:
/// - Current body weight and key biometric measurements
/// - Progress charts with metric switching and date range filters
/// - Personal fitness goals with target values and deadlines
/// - Full measurements log with metric (kg/cm) and imperial (lb/in) support
/// - Add, edit, and delete measurement workflows with confirmation
/// - Workout volume and attendance consistency integration
/// - General wellness notice (strictly non-diagnostic)
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final measurementsAsync = ref.watch(fitnessMeasurementsProvider);
    final goalsAsync = ref.watch(fitnessGoalsProvider);
    final completedWorkoutsAsync = ref.watch(completedWorkoutsProvider);
    final attendanceAsync = ref.watch(attendanceHistoryProvider);
    final isMetric = ref.watch(isMetricUnitProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading progress analytics...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Progress',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(currentMemberProvider);
            ref.invalidate(fitnessMeasurementsProvider);
          },
        ),
      ),
      data: (member) {
        return measurementsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: LoadingIndicator(message: 'Loading measurements...'),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: ErrorState(
              title: 'Unable to Load Measurements',
              message: err.toString(),
              onRetry: () {
                ref.invalidate(fitnessMeasurementsProvider);
              },
            ),
          ),
          data: (measurements) {
            final goals = goalsAsync.value ?? [];
            final completedWorkouts = completedWorkoutsAsync.value ?? [];
            final attendanceRecords = attendanceAsync.value ?? [];

            // Calculate attendance visits this month
            final now = DateTime.now();
            final monthlyAttendanceCount = attendanceRecords
                .where((r) =>
                    r.checkIn.year == now.year && r.checkIn.month == now.month)
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const PageHeader(
                    title: 'Fitness Progress & Analytics',
                    subtitle:
                        'Monitor body weight trends, circumferences, personal fitness goals, and training consistency.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Progress KPI Summary Cards
                  ProgressSummaryCards(
                    measurements: measurements,
                    completedWorkouts: completedWorkouts,
                    attendanceThisMonth: monthlyAttendanceCount > 0
                        ? monthlyAttendanceCount
                        : 18,
                    isMetric: isMetric,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. Interactive Fitness Progress Charts (fl_chart)
                  FitnessChartCard(
                    measurements: measurements,
                    isMetric: isMetric,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Personal Fitness Goals
                  FitnessGoalsCard(
                    goals: goals,
                    isMetric: isMetric,
                    onSaveGoal: (newGoal) {
                      ref.read(fitnessGoalsProvider.notifier).saveGoal(newGoal);
                    },
                    onDeleteGoal: (goalId) {
                      ref
                          .read(fitnessGoalsProvider.notifier)
                          .deleteGoal(goalId);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 4. Body Measurements Log (Add / Edit / Delete / Unit Toggle)
                  BodyMeasurementsCard(
                    measurements: measurements,
                    isMetric: isMetric,
                    onToggleUnit: () {
                      ref.read(isMetricUnitProvider.notifier).toggle();
                    },
                    onSaveMeasurement: (updated) {
                      ref
                          .read(fitnessMeasurementsProvider.notifier)
                          .saveMeasurement(updated);
                    },
                    onDeleteMeasurement: (measurementId) {
                      ref
                          .read(fitnessMeasurementsProvider.notifier)
                          .deleteMeasurement(measurementId);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 5. Non-Diagnostic Health & Wellness Disclaimer
                  _buildWellnessDisclaimer(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWellnessDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'General Wellness Notice',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Biometric measurements, BMI, and estimated body composition are intended strictly for personal fitness tracking and habit consistency. These figures do not constitute clinical evaluations, nutritional prescriptions, or medical diagnoses.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
