import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  final int? badgeCount;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.badgeCount,
  });
}

/// Left sidebar navigation for desktop and tablet screens.
class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  static const List<SidebarItem> primaryNav = [
    SidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
    SidebarItem(label: 'Membership', icon: Icons.card_membership_outlined, route: '/membership'),
    SidebarItem(label: 'Attendance', icon: Icons.qr_code_scanner_outlined, route: '/attendance'),
    SidebarItem(label: 'Workouts', icon: Icons.fitness_center_outlined, route: '/workouts'),
    SidebarItem(label: 'Fitness Progress', icon: Icons.trending_up_outlined, route: '/progress'),
    SidebarItem(label: 'Diet Plan', icon: Icons.restaurant_outlined, route: '/diet-plan'),
    SidebarItem(label: 'Classes & Bookings', icon: Icons.calendar_month_outlined, route: '/classes'),
    SidebarItem(label: 'My Trainer', icon: Icons.sports_outlined, route: '/trainer'),
    SidebarItem(label: 'Payments', icon: Icons.receipt_long_outlined, route: '/payments'),
  ];

  static const List<SidebarItem> secondaryNav = [
    SidebarItem(label: 'Notifications', icon: Icons.notifications_none_outlined, route: '/notifications', badgeCount: 2),
    SidebarItem(label: 'Announcements', icon: Icons.campaign_outlined, route: '/announcements'),
    SidebarItem(label: 'Profile', icon: Icons.person_outline, route: '/profile'),
    SidebarItem(label: 'Settings', icon: Icons.settings_outlined, route: '/settings'),
    SidebarItem(label: 'Help & Support', icon: Icons.help_outline, route: '/support'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 260.0;

    return Container(
      width: width,
      height: double.infinity,
      color: AppColors.darkCharcoal,
      child: Column(
        children: [
          // Gym Branding
          _buildBranding(context),
          const Divider(color: AppColors.darkBorder, height: 1),

          // Scrollable navigation links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
              children: [
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xs),
                    child: Text(
                      'MAIN MENU',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textOnDarkMuted, letterSpacing: 1.1),
                    ),
                  ),
                ...primaryNav.map((item) => _buildNavItem(context, item)),
                const SizedBox(height: AppSpacing.md),
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.xs),
                    child: Text(
                      'PREFERENCES',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textOnDarkMuted, letterSpacing: 1.1),
                    ),
                  ),
                ...secondaryNav.map((item) => _buildNavItem(context, item)),
              ],
            ),
          ),

          // Member quick profile footer
          const Divider(color: AppColors.darkBorder, height: 1),
          _buildMemberProfileSnippet(context),
        ],
      ),
    );
  }

  Widget _buildBranding(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.limeAccent,
              borderRadius: AppRadius.roundedMd,
            ),
            child: const Icon(Icons.bolt, color: AppColors.darkCharcoal, size: 24),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w700),
                    maxLines: 1,
                  ),
                  Text(
                    'MEMBER PORTAL',
                    style: AppTextStyles.caption.copyWith(color: AppColors.limeAccent, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, SidebarItem item) {
    final isActive = currentRoute == item.route || currentRoute.startsWith('${item.route}/');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Tooltip(
        message: isCollapsed ? item.label : '',
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: isActive ? AppColors.darkElevated : Colors.transparent,
          borderRadius: AppRadius.roundedMd,
          child: InkWell(
            onTap: () {
              if (currentRoute != item.route) {
                context.go(item.route);
              }
            },
            borderRadius: AppRadius.roundedMd,
            child: Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                border: isActive
                    ? const Border(left: BorderSide(color: AppColors.limeAccent, width: 3.5))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isActive ? AppColors.textOnDark : AppColors.textOnDarkMuted,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent,
                          borderRadius: AppRadius.roundedFull,
                        ),
                        child: Text(
                          '${item.badgeCount}',
                          style: AppTextStyles.badge.copyWith(color: AppColors.darkCharcoal),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberProfileSnippet(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.darkElevated,
          child: Text(
            'AM',
            style: AppTextStyles.badge.copyWith(color: AppColors.limeAccent),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go('/profile'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.darkElevated,
              child: Text(
                'AM',
                style: AppTextStyles.badge.copyWith(color: AppColors.limeAccent),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.demoMemberName,
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnDark, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${AppConstants.demoMemberId}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textOnDarkMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.limeAccent.withValues(alpha: 0.15),
                borderRadius: AppRadius.roundedSm,
              ),
              child: Text(
                'ACTIVE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.limeAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
