import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/info_card.dart';

/// Weekly attendance & workout activity bar chart using FL Chart.
class WeeklyAttendanceChart extends StatelessWidget {
  final int monthlyVisitCount;

  const WeeklyAttendanceChart({
    super.key,
    this.monthlyVisitCount = 18,
  });

  // Demonstration week: Mon - Sun (workout duration in minutes)
  // Mon: 60m, Tue: 55m, Wed: 0 (Rest), Thu: 65m, Fri: 60m, Sat: 45m, Sun: 0 (Rest)
  static const List<double> weeklyMinutes = [60, 55, 0, 65, 60, 45, 0];
  static const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Weekly Attendance & Activity',
      subtitle: '5 sessions completed this week • 285 active minutes',
      icon: Icons.bar_chart_rounded,
      trailing: TextButton.icon(
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('View All'),
        onPressed: () => context.go('/attendance'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Summary metrics row
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _buildMetricBadge(
                icon: Icons.check_circle_outline,
                label: 'This Week',
                value: '5 / 7 Days',
                color: AppColors.limeAccentDark,
              ),
              _buildMetricBadge(
                icon: Icons.timer_outlined,
                label: 'Avg Duration',
                value: '57 min/day',
                color: AppColors.darkCharcoal,
              ),
              _buildMetricBadge(
                icon: Icons.calendar_today_outlined,
                label: 'Month Total',
                value: '$monthlyVisitCount Visits',
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Bar Chart container
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 80,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkCharcoal,
                    tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = weekDays[group.x.toInt()];
                      final mins = rod.toY.toInt();
                      if (mins == 0) {
                        return BarTooltipItem(
                          '$day\nRest Day',
                          AppTextStyles.caption.copyWith(color: AppColors.textOnDarkMuted),
                        );
                      }
                      return BarTooltipItem(
                        '$day\n$mins mins',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.limeAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}m',
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weekDays.length) {
                          return const SizedBox.shrink();
                        }
                        final isToday = index == 4; // Friday in demo week
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weekDays[index],
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? AppColors.darkCharcoal : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final minutes = weeklyMinutes[index];
                  final isToday = index == 4; // Friday
                  final isRestDay = minutes == 0;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: isRestDay ? 3 : minutes,
                        color: isRestDay
                            ? AppColors.borderSubtle
                            : (isToday ? AppColors.limeAccent : AppColors.darkCharcoal),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 80,
                          color: AppColors.scaffoldBackground,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Legend Row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildLegendDot(AppColors.darkCharcoal, 'Completed Session'),
              _buildLegendDot(AppColors.limeAccent, 'Today'),
              _buildLegendDot(AppColors.borderSubtle, 'Rest Day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption,
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: color == AppColors.borderSubtle
                ? Border.all(color: AppColors.borderStrong, width: 0.8)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
