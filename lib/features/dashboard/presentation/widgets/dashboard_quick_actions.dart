import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';

/// Quick action buttons for high-frequency member workflows.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
            final columns = isDesktop ? 4 : (isTablet ? 2 : 2);

            final actions = [
              _QuickActionItem(
                title: 'View Workout',
                subtitle: 'Upper Body Power',
                icon: Icons.fitness_center_rounded,
                route: '/workouts',
                accentColor: AppColors.limeAccent,
              ),
              _QuickActionItem(
                title: 'View Membership',
                subtitle: 'Premium Plan Active',
                icon: Icons.card_membership_rounded,
                route: '/membership',
                accentColor: AppColors.darkCharcoal,
              ),
              _QuickActionItem(
                title: 'Book a Class',
                subtitle: 'Reserve group spot',
                icon: Icons.calendar_month_rounded,
                route: '/classes',
                accentColor: AppColors.info,
              ),
              _QuickActionItem(
                title: 'View Progress',
                subtitle: 'Analytics & records',
                icon: Icons.trending_up_rounded,
                route: '/progress',
                accentColor: AppColors.warning,
              ),
            ];

            return GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: isDesktop ? 2.3 : (isTablet ? 2.5 : 2.0),
              ),
              itemBuilder: (context, index) {
                final item = actions[index];
                return _buildActionCard(context, item);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickActionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: AppRadius.roundedLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.18),
                    borderRadius: AppRadius.roundedMd,
                  ),
                  child: Icon(item.icon, color: item.accentColor == AppColors.limeAccent ? AppColors.limeAccentDark : item.accentColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accentColor;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accentColor,
  });
}
