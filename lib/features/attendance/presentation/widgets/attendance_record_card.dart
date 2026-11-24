import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';
import 'attendance_record_detail_modal.dart';

/// Card component representing a single gym attendance entry.
class AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final String memberName;

  const AttendanceRecordCard({
    super.key,
    required this.record,
    this.memberName = 'Alex Morgan',
  });

  @override
  Widget build(BuildContext context) {
    final durationStr = AppFormatters.formatDuration(record.duration);
    final isCompleted = record.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => AttendanceRecordDetailModal.show(
            context,
            record: record,
            memberName: memberName,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date, day, and status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.limeAccentDark,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${AppFormatters.formatShortDate(record.checkIn)} • ${AppFormatters.formatShortDayOfWeek(record.checkIn)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.limeAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.success.withValues(alpha: 0.25)
                              : AppColors.limeAccentDark.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        record.status,
                        style: AppTextStyles.caption.copyWith(
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.limeAccentDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Metrics wrap: Check-in, Check-out, Duration, Location
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildPill(
                      icon: Icons.login_rounded,
                      iconColor: AppColors.limeAccentDark,
                      label: 'In',
                      value: AppFormatters.formatTime(record.checkIn),
                    ),
                    _buildPill(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.warning,
                      label: 'Out',
                      value: record.checkOut != null
                          ? AppFormatters.formatTime(record.checkOut!)
                          : 'In Progress',
                    ),
                    _buildPill(
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.textSecondary,
                      label: 'Duration',
                      value: durationStr,
                    ),
                    _buildPill(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.textSecondary,
                      label: 'Zone',
                      value: record.location,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
}
