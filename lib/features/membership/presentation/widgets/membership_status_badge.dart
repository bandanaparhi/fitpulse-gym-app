import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';

/// Reusable status badge for Active, Expired, and Pending memberships.
class MembershipStatusBadge extends StatelessWidget {
  final String status;

  const MembershipStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();

    Color bgColor;
    Color textColor;
    IconData icon;
    String displayLabel;

    if (normalized == 'active') {
      bgColor = AppColors.successBg;
      textColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      displayLabel = 'ACTIVE';
    } else if (normalized == 'expired') {
      bgColor = AppColors.borderSubtle;
      textColor = AppColors.textSecondary;
      icon = Icons.cancel_outlined;
      displayLabel = 'EXPIRED';
    } else if (normalized == 'pending' || normalized == 'pending payment') {
      bgColor = AppColors.warningBg;
      textColor = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      displayLabel = 'PENDING';
    } else {
      bgColor = AppColors.limeAccent.withValues(alpha: 0.15);
      textColor = AppColors.limeAccentDark;
      icon = Icons.info_outline_rounded;
      displayLabel = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            displayLabel,
            style: AppTextStyles.badge.copyWith(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
