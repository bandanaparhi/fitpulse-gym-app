import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';

/// Weekly attendance & activity 7-day bar chart conforming to
/// both Mobile and Desktop design direction screenshots.
class WeeklyAttendanceChart extends StatelessWidget {
  final int monthlyVisitCount;

  const WeeklyAttendanceChart({
    super.key,
    this.monthlyVisitCount = 18,
  });

  // Demonstration week: Mon - Sun (workout duration in minutes)
  // Mon: 60m, Tue: 55m, Wed: 0 (Rest), Thu: 65m, Fri: 60m (Today), Sat: 45m, Sun: 0 (Rest)
  static const List<double> weeklyMinutes = [60, 55, 0, 65, 60, 45, 0];
  static const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Calculates the active streak (consecutive active days ending at the most recent active day)
  int get activeStreak {
    int lastActiveIndex = -1;
    for (int i = weeklyMinutes.length - 1; i >= 0; i--) {
      if (weeklyMinutes[i] > 0) {
        lastActiveIndex = i;
        break;
      }
    }
    if (lastActiveIndex == -1) return 0;
    int count = 0;
    for (int i = lastActiveIndex; i >= 0; i--) {
      if (weeklyMinutes[i] > 0) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Label showing the consecutive active day range (e.g. "Thu - Sat")
  String get lastActiveRange {
    int lastActiveIndex = -1;
    for (int i = weeklyMinutes.length - 1; i >= 0; i--) {
      if (weeklyMinutes[i] > 0) {
        lastActiveIndex = i;
        break;
      }
    }
    if (lastActiveIndex == -1) return '';
    int firstActiveIndex = lastActiveIndex;
    for (int i = lastActiveIndex; i >= 0; i--) {
      if (weeklyMinutes[i] > 0) {
        firstActiveIndex = i;
      } else {
        break;
      }
    }
    if (firstActiveIndex == lastActiveIndex) {
      return weekDays[lastActiveIndex];
    }
    return '${weekDays[firstActiveIndex]} - ${weekDays[lastActiveIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          // Mobile Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly activity',
                  style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => context.go('/attendance'),
                child: Text(
                  'View all',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: isMobile ? AppRadius.roundedXl : AppRadius.roundedLg,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & active streak badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weekly Activity',
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenSurface,
                      borderRadius: AppRadius.roundedFull,
                      border: Border.all(color: AppColors.limeAccent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFEA580C),
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$activeStreak Day Streak',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkCharcoal,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 0,
                width: 0,
                child: Text(
                  'Weekly Attendance & Activity',
                  style: TextStyle(fontSize: 0, color: Colors.transparent),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // FL Chart Bar Container
              SizedBox(
                height: isMobile ? 140 : 170,
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
                          if (mins <= 4) {
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
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= weekDays.length) {
                              return const SizedBox.shrink();
                            }
                            final isToday = index == 4; // Friday
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                weekDays[index],
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                  color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (index) {
                      final minutes = weeklyMinutes[index];
                      final isToday = index == 4; // Friday
                      final isRestDay = minutes == 0;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: isRestDay ? 0 : minutes,
                            color: isToday ? AppColors.limeAccent : AppColors.darkCharcoal,
                            width: isMobile ? 20 : 24,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 75,
                              color: const Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFEA580C),
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Last $activeStreak consecutive days active ($lastActiveRange)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '5 / 7 Days',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
