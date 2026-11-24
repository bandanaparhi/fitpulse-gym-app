import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/notification_item.dart';

/// Card displaying an individual notification item with type-based iconography,
/// unread indicators, mark-as-read action, and navigation to the related screen.
class NotificationItemCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'class':
        return Icons.event_seat_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'trainer':
        return Icons.sports_outlined;
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'membership':
        return Icons.card_membership_rounded;
      case 'diet':
        return Icons.restaurant_menu_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'class':
        return AppColors.warning;
      case 'workout':
        return AppColors.limeAccentDark;
      case 'trainer':
        return AppColors.info;
      case 'payment':
        return AppColors.success;
      case 'membership':
        return AppColors.darkCharcoal;
      case 'diet':
        return AppColors.warning;
      default:
        return AppColors.darkCharcoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeIcon = _getTypeIcon(notification.type);
    final typeColor = _getTypeColor(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.cardBackground
            : AppColors.cardSubtleBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnread
              ? AppColors.limeAccentDark.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
          width: isUnread ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title, Unread Indicator & Time
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          final titleWidget = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUnread) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 2, right: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.limeAccentDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Flexible(
                                child: Text(
                                  notification.title,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );

                          final timeWidget = Text(
                            '${AppFormatters.formatShortDate(notification.timestamp)} • ${AppFormatters.formatTime(notification.timestamp)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleWidget,
                                const SizedBox(height: 2),
                                timeWidget,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: titleWidget),
                              const SizedBox(width: AppSpacing.sm),
                              timeWidget,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Description
                      Text(
                        notification.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Bottom Action Row: Related Screen Action & Mark as Read
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnread
                                  ? AppColors.darkCharcoal
                                  : AppColors.cardSubtleBg,
                              foregroundColor: isUnread
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                side: isUnread
                                    ? BorderSide.none
                                    : const BorderSide(
                                        color: AppColors.borderSubtle,
                                      ),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: isUnread
                                  ? AppColors.limeAccent
                                  : AppColors.textSecondary,
                            ),
                            label: Text(
                              notification.effectiveActionLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                            onPressed: onTap,
                          ),
                          if (isUnread) ...[
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Mark as Read',
                                style: TextStyle(fontSize: 13),
                              ),
                              onPressed: onMarkAsRead,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
