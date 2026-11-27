import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../data/models/daily_health_log.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/before_after_photos_card.dart';
import 'widgets/bmi_bmr_calculator_card.dart';
import 'widgets/body_measurements_card.dart';
import 'widgets/daily_health_trackers_card.dart';
import 'widgets/fitness_chart_card.dart';
import 'widgets/fitness_goals_card.dart';
import 'widgets/muscle_growth_card.dart';
import 'widgets/personal_records_summary_card.dart';
import 'widgets/progress_summary_cards.dart';
import 'widgets/weekly_monthly_reports_card.dart';

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
    final fitnessProfileAsync = ref.watch(fitnessProfileProvider);
    final dailyHealthAsync = ref.watch(dailyHealthLogProvider);
    final foodLogsAsync = ref.watch(foodLogsProvider);
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
            final fitnessProfile = fitnessProfileAsync.value;
            final dailyHealth =
                dailyHealthAsync.value ?? const DailyHealthLog(dateKey: '');
            final foodLogs = foodLogsAsync.value ?? [];
            final latestWeight = measurements.isNotEmpty
                ? measurements.last.weightKg
                : (fitnessProfile?.weightKg ?? 75.0);
            final gapLg = AppResponsive.sectionGapLg(context);

            // Calculate attendance visits this month
            final now = DateTime.now();
            final monthlyAttendanceCount = attendanceRecords
                .where((r) =>
                    r.checkIn.year == now.year && r.checkIn.month == now.month)
                .length;

            return SingleChildScrollView(
              padding: AppResponsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const PageHeader(
                    title: 'Fitness Progress & Analytics',
                    subtitle:
                        'Monitor body weight trends, circumferences, personal fitness goals, and training consistency.',
                  ),

                  // 1. Progress KPI Summary Cards
                  ProgressSummaryCards(
                    measurements: measurements,
                    completedWorkouts: completedWorkouts,
                    attendanceThisMonth: monthlyAttendanceCount > 0
                        ? monthlyAttendanceCount
                        : 18,
                    isMetric: isMetric,
                  ),

                  SizedBox(height: gapLg),

                  // 1b. Daily Activity, Water & Sleep Trackers
                  const DailyHealthTrackersCard(),

                  SizedBox(height: gapLg),

                  // 1c. Interactive BMI & BMR Calculator
                  BmiBmrCalculatorCard(
                    initialHeightCm: fitnessProfile?.heightCm ?? 175.0,
                    initialWeightKg: latestWeight,
                    initialAge: fitnessProfile?.age ?? 28,
                  ),

                  SizedBox(height: gapLg),

                  // 2. Interactive Fitness Progress Charts (fl_chart)
                  FitnessChartCard(
                    measurements: measurements,
                    isMetric: isMetric,
                  ),

                  SizedBox(height: gapLg),

                  // 2b. Dedicated Muscle Growth & Recomposition Tracking
                  MuscleGrowthCard(
                    measurements: measurements,
                    isMetric: isMetric,
                    onSaveMeasurement: (updated) {
                      ref
                          .read(fitnessMeasurementsProvider.notifier)
                          .saveMeasurement(updated);
                    },
                  ),

                  SizedBox(height: gapLg),

                  // 2c. Before & After Progress Photos
                  BeforeAfterPhotosCard(
                    latestWeightKg: latestWeight,
                    isMetric: isMetric,
                  ),

                  SizedBox(height: gapLg),

                  // 2d. Personal Fitness Records (PRs)
                  PersonalRecordsSummaryCard(
                    memberId: member.id,
                    isMetric: isMetric,
                  ),

                  SizedBox(height: gapLg),

                  // 2e. Weekly & Monthly Progress Reports
                  WeeklyMonthlyReportsCard(
                    measurements: measurements,
                    completedWorkouts: completedWorkouts,
                    attendanceRecords: attendanceRecords,
                    dailyHealthLog: dailyHealth,
                    foodLogs: foodLogs,
                    isMetric: isMetric,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Personal Fitness Goals & Goal Compilation
                  FitnessGoalsCard(
                    goals: goals,
                    isMetric: isMetric,
                    primaryProfileGoal: fitnessProfile?.primaryGoal,
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
