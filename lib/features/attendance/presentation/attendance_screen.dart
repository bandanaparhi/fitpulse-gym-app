import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/models/member.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
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
            final gap = AppResponsive.sectionGap(context);
            final gapLg = AppResponsive.sectionGapLg(context);
            return SingleChildScrollView(
              padding: AppResponsive.pagePadding(context),
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
                      onPressed: () => _openQrPassDialog(context, member),
                    ),
                  ),

                  // Interactive QR Check-In / Check-Out Bar
                  _QrCheckinActionBar(
                    member: member,
                    records: records,
                    onOpenQrPass: () => _openQrPassDialog(context, member),
                  ),
                  SizedBox(height: gap),

                  // Calculated Attendance Summaries, Workout Streak & Monthly Report
                  AttendanceSummaryCards(
                    records: records,
                    selectedMonth: filter.selectedMonth,
                  ),

                  SizedBox(height: gapLg),

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

                  SizedBox(height: gap),

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

  void _openQrPassDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: QrCheckinPassCard(member: member),
      ),
    );
  }
}

class _QrCheckinActionBar extends ConsumerWidget {
  final Member member;
  final List<AttendanceRecord> records;
  final VoidCallback onOpenQrPass;

  const _QrCheckinActionBar({
    required this.member,
    required this.records,
    required this.onOpenQrPass,
  });

  AttendanceRecord? get _activeSession {
    for (final r in records) {
      if (r.checkOut == null) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = _activeSession;
    final isMobile = AppResponsive.isMobile(context);

    final statusSection = Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: active != null
                ? AppColors.limeAccent.withValues(alpha: 0.22)
                : AppColors.darkCharcoal,
            borderRadius: AppRadius.roundedMd,
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            color: active != null ? AppColors.limeAccentDark : AppColors.limeAccent,
            size: isMobile ? 20 : 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active != null
                    ? 'Active Gym Session • Checked In'
                    : 'QR Gym Check-In & Check-Out',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: isMobile ? 13.5 : 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active != null
                    ? 'Checked in at ${AppFormatters.formatTime(active.checkIn)} • ${active.location}'
                    : 'Scan or tap QR Check-In to record your entry and exit times',
                style: AppTextStyles.caption.copyWith(
                  color: active != null ? AppColors.limeAccentDark : AppColors.textSecondary,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actionButton = PrimaryButton(
      label: active != null ? 'QR Check-Out' : 'QR Check-In',
      icon: active != null ? Icons.logout_rounded : Icons.qr_code_scanner_rounded,
      height: 40,
      onPressed: () async {
        if (active != null) {
          final updated = await ref
              .read(attendanceHistoryProvider.notifier)
              .checkOutWithQr(active.id);
          if (context.mounted) {
            final outTime = updated?.checkOut ?? DateTime.now();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Checked out via QR at ${AppFormatters.formatTime(outTime)}.',
                ),
                backgroundColor: AppColors.darkCharcoal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          final created = await ref
              .read(attendanceHistoryProvider.notifier)
              .checkInWithQr();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Checked in via QR at ${AppFormatters.formatTime(created.checkIn)}.',
                ),
                backgroundColor: AppColors.darkCharcoal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );

    return Container(
      width: double.infinity,
      padding: AppResponsive.cardPadding(context),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(
          color: active != null ? AppColors.limeAccentDark : AppColors.borderSubtle,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusSection,
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: actionButton),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: onOpenQrPass,
                      child: const Text('QR Code'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: statusSection),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton(
                  onPressed: onOpenQrPass,
                  child: const Text('Show QR Code'),
                ),
                const SizedBox(width: AppSpacing.sm),
                actionButton,
              ],
            ),
    );
  }
}
