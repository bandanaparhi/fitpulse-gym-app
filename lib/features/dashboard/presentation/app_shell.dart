import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_sidebar.dart';

/// Responsive application shell wrapping all authenticated member screens.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouterState routerState;

  const AppShell({
    super.key,
    required this.child,
    required this.routerState,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentRoute = widget.routerState.uri.path;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        if (isDesktop || isTablet) {
          // Desktop & Tablet Layout with persistent Left Sidebar
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: Row(
              children: [
                // Persistent Sidebar (slim/collapsed on tablet, full on desktop)
                AppSidebar(
                  currentRoute: currentRoute,
                  isCollapsed: isTablet,
                ),
                // Main Content & Top Header
                Expanded(
                  child: Column(
                    children: [
                      AppHeader(
                        isMobile: false,
                        unreadNotifications: unreadCount,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout: Compact Header + Content + Bottom Nav + End Drawer for More items
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppHeader(
            isMobile: true,
            unreadNotifications: unreadCount,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          drawer: _buildMobileDrawer(context, currentRoute),
          body: SafeArea(
            bottom: false,
            child: widget.child,
          ),
          bottomNavigationBar: AppBottomNav(
            currentRoute: currentRoute,
            onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer(BuildContext context, String currentRoute) {
    return Drawer(
      backgroundColor: AppColors.darkCharcoal,
      child: SafeArea(
        child: Column(
          children: [
            // Header inside drawer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Icon(Icons.bolt, color: AppColors.darkCharcoal, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnDark),
                      ),
                      Text(
                        'Member: ${AppConstants.demoMemberName}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.limeAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),

            // Navigation Links in drawer
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  ...AppSidebar.primaryNav.map((item) => _buildDrawerItem(context, item, currentRoute)),
                  const Divider(color: AppColors.darkBorder, height: AppSpacing.lg),
                  ...AppSidebar.secondaryNav.map((item) => _buildDrawerItem(context, item, currentRoute)),
                ],
              ),
            ),

            const Divider(color: AppColors.darkBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, SidebarItem item, String currentRoute) {
    final isActive = currentRoute == item.route;

    return ListTile(
      leading: Icon(
        item.icon,
        color: isActive ? AppColors.limeAccent : AppColors.textOnDarkMuted,
        size: 22,
      ),
      title: Text(
        item.label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isActive ? AppColors.textOnDark : AppColors.textOnDarkMuted,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: item.badgeCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                borderRadius: AppRadius.roundedFull,
              ),
              child: Text(
                '${item.badgeCount}',
                style: AppTextStyles.badge.copyWith(color: AppColors.darkCharcoal),
              ),
            )
          : null,
      selected: isActive,
      selectedTileColor: AppColors.darkElevated,
      onTap: () {
        Navigator.of(context).pop();
        if (currentRoute != item.route) {
          context.go(item.route);
        }
      },
    );
  }
}
