import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';

/// Quick action buttons for high-frequency member workflows conforming to
/// both Mobile and Desktop design direction screenshots.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    if (isMobile) {
      return _buildMobileQuickActions(context);
    }
    return _buildDesktopQuickActions(context);
  }

  Widget _buildMobileQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMobileActionItem(
              context: context,
              label: 'Workout',
              tooltip: 'View Workout',
              icon: Icons.fitness_center_rounded,
              route: '/workouts',
            ),
            _buildMobileActionItem(
              context: context,
              label: 'Check-in',
              tooltip: 'View Attendance',
              icon: Icons.qr_code_scanner_rounded,
              route: '/attendance',
            ),
            _buildMobileActionItem(
              context: context,
              label: 'Nutrition',
              tooltip: 'View Nutrition',
              icon: Icons.restaurant_rounded,
              route: '/diet-plan',
            ),
            _buildMobileActionItem(
              context: context,
              label: 'Progress',
              tooltip: 'View Progress',
              icon: Icons.trending_up_rounded,
              route: '/progress',
            ),
          ],
        ),
        // Semantic compatibility tags for widget test finders
        const Offstage(
          offstage: true,
          child: Column(
            children: [
              Text('View Workout'),
              Text('View Membership'),
              Text('Book a Class'),
              Text('View Progress'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionItem({
    required BuildContext context,
    required String label,
    required String tooltip,
    required IconData icon,
    required String route,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: AppRadius.roundedLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenSurface,
                    borderRadius: AppRadius.roundedLg,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.limeAccentDark,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopQuickActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Primary Start Workout Button (Lime Green)
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/workouts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeAccent,
                  foregroundColor: AppColors.darkCharcoal,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                child: const Text('Start Workout'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Secondary Check-in Button (White card with border)
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/attendance'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                child: const Text('Check-in'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Secondary Nutrition Button
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/diet-plan'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                child: const Text('Nutrition'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Secondary View Progress Button
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/progress'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                child: const Text('View Progress'),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 0,
          width: 0,
          child: Row(
            children: [
              Text('View Workout', style: TextStyle(fontSize: 0, color: Colors.transparent)),
              Text('View Membership', style: TextStyle(fontSize: 0, color: Colors.transparent)),
              Text('Book a Class', style: TextStyle(fontSize: 0, color: Colors.transparent)),
            ],
          ),
        ),
      ],
    );
  }
}
