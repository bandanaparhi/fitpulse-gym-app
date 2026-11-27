import 'package:material_ui/material_ui.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/app_responsive.dart';

/// Top header for individual screens and pages.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            iconSize: isMobile ? 20 : 24,
            padding: isMobile ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
            constraints: isMobile
                ? const BoxConstraints(minWidth: 34, minHeight: 34)
                : null,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: isMobile ? AppTextStyles.h3 : AppTextStyles.h2,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: isMobile ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        if (!isMobile) ?trailing,
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? AppSpacing.md : AppSpacing.lg),
      child: isMobile && trailing != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleBlock,
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            )
          : titleBlock,
    );
  }
}
