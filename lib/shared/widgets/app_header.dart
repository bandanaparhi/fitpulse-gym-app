import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Top application header bar adhering to the FitPulse commercial redesign.
///
/// Mobile View:
/// - Safe area support for phone status bar / notch / camera cutout
/// - Left: FitPulse lime bolt badge + "FitPulse" brand title
/// - Right: Notification bell with badge + Circular "AM" avatar
///
/// Desktop View:
/// - Left: Clean page title (e.g. "Dashboard")
/// - Right: Notifications bell + User avatar with name/status
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final int unreadNotifications;
  final String? pageTitle;

  const AppHeader({
    super.key,
    this.isMobile = false,
    this.onMenuPressed,
    this.unreadNotifications = 2,
    this.pageTitle,
  });

  @override
  Size get preferredSize => Size.fromHeight(isMobile ? 56.0 : 64.0);

  String _resolveTitle(BuildContext context) {
    if (pageTitle != null && pageTitle!.isNotEmpty) {
      return pageTitle!;
    }
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/membership')) return 'Membership';
    if (path.startsWith('/attendance')) return 'Attendance';
    if (path.startsWith('/workouts')) return 'Workouts';
    if (path.startsWith('/progress')) return 'Fitness Progress';
    if (path.startsWith('/diet-plan')) return 'Nutrition';
    if (path.startsWith('/classes')) return 'Classes & Bookings';
    if (path.startsWith('/trainer')) return 'Personal Trainer';
    if (path.startsWith('/payments')) return 'Payments';
    if (path.startsWith('/announcements')) return 'Announcements';
    if (path.startsWith('/notifications')) return 'Notifications';
    if (path.startsWith('/profile')) return 'Profile';
    if (path.startsWith('/settings')) return 'Settings';
    if (path.startsWith('/support')) return 'Help & Support';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final headerContent = SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : AppSpacing.xl),
        child: Row(
          children: [
            if (isMobile) ...[
              // Brand Logo & Name
              Expanded(
                child: InkWell(
                  onTap: () => context.go('/dashboard'),
                  borderRadius: AppRadius.roundedSm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: const Icon(Icons.bolt, color: AppColors.darkCharcoal, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        'FitPulse',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Desktop/Tablet Page Title
              Expanded(
                child: Text(
                  _resolveTitle(context),
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],

            // Notification icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  iconSize: isMobile ? 22 : 24,
                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 36 : 44,
                    minHeight: isMobile ? 36 : 44,
                  ),
                  onPressed: () => context.go('/notifications'),
                  tooltip: 'Notifications',
                ),
                if (unreadNotifications > 0)
                  Positioned(
                    top: isMobile ? 4 : 7,
                    right: isMobile ? 4 : 7,
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: const BoxDecoration(
                        color: AppColors.limeAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Center(
                        child: Text(
                          '$unreadNotifications',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkCharcoal,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: isMobile ? 2 : AppSpacing.xs),

            // Profile access avatar
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: AppRadius.roundedFull,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 15 : 18,
                      backgroundColor: AppColors.darkCharcoal,
                      child: Text(
                        'AM',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.limeAccent,
                          fontSize: isMobile ? 10.5 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        AppConstants.demoMemberName,
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 13.5),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: headerContent,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: headerContent,
    );
  }
}
