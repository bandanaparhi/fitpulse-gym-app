import 'package:material_ui/material_ui.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/app_responsive.dart';

/// Primary action button styled with the signature gym lime accent.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final effectiveHeight = isMobile ? (height > 40.0 ? 40.0 : height) : height;

    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: isMobile ? 16 : 18,
            height: isMobile ? 16 : 18,
            child: const CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: isMobile ? 16 : 18, color: AppColors.darkCharcoal),
            SizedBox(width: isMobile ? 6 : AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: AppColors.darkCharcoal,
                fontSize: isMobile ? 13 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    final button = SizedBox(
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.limeAccent,
          foregroundColor: AppColors.darkCharcoal,
          disabledBackgroundColor: AppColors.limeAccent.withValues(alpha: 0.5),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        ),
        child: buttonContent,
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
