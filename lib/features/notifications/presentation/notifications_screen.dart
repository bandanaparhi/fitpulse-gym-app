import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/models/notification_preferences.dart';
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
  String _selectedType = 'all'; // 'all', 'membership', 'payment', 'workout', 'water', 'diet', 'announcement'

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
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final prefs = prefsAsync.value ?? const NotificationPreferences();
    final unreadCount = allNotifications.where((n) => !n.isRead).length;
    final readCount = allNotifications.where((n) => n.isRead).length;

    final filteredNotifications = allNotifications.where((n) {
      final matchesRead = _selectedFilter == 'Unread'
          ? !n.isRead
          : (_selectedFilter == 'Read' ? n.isRead : true);
      final matchesType =
          _selectedType == 'all' || n.type.toLowerCase() == _selectedType;
      return matchesRead && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Row
            PageHeader(
              title: 'Notifications & Alerts',
              subtitle:
                  'Stay updated on your class bookings, coaching check-ins, invoices, and workout achievements.',
              trailing: unreadCount > 0
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCharcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Mark All as Read'),
                      onPressed: _handleMarkAllAsRead,
                    )
                  : null,
            ),

            // Reminder Channels Summary Strip
            _ActiveReminderChannelsCard(
              prefs: prefs,
              onConfigure: () {
                GoRouter.maybeOf(context)?.go('/settings');
              },
            ),

            const SizedBox(height: AppSpacing.md),

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

            const SizedBox(height: AppSpacing.sm),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in const [
                    ('all', 'All Types'),
                    ('membership', 'Membership Expiry'),
                    ('payment', 'Payment'),
                    ('workout', 'Workout'),
                    ('water', 'Water Intake'),
                    ('diet', 'Diet'),
                    ('announcement', 'Announcement'),
                  ]) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(
                          item.$2,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: _selectedType == item.$1
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedType == item.$1
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        selected: _selectedType == item.$1,
                        selectedColor: AppColors.darkCharcoal,
                        backgroundColor: AppColors.cardBackground,
                        side: BorderSide(
                          color: _selectedType == item.$1
                              ? AppColors.darkCharcoal
                              : AppColors.borderSubtle,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedType = item.$1);
                        },
                      ),
                    ),
                  ],
                ],
              ),
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
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ActiveReminderChannelsCard extends StatelessWidget {
  final NotificationPreferences prefs;
  final VoidCallback onConfigure;

  const _ActiveReminderChannelsCard({
    required this.prefs,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final channels = [
      ('Membership Expiry', prefs.membershipReminders),
      ('Payment', prefs.paymentReminders),
      ('Workout', prefs.workoutReminders),
      ('Water Intake', prefs.waterIntakeReminders),
      ('Diet', prefs.dietReminders),
      ('Gym Announcement', prefs.gymAnnouncements),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.darkCharcoal,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Active Reminder Channels',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onConfigure,
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text('Manage Reminders'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: channels.map((c) {
              final active = c.$2;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.successBg : AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: active
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  '${c.$1}: ${active ? 'ON' : 'OFF'}',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
