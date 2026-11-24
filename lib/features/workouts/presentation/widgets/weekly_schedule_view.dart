import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/workout.dart';

class _ScheduleDayItem {
  final String dayName;
  final bool isTrainingDay;
  final String workoutTitle;
  final String? workoutId;
  final String duration;
  final String focusArea;

  const _ScheduleDayItem({
    required this.dayName,
    required this.isTrainingDay,
    required this.workoutTitle,
    this.workoutId,
    required this.duration,
    required this.focusArea,
  });
}

/// Visual weekly schedule showing training days and rest days.
class WeeklyScheduleView extends StatelessWidget {
  final List<Workout> workouts;

  const WeeklyScheduleView({
    super.key,
    required this.workouts,
  });

  static const List<_ScheduleDayItem> _schedule = [
    _ScheduleDayItem(
      dayName: 'Monday',
      isTrainingDay: true,
      workoutTitle: 'Upper Body Power & Hypertrophy',
      workoutId: 'WK-01',
      duration: '60 min',
      focusArea: 'Chest, Shoulders & Back',
    ),
    _ScheduleDayItem(
      dayName: 'Tuesday',
      isTrainingDay: true,
      workoutTitle: 'Lower Body Strength & Core',
      workoutId: 'WK-02',
      duration: '55 min',
      focusArea: 'Quads, Hamstrings & Glutes',
    ),
    _ScheduleDayItem(
      dayName: 'Wednesday',
      isTrainingDay: false,
      workoutTitle: 'Active Recovery & Mobility',
      duration: '30 min',
      focusArea: 'Foam rolling, stretching & walking',
    ),
    _ScheduleDayItem(
      dayName: 'Thursday',
      isTrainingDay: true,
      workoutTitle: 'Upper Body Power & Hypertrophy',
      workoutId: 'WK-01',
      duration: '60 min',
      focusArea: 'Chest, Lat Width & Pressing',
    ),
    _ScheduleDayItem(
      dayName: 'Friday',
      isTrainingDay: true,
      workoutTitle: 'Lower Body Strength & Core',
      workoutId: 'WK-02',
      duration: '55 min',
      focusArea: 'Posterior chain & squat power',
    ),
    _ScheduleDayItem(
      dayName: 'Saturday',
      isTrainingDay: true,
      workoutTitle: 'Cardio & Conditioning (Optional)',
      duration: '40 min',
      focusArea: 'HIIT intervals & core stability',
    ),
    _ScheduleDayItem(
      dayName: 'Sunday',
      isTrainingDay: false,
      workoutTitle: 'Full Rest & Nutrition Reset',
      duration: 'Rest Day',
      focusArea: 'Recovery and hydration',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.darkCharcoal,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Weekly Workout Schedule',
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '4 Training Days',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Your weekly regime designed by Coach Jordan Lee. Follow progressive overload on training days.',
            style: AppTextStyles.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Schedule Days List
          Column(
            children: _schedule.map((item) {
              return _buildScheduleRow(context, item);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BuildContext context, _ScheduleDayItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: item.isTrainingDay
            ? AppColors.cardBackground
            : AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.isTrainingDay
              ? AppColors.borderSubtle
              : AppColors.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Day column
          SizedBox(
            width: 85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dayName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.isTrainingDay
                        ? AppColors.limeAccent.withValues(alpha: 0.2)
                        : AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    item.isTrainingDay ? 'TRAINING' : 'REST',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: item.isTrainingDay
                          ? AppColors.limeAccentDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Workout Title & Focus Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.workoutTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.duration} • ${item.focusArea}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action button
          if (item.workoutId != null) ...[
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              onPressed: () {
                context.go('/workouts/${item.workoutId}');
              },
              child: const Text('View', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
