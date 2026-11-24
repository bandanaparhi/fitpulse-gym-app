import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Touch-friendly bottom navigation bar for mobile screens.
class AppBottomNav extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onOpenMenu;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
    this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCharcoal,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(
                context: context,
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                route: '/dashboard',
              ),
              _buildTab(
                context: context,
                label: 'Attendance',
                icon: Icons.qr_code_scanner_outlined,
                activeIcon: Icons.qr_code_scanner,
                route: '/attendance',
              ),
              _buildTab(
                context: context,
                label: 'Workouts',
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                route: '/workouts',
              ),
              _buildTab(
                context: context,
                label: 'Classes',
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                route: '/classes',
              ),
              _buildMenuTab(
                context: context,
                label: 'More',
                icon: Icons.menu_rounded,
                onTap: onOpenMenu ?? () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required String route,
  }) {
    final isActive = currentRoute == route || (route != '/dashboard' && currentRoute.startsWith(route));

    return InkWell(
      onTap: () {
        if (currentRoute != route) {
          context.go(route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSecondaryRoute = currentRoute == '/profile' ||
        currentRoute == '/settings' ||
        currentRoute == '/support' ||
        currentRoute == '/membership' ||
        currentRoute == '/diet-plan' ||
        currentRoute == '/progress' ||
        currentRoute == '/trainer' ||
        currentRoute == '/payments' ||
        currentRoute == '/notifications' ||
        currentRoute == '/announcements';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSecondaryRoute ? AppColors.limeAccent : AppColors.textOnDarkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSecondaryRoute ? AppColors.limeAccent : AppColors.textOnDarkMuted,
                fontSize: 10,
                fontWeight: isSecondaryRoute ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
