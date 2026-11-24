import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Top application header bar with notifications, profile access, and mobile drawer controls.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final int unreadNotifications;

  const AppHeader({
    super.key,
    this.isMobile = false,
    this.onMenuPressed,
    this.unreadNotifications = 2,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: onMenuPressed,
              tooltip: 'Open Menu',
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                borderRadius: AppRadius.roundedSm,
              ),
              child: const Icon(Icons.bolt, color: AppColors.darkCharcoal, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppConstants.appName,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ] else ...[
            // Desktop/Tablet title greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back, ${AppConstants.demoMemberName} 👋',
                    style: AppTextStyles.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Member ID: ${AppConstants.demoMemberId} • ${AppConstants.demoMembershipPlan} Plan',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (isMobile) const Spacer(),

          // Notification icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => context.go('/notifications'),
                tooltip: 'Notifications',
              ),
              if (unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.limeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadNotifications',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSpacing.xs),

          // Profile access avatar
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: AppRadius.roundedFull,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.darkCharcoal,
                    child: Text(
                      'AM',
                      style: AppTextStyles.badge.copyWith(color: AppColors.limeAccent),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppConstants.demoMemberName,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
