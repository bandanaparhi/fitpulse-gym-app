import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';
import '../../../../shared/widgets/summary_card.dart';

/// KPI Summary Cards displaying calculated metrics from actual attendance records.
class AttendanceSummaryCards extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime selectedMonth;

  const AttendanceSummaryCards({
    super.key,
    required this.records,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate visits this selected month directly from records
    final monthRecords = records.where((r) {
      return r.checkIn.year == selectedMonth.year &&
          r.checkIn.month == selectedMonth.month;
    }).toList();
    final visitsThisMonth = monthRecords.length;

    // 2. Calculate visits this selected year directly from records
    final yearRecords = records.where((r) {
      return r.checkIn.year == selectedMonth.year;
    }).toList();
    final visitsThisYear = yearRecords.length;

    // 3. Calculate average duration directly from records with checkOut
    final monthDurations = monthRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration!)
        .toList();

    String avgDurationStr = '--';
    if (monthDurations.isNotEmpty) {
      final totalMinutes = monthDurations.fold<int>(
        0,
        (sum, d) => sum + d.inMinutes,
      );
      final avgMinutes = totalMinutes ~/ monthDurations.length;
      final hours = avgMinutes ~/ 60;
      final mins = avgMinutes % 60;
      avgDurationStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    } else {
      // Fallback to year records if selected month has no visits
      final yearDurations = yearRecords
          .where((r) => r.duration != null)
          .map((r) => r.duration!)
          .toList();
      if (yearDurations.isNotEmpty) {
        final totalMinutes = yearDurations.fold<int>(
          0,
          (sum, d) => sum + d.inMinutes,
        );
        final avgMinutes = totalMinutes ~/ yearDurations.length;
        final hours = avgMinutes ~/ 60;
        final mins = avgMinutes % 60;
        avgDurationStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
      }
    }

    final monthName = AppFormatters.formatMonthAbbr(selectedMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;
        final isTablet = width >= 600 && width < 900;

        final cardMonth = SummaryCard(
          label: 'Visits in $monthName',
          value: '$visitsThisMonth',
          subtitle: visitsThisMonth >= 18
              ? 'Goal reached (18/20 visits)'
              : '$visitsThisMonth visits recorded',
          icon: Icons.event_available_rounded,
          iconColor: AppColors.limeAccentDark,
          iconBgColor: AppColors.limeAccent.withValues(alpha: 0.15),
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'Monthly',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.limeAccentDark,
                fontSize: 10,
              ),
            ),
          ),
        );

        final cardYear = SummaryCard(
          label: 'Total Visits in ${selectedMonth.year}',
          value: '$visitsThisYear',
          subtitle: 'Active member attendance',
          icon: Icons.emoji_events_outlined,
          iconColor: AppColors.info,
          iconBgColor: AppColors.info.withValues(alpha: 0.12),
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${selectedMonth.year}',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.info,
                fontSize: 10,
              ),
            ),
          ),
        );

        final cardDuration = SummaryCard(
          label: 'Avg Visit Duration',
          value: avgDurationStr,
          subtitle: 'Per workout session',
          icon: Icons.timer_outlined,
          iconColor: AppColors.warning,
          iconBgColor: AppColors.warning.withValues(alpha: 0.12),
        );

        final cardConsistency = SummaryCard(
          label: 'Attendance Consistency',
          value: visitsThisMonth >= 12 ? 'Excellent' : 'Moderate',
          subtitle: 'Regular weekly routine',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.limeAccentDark,
          iconBgColor: AppColors.limeAccent.withValues(alpha: 0.15),
        );

        if (isDesktop) {
          return Row(
            children: [
              Expanded(child: cardMonth),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardYear),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardDuration),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: cardConsistency),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardMonth),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardYear),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: cardDuration),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardConsistency),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardMonth),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cardYear),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: cardDuration),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cardConsistency),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}
