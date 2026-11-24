import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';

/// Interactive monthly calendar displaying gym attendance.
///
/// Features:
/// - Month & year navigation and selector
/// - Highlighted attended days with check-in indicators
/// - Clean rest days
/// - Strictly neutral upcoming future days (never marked as missed)
/// - Day selection to filter attendance records
class MonthlyAttendanceCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime? selectedDay;
  final List<AttendanceRecord> records;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime?> onDaySelected;

  const MonthlyAttendanceCalendar({
    super.key,
    required this.currentMonth,
    required this.selectedDay,
    required this.records,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  static const List<String> _weekDayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final offset = firstDayWeekday - 1; // 0-based offset for Monday start

    // Map attended days in this month to records
    final Map<int, List<AttendanceRecord>> attendedDays = {};
    for (final record in records) {
      if (record.checkIn.year == currentMonth.year &&
          record.checkIn.month == currentMonth.month) {
        attendedDays.putIfAbsent(record.checkIn.day, () => []).add(record);
      }
    }

    final isCurrentRealMonth =
        now.year == currentMonth.year && now.month == currentMonth.month;

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
          // Calendar Header: Month, Year, Nav Buttons, and Today Jump
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMonthYearSelector(context),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              tooltip: 'Previous Month',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final prev = DateTime(
                                  currentMonth.year,
                                  currentMonth.month - 1,
                                  1,
                                );
                                onMonthChanged(prev);
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              tooltip: 'Next Month',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final next = DateTime(
                                  currentMonth.year,
                                  currentMonth.month + 1,
                                  1,
                                );
                                onMonthChanged(next);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMonthYearSelector(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous Month',
                    onPressed: () {
                      final prev = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                        1,
                      );
                      onMonthChanged(prev);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next Month',
                    onPressed: () {
                      final next = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                        1,
                      );
                      onMonthChanged(next);
                    },
                  ),
                  if (!isCurrentRealMonth) ...[
                    const SizedBox(width: AppSpacing.xs),
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
                        onMonthChanged(DateTime(now.year, now.month, 1));
                      },
                      child: const Text('Today', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Legend Row
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLegendItem(
                color: AppColors.limeAccentDark,
                label: 'Attended (${attendedDays.length} days)',
              ),
              _buildLegendItem(
                color: AppColors.borderStrong,
                label: 'Rest Day',
              ),
              _buildLegendItem(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                label: 'Upcoming',
              ),
              if (selectedDay != null)
                GestureDetector(
                  onTap: () => onDaySelected(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Showing ${AppFormatters.formatShortDate(selectedDay!)}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkCharcoal,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: AppColors.darkCharcoal,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Weekday Labels Header Row
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Center(
                  child: Text(
                    _weekDayNames[index],
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Calendar Grid
          _buildCalendarGrid(
            daysInMonth: daysInMonth,
            offset: offset,
            today: today,
            attendedDays: attendedDays,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector(BuildContext context) {
    final currentYear = currentMonth.year;
    final currentMonthIndex = currentMonth.month - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month Dropdown Button
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: currentMonthIndex,
            icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            dropdownColor: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: List.generate(12, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  _monthNames[index],
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            onChanged: (newMonthIndex) {
              if (newMonthIndex != null) {
                final updated = DateTime(currentYear, newMonthIndex + 1, 1);
                onMonthChanged(updated);
              }
            },
          ),
        ),

        const SizedBox(width: 4),

        // Year Dropdown Button
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: currentYear,
            icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            dropdownColor: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            items: [2025, 2026, 2027].map((y) {
              return DropdownMenuItem<int>(
                value: y,
                child: Text(
                  y.toString(),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newYear) {
              if (newYear != null) {
                final updated = DateTime(newYear, currentMonth.month, 1);
                onMonthChanged(updated);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid({
    required int daysInMonth,
    required int offset,
    required DateTime today,
    required Map<int, List<AttendanceRecord>> attendedDays,
  }) {
    final totalCells = offset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - offset + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final cellDate = DateTime(
                currentMonth.year,
                currentMonth.month,
                dayNumber,
              );
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final isFuture = cellDate.isAfter(today);
              final hasAttendance = attendedDays.containsKey(dayNumber);
              final isSelected = selectedDay != null &&
                  selectedDay!.year == cellDate.year &&
                  selectedDay!.month == cellDate.month &&
                  selectedDay!.day == cellDate.day;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildDayCell(
                    dayNumber: dayNumber,
                    cellDate: cellDate,
                    isToday: isToday,
                    isFuture: isFuture,
                    hasAttendance: hasAttendance,
                    isSelected: isSelected,
                    recordsCount: attendedDays[dayNumber]?.length ?? 0,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell({
    required int dayNumber,
    required DateTime cellDate,
    required bool isToday,
    required bool isFuture,
    required bool hasAttendance,
    required bool isSelected,
    required int recordsCount,
  }) {
    // Styling states
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;
    Border? border;

    if (isSelected) {
      border = Border.all(color: AppColors.darkCharcoal, width: 2);
      bgColor = AppColors.limeAccent.withValues(alpha: 0.25);
    } else if (isToday) {
      border = Border.all(color: AppColors.limeAccentDark, width: 2);
    }

    if (hasAttendance) {
      bgColor = isSelected
          ? AppColors.limeAccent.withValues(alpha: 0.3)
          : AppColors.limeAccent.withValues(alpha: 0.15);
      textColor = AppColors.textPrimary;
    } else if (isFuture) {
      // Future dates: clean and neutral, NEVER marked as missed
      textColor = AppColors.textSecondary.withValues(alpha: 0.4);
      bgColor = AppColors.cardSubtleBg.withValues(alpha: 0.5);
    } else {
      // Past rest days
      textColor = AppColors.textSecondary;
      bgColor = AppColors.cardSubtleBg;
    }

    return Tooltip(
      message: hasAttendance
          ? 'Attended: $recordsCount visit(s) on ${AppFormatters.formatShortDate(cellDate)}'
          : isFuture
              ? 'Upcoming: ${AppFormatters.formatShortDate(cellDate)}'
              : 'Rest Day: ${AppFormatters.formatShortDate(cellDate)}',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            // Tapping selects or deselects this day
            if (isSelected) {
              onDaySelected(null);
            } else {
              onDaySelected(cellDate);
            }
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: border ?? Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Day number
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (hasAttendance || isToday || isSelected)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: textColor,
                  ),
                ),

                // Attended indicator icon / dot
                if (hasAttendance)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.limeAccentDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // Today badge indicator
                if (isToday)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.limeAccentDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
