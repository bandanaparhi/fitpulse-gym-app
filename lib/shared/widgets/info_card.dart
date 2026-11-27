import 'package:material_ui/material_ui.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/app_responsive.dart';

/// Reusable clean card container with subtle borders for dashboard sections.
class InfoCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final resolvedPadding = padding ?? AppResponsive.cardPadding(context);
    final headerGap = isMobile ? AppSpacing.sm + 2 : AppSpacing.md;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || icon != null || trailing != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(isMobile ? 5 : AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.limeAccent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Icon(icon, size: isMobile ? 15 : 18, color: AppColors.limeAccentDark),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (title != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: isMobile
                            ? AppTextStyles.titleMedium.copyWith(fontSize: 13.5)
                            : AppTextStyles.titleMedium,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: isMobile
                              ? AppTextStyles.bodySmall.copyWith(fontSize: 11)
                              : AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ?trailing,
            ],
          ),
          SizedBox(height: headerGap),
          const Divider(color: AppColors.borderSubtle, height: 1),
          SizedBox(height: headerGap),
        ],
        child,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: isMobile ? AppRadius.roundedMd : AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: isMobile ? AppRadius.roundedMd : AppRadius.roundedLg,
          child: Padding(
            padding: resolvedPadding,
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
