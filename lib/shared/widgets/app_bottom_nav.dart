import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';

/// Touch-friendly bottom navigation bar for mobile screens conforming to
/// the FitPulse commercial redesign.
///
/// 5 tabs:
/// 1. Home (/dashboard)
/// 2. Workouts (/workouts)
/// 3. Check-in (/attendance with prominent lime QR button)
/// 4. Classes (/classes)
/// 5. More (opens drawer / full navigation sheet)
class AppBottomNav extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onMorePressed;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
    this.onMorePressed,
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
            children: [
              Expanded(
                child: _buildTab(
                  context: context,
                  label: 'Home',
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  route: '/dashboard',
                ),
              ),
              Expanded(
                child: _buildTab(
                  context: context,
                  label: 'Workouts',
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center_rounded,
                  route: '/workouts',
                ),
              ),
              Expanded(
                child: _buildCenterQrTab(
                  context: context,
                  currentRoute: currentRoute,
                ),
              ),
              Expanded(
                child: _buildTab(
                  context: context,
                  label: 'Classes',
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  route: '/classes',
                ),
              ),
              Expanded(
                child: _buildMoreTab(
                  context: context,
                  currentRoute: currentRoute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterQrTab({
    required BuildContext context,
    required String currentRoute,
  }) {
    final isActive = currentRoute == '/attendance' || currentRoute.startsWith('/attendance');

    return InkWell(
      onTap: () {
        if (currentRoute != '/attendance') {
          context.go('/attendance');
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.limeAccent : AppColors.darkElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.limeAccent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.limeAccent.withValues(alpha: isActive ? 0.4 : 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 20,
              color: isActive ? AppColors.darkCharcoal : AppColors.limeAccent,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Check-in',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
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
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreTab({
    required BuildContext context,
    required String currentRoute,
  }) {
    // Check if current route is one of the secondary routes accessed via More
    final isSecondaryRoute = currentRoute.startsWith('/membership') ||
        currentRoute.startsWith('/progress') ||
        currentRoute.startsWith('/diet-plan') ||
        currentRoute.startsWith('/trainer') ||
        currentRoute.startsWith('/payments') ||
        currentRoute.startsWith('/announcements') ||
        currentRoute.startsWith('/profile') ||
        currentRoute.startsWith('/settings') ||
        currentRoute.startsWith('/support');

    return InkWell(
      onTap: () {
        if (onMorePressed != null) {
          onMorePressed!();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_rounded,
            size: 22,
            color: isSecondaryRoute ? AppColors.limeAccent : AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: 3),
          Text(
            'More',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isSecondaryRoute ? AppColors.limeAccent : AppColors.textOnDarkMuted,
              fontSize: 10.5,
              fontWeight: isSecondaryRoute ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
