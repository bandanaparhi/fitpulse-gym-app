import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/training_session.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';

/// Card displaying an individual personal coaching session.
class SessionCard extends StatelessWidget {
  final TrainingSession session;
  final Future<void> Function()? onCancel;

  const SessionCard({
    super.key,
    required this.session,
    this.onCancel,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.limeAccentDark;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.darkCharcoal;
    }
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Coaching Session',
      message:
          'Are you sure you want to cancel your upcoming 1-on-1 session "${session.sessionTitle}"? Your coach will be notified.',
      confirmLabel: 'Yes, Cancel Session',
      cancelLabel: 'Keep Session',
      isDestructive: true,
    );

    if (confirmed == true && onCancel != null) {
      await onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(session.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: session.isUpcoming
              ? AppColors.limeAccentDark.withValues(alpha: 0.35)
              : AppColors.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionTitle,
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Session ID: ${session.id}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  session.status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Details Grid: Date & Time, Duration, Location
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              // Date & Time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.darkCharcoal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.formatDate(session.sessionDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppFormatters.formatTime(session.sessionDate)} (${session.durationMinutes} min)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Location
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coaching Location',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          session.location,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Focus Area or Notes
          if (session.focusArea != null || session.notes != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.cardSubtleBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session.focusArea != null) ...[
                    Text(
                      'Focus: ${session.focusArea}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (session.notes != null) ...[
                    if (session.focusArea != null)
                      const SizedBox(height: 2),
                    Text(
                      'Coach Note: ${session.notes}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Cancellation Action (if upcoming)
          if (session.canCancel) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Session'),
                onPressed: () => _handleCancel(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
