import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/attendance_history_list.dart';
import 'widgets/attendance_summary_cards.dart';
import 'widgets/monthly_attendance_calendar.dart';
import 'widgets/qr_checkin_pass_card.dart';

/// Attendance screen at `/attendance`.
///
/// Displays:
/// - Total visits this month and this year (calculated from actual records)
/// - Average visit duration and attendance summaries
/// - Interactive monthly calendar with highlighted attended days
/// - Strictly neutral future days (never marked as missed)
/// - Attendance history log with check-in, check-out, duration, and zone
/// - Read-only individual record inspection
/// - Loading, empty, and error states
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final filter = ref.watch(attendanceFilterProvider);
    final filterNotifier = ref.read(attendanceFilterProvider.notifier);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading attendance details...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Attendance',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(currentMemberProvider);
            ref.invalidate(attendanceHistoryProvider);
          },
        ),
      ),
      data: (member) {
        return historyAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: LoadingIndicator(message: 'Loading attendance records...'),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: ErrorState(
              title: 'Unable to Load Attendance History',
              message: err.toString(),
              onRetry: () {
                ref.invalidate(attendanceHistoryProvider);
              },
            ),
          ),
          data: (records) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  PageHeader(
                    title: 'Attendance & Visits',
                    subtitle:
                        'Review your gym check-in logs, monthly attendance calendar, and workout durations.',
                    trailing: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text('Member QR Pass'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 8,
                        ),
                        side: const BorderSide(color: AppColors.limeAccentDark),
                        foregroundColor: AppColors.limeAccentDark,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: QrCheckinPassCard(member: member),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Calculated Attendance Summaries (KPIs)
                  AttendanceSummaryCards(
                    records: records,
                    selectedMonth: filter.selectedMonth,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Monthly Attendance Calendar
                  MonthlyAttendanceCalendar(
                    currentMonth: filter.selectedMonth,
                    selectedDay: filter.selectedDay,
                    records: records,
                    onMonthChanged: (newMonth) {
                      filterNotifier.setMonth(newMonth);
                    },
                    onDaySelected: (day) {
                      filterNotifier.selectDay(day);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Attendance History Log & Detail Inspection
                  AttendanceHistoryList(
                    records: records,
                    selectedMonth: filter.selectedMonth,
                    selectedDay: filter.selectedDay,
                    selectedLocation: filter.selectedLocation,
                    memberName: member.name,
                    onClearDayFilter: () {
                      filterNotifier.selectDay(null);
                    },
                    onLocationChanged: (loc) {
                      filterNotifier.setLocation(loc);
                    },
                    onResetToCurrentMonth: () {
                      filterNotifier.resetToCurrentMonth();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
