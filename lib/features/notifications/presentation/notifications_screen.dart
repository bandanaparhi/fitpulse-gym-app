import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/notification_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/notification_item_card.dart';

/// Screen displaying the member's notification stream at `/notifications`.
///
/// Features:
/// - Filters for All, Read, and Unread
/// - Mark as Read on individual items
/// - Mark All as Read bulk action
/// - Navigation to related feature screens (membership, payment, workout, etc.)
/// - Instant read status update on action
/// - Themed empty states for each filter view
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Unread', 'Read'

  void _handleMarkAllAsRead() {
    ref.read(notificationsProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleItemTap(NotificationItem notification) {
    // 1. Update read status when action succeeds
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }
    // 2. Navigate to related screen
    context.go(notification.effectiveRoute);
  }

  void _handleMarkAsRead(NotificationItem notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${notification.title}" as read.'),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkCharcoal : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.darkCharcoal : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.limeAccentDark
                    : AppColors.cardSubtleBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = ref.watch(notificationsProvider);
    final unreadCount = allNotifications.where((n) => !n.isRead).length;
    final readCount = allNotifications.where((n) => n.isRead).length;

    final filteredNotifications = allNotifications.where((n) {
      if (_selectedFilter == 'Unread') return !n.isRead;
      if (_selectedFilter == 'Read') return n.isRead;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: PageHeader(
                    title: 'Notifications & Alerts',
                    subtitle:
                        'Stay updated on your class bookings, coaching check-ins, invoices, and workout achievements.',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (unreadCount > 0)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCharcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark All as Read'),
                    onPressed: _handleMarkAllAsRead,
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Filters Bar (All, Unread, Read)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildFilterChip(
                  label: 'All Notifications',
                  value: 'All',
                  count: allNotifications.length,
                ),
                _buildFilterChip(
                  label: 'Unread',
                  value: 'Unread',
                  count: unreadCount,
                ),
                _buildFilterChip(
                  label: 'Read',
                  value: 'Read',
                  count: readCount,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Notification List or Empty State
            if (filteredNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: EmptyState(
                  icon: _selectedFilter == 'Unread'
                      ? Icons.mark_chat_read_outlined
                      : Icons.notifications_off_outlined,
                  title: _selectedFilter == 'Unread'
                      ? 'All Caught Up! 🎉'
                      : _selectedFilter == 'Read'
                          ? 'No Read Notifications'
                          : 'No Notifications Yet',
                  message: _selectedFilter == 'Unread'
                      ? 'You have reviewed all your notifications and updates. New activity alerts will appear here.'
                      : _selectedFilter == 'Read'
                          ? 'You have not marked any notifications as read yet.'
                          : 'You currently have no notifications on file.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredNotifications.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final notification = filteredNotifications[index];
                  return NotificationItemCard(
                    notification: notification,
                    onTap: () => _handleItemTap(notification),
                    onMarkAsRead: () => _handleMarkAsRead(notification),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
