import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';
import '../../../../shared/widgets/empty_state.dart';
import 'attendance_record_card.dart';

/// List of attendance records with location and day filtering, empty state, and detailed view.
class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime selectedMonth;
  final DateTime? selectedDay;
  final String? selectedLocation;
  final String memberName;
  final VoidCallback onClearDayFilter;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onResetToCurrentMonth;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    required this.selectedMonth,
    required this.selectedDay,
    required this.selectedLocation,
    required this.memberName,
    required this.onClearDayFilter,
    required this.onLocationChanged,
    required this.onResetToCurrentMonth,
  });

  static const List<String> availableLocations = [
    'All Locations',
    'Downtown Main Floor',
    'Olympic Lifting Zone',
    'CrossFit Arena',
    'Cardio Deck & Track',
    'Strength & Conditioning Floor',
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Filter by selected month & year
    var filtered = records.where((r) {
      return r.checkIn.year == selectedMonth.year &&
          r.checkIn.month == selectedMonth.month;
    }).toList();

    // 2. Filter by specific day if selected from calendar
    if (selectedDay != null) {
      filtered = filtered.where((r) {
        return r.checkIn.year == selectedDay!.year &&
            r.checkIn.month == selectedDay!.month &&
            r.checkIn.day == selectedDay!.day;
      }).toList();
    }

    // 3. Filter by location if specified
    if (selectedLocation != null &&
        selectedLocation!.isNotEmpty &&
        selectedLocation != 'All Locations') {
      filtered = filtered.where((r) {
        return r.location.toLowerCase() == selectedLocation!.toLowerCase();
      }).toList();
    }

    final monthLabel = AppFormatters.formatMonthYear(selectedMonth);

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
          // Section Title & Filters Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final headerInfo = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.history_rounded,
                        color: AppColors.darkCharcoal,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Attendance History',
                          style: AppTextStyles.h3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${filtered.length} ${filtered.length == 1 ? 'Visit' : 'Visits'}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.limeAccentDark,
                      ),
                    ),
                  ),
                ],
              );

              final locationSelector = Container(
                width: isNarrow ? double.infinity : 220,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedLocation ?? 'All Locations',
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: availableLocations.map((loc) {
                      return DropdownMenuItem<String>(
                        value: loc,
                        child: Text(
                          loc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      onLocationChanged(val == 'All Locations' ? null : val);
                    },
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: AppSpacing.md),
                    locationSelector,
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: headerInfo),
                    locationSelector,
                  ],
                );
              }
            },
          ),

          // Active Day Filter Badge (if tapped on calendar)
          if (selectedDay != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.limeAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.limeAccentDark.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    size: 15,
                    color: AppColors.limeAccentDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Filtered by date: ${AppFormatters.formatShortDate(selectedDay!)}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: onClearDayFilter,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.darkCharcoal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Records List or Empty State
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Visits Found',
                message: selectedDay != null
                    ? 'No check-ins recorded for ${AppFormatters.formatShortDate(selectedDay!)}.'
                    : 'No attendance records found for $monthLabel${selectedLocation != null ? ' in $selectedLocation' : ''}.',
                actionLabel: selectedDay != null
                    ? 'Clear Date Filter'
                    : 'Jump to Current Month',
                onAction: selectedDay != null
                    ? onClearDayFilter
                    : onResetToCurrentMonth,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return AttendanceRecordCard(
                  record: filtered[index],
                  memberName: memberName,
                );
              },
            ),
        ],
      ),
    );
  }
}
