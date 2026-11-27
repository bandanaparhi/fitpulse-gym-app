import 'package:material_ui/material_ui.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/app_responsive.dart';

/// KPI Summary card for key metrics (Attendance, Membership, Payments, etc.)
class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? badge;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final effectiveIconColor = iconColor ?? AppColors.darkCharcoal;
    final effectiveIconBgColor = iconBgColor ?? AppColors.limeAccent.withValues(alpha: 0.2);

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
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 14,
              vertical: isMobile ? 9 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 5 : 7),
                      decoration: BoxDecoration(
                        color: effectiveIconBgColor,
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: Icon(icon, color: effectiveIconColor, size: isMobile ? 15 : 18),
                    ),
                    if (badge != null)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: badge!,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isMobile ? 6 : AppSpacing.sm),
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 15 : 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: isMobile ? 10 : 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
