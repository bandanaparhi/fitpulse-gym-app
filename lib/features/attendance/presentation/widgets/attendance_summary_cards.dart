import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
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

  ({int current, int best}) _computeStreaks(List<AttendanceRecord> records) {
    if (records.isEmpty) return (current: 0, best: 0);
    final uniqueDays = records
        .map((r) => DateTime(r.checkIn.year, r.checkIn.month, r.checkIn.day))
        .toSet()
        .toList()
      ..sort();

    int best = 1;
    int run = 1;
    for (int i = 1; i < uniqueDays.length; i++) {
      if (uniqueDays[i].difference(uniqueDays[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daySet = uniqueDays.toSet();
    DateTime cursor = daySet.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    int current = 0;
    while (daySet.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return (current: current, best: best);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final streaks = _computeStreaks(records);

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

    // 3. Calculate total & average duration directly from records with checkOut
    final monthDurations = monthRecords
        .where((r) => r.duration != null)
        .map((r) => r.duration!)
        .toList();
    final totalMonthMinutes = monthDurations.fold<int>(
      0,
      (sum, d) => sum + d.inMinutes,
    );
    final totalMonthTimeStr = totalMonthMinutes >= 60
        ? '${totalMonthMinutes ~/ 60}h ${totalMonthMinutes % 60}m'
        : '${totalMonthMinutes}m';

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
          subtitle: '${streaks.current}d workout streak • Best: ${streaks.best}d',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.limeAccentDark,
          iconBgColor: AppColors.limeAccent.withValues(alpha: 0.15),
        );

        final kpiGrid = isDesktop
            ? Row(
                children: [
                  Expanded(child: cardMonth),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardYear),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardDuration),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cardConsistency),
                ],
              )
            : isTablet
                ? Column(
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
                  )
                : Column(
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kpiGrid,
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : AppSpacing.md,
                vertical: isMobile ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 17,
                        color: AppColors.limeAccentDark,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Workout Streak: ${streaks.current} day${streaks.current == 1 ? '' : 's'} (Best: ${streaks.best}d)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 11.5 : 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.summarize_outlined,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Monthly Attendance Report ($monthName ${selectedMonth.year}): $visitsThisMonth visits • $totalMonthTimeStr active',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 11.5 : 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
